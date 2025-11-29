//
//  Created by Anton Spivak
//

// MARK: - BOCEncoder

struct BOCEncoder {
    // MARK: Lifecycle

    init(_ data: BOC.Data) {
        self.data = data
    }

    // MARK: Internal

    let data: BOC.Data
}

// MARK: Sendable

extension BOCEncoder: Sendable {}

// MARK: - BOCEncodingError

public enum BOCEncodingError: Error {
    /// The final size is not byte-aligned (must be multiple of 8 bits).
    case invalidSize

    /// No root cells were provided for encoding.
    case emptyRootCells

    /// Cyclic references prevent topological sorting.
    case topologicalSortingCycle

    /// The byte width needed for references is too large.
    case referenceCountByteWidthOverflow

    /// The byte width needed for cell contents is too large.
    case contentsCountByteWidthOverflow

    /// The .cachingBits option is not supported.
    case cacheBitsAreNotSupported
}

// MARK: CustomStringConvertible

extension BOCEncodingError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidSize: "BOC must be aligned to 8-bit nibbles"
        case .emptyRootCells: "BOC must have at least one root cell"
        case .topologicalSortingCycle: "Topological sorting failed with infinity cycle"
        case .referenceCountByteWidthOverflow: "Reference's 'count' byte width must be less or equal to 7"
        case .contentsCountByteWidthOverflow: "Contents's 'count' byte width must be less or equal to 8"
        case .cacheBitsAreNotSupported: "Cache bits are not supported"
        }
    }
}

// MARK: LocalizedError

extension BOCEncodingError: LocalizedError {
    public var errorDescription: String? { description }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: BOCEncodingError) {
        appendLiteral("\(value.description)")
    }
}

extension BOCEncoder {
    /// Encodes an array of root Cell objects into a `Data` BOC, applying
    /// the specified included options (.indices, .crc32c), verifying constraints,
    /// and performing topological sorting.
    ///
    /// - Parameter cells: The root cells to encode. Must not be empty.
    /// - Returns: A `Data` representing the final BOC bytes.
    /// - Throws: A `BOCEncodingError` if constraints fail, or if a cycle is detected in the DAG.
    ///
    ///
    /// **BOC TL-B structure**:
    /// ```
    ///  serialized_boc#b5ee9c72
    ///   has_idx:(## 1) has_crc32c:(## 1) has_cache_bits:(## 1) flags:(## 2) size:(## 3)
    ///   off_bytes:(## 8)
    ///   cells:(##(size * 8))
    ///   roots:(##(size * 8))
    ///   absent:(##(size * 8))
    ///   tot_cells_size:(##(off_bytes * 8))
    ///   root_list:(roots * ##(size * 8))
    ///   index:has_idx?(cells * ##(off_bytes * 8))
    ///   cell_data:(tot_cells_size * [uint8])
    ///   crc32c:has_crc32c?uint32
    ///   = BagOfCells;
    /// ```
    func encode() throws(BOCEncodingError) -> Data {
        guard !data.rootCells.isEmpty
        else {
            throw .emptyRootCells
        }

        if data.includedOptions.contains(.cachingBits) {
            throw BOCEncodingError.cacheBitsAreNotSupported
        }

        let (toplogicalSortedCells, rootIndices) = try topologicalSort(data.rootCells)

        var result = BitStorage()
        result.append(bitPattern: BOC.HeaderByte.generic.rawValue) // magic

        //
        // Serializing first byte
        //

        result.append(data.includedOptions.contains(.indices)) // has_idx:(## 1)
        result.append(data.includedOptions.contains(.crc32c)) // has_crc32c:(## 1)
        result.append(data.includedOptions.contains(.cachingBits)) // has_cache_bits:(## 1)
        result.append(contentsOf: [data.headerFlags.0, data.headerFlags.1]) // flags:(## 2)

        // Decide how many bytes needed for storing "cells count", "roots count", etc.
        // Check if it fits <= 7 (since specification says size <= 4, but code uses 0b0000_0111 mask).
        let referenceCountByteWidth = data.rootCells.count.minimumBytesWidth
        guard referenceCountByteWidth <= 0b0000_0111
        else {
            throw .referenceCountByteWidthOverflow
        }

        result.append(bitPattern: referenceCountByteWidth, truncatingToBitWidth: 3) // size:(## 3)

        let (encodedCellBits, indices) = serialize(
            toplogicalSortedCells,
            withReferenceByteWidth: referenceCountByteWidth
        )

        //
        // Serializing next bytes
        //

        // Number of bytes needed to store contents count (size of cells bytes)
        let contentsCountBytesWidth = (encodedCellBits.count / 8).minimumBytesWidth
        guard contentsCountBytesWidth <= 8 // BOC TL-b Restriction
        else {
            throw .contentsCountByteWidthOverflow
        }

        // off_bytes:(## 8)
        result.append(bitPattern: UInt8(contentsCountBytesWidth))

        // cells:(##(size * 8))
        result.append(
            bitPattern: toplogicalSortedCells.count,
            truncatingToByteWidth: referenceCountByteWidth
        )

        // roots:(##(size * 8))
        result.append(bitPattern: rootIndices.count, truncatingToByteWidth: referenceCountByteWidth)

        // absent:(##(size * 8))
        result.append(bitPattern: 0, truncatingToByteWidth: referenceCountByteWidth)

        // tot_cells_size:(##(off_bytes * 8))
        result.append(
            bitPattern: encodedCellBits.count / 8,
            truncatingToByteWidth: contentsCountBytesWidth
        )

        // root_list:(roots * ##(size * 8));
        for rootIndex in rootIndices {
            result.append(bitPattern: rootIndex, truncatingToByteWidth: referenceCountByteWidth)
        }

        // index:has_idx?(cells * ##(off_bytes * 8))
        if data.includedOptions.contains(.indices) {
            for index in indices {
                result.append(bitPattern: index, truncatingToByteWidth: contentsCountBytesWidth)
            }
        }

        // cell_data:(tot_cells_size * [uint8])
        result.append(contentsOf: encodedCellBits)
        guard result.count % 8 == 0
        else {
            throw .invalidSize
        }

        var alignedData = result.alignedData()

        // crc32c:has_crc32c?uint32
        if data.includedOptions.contains(.crc32c) {
            // Reversed because here should be Little Endian crc32c.
            alignedData.append(contentsOf: alignedData.crc32c().reversed())
        }

        return alignedData
    }
}

extension BOCEncoder {
    typealias SortedCell = (Cell, children: [Int])

    /// Sorts the given root cells along with their descendants, ensuring
    /// a directed acyclic graph (DAG). Each cell is assigned an index,
    /// and children are stored as array of those indices.
    ///
    /// - Parameter cells: An array of root cells to traverse.
    /// - Returns: A tuple containing sorted cells and an array of indices for root cells.
    /// - Throws: `BOCEncodingError.topologicalSortingCycle` if a cycle is detected.
    @inline(__always)
    func topologicalSort(
        _ cells: [Cell]
    ) throws(BOCEncodingError) -> ([SortedCell], rootIndices: [Int]) {
        var graphElements = [(cell: Cell, hash: Data, childrenHashes: [Data])]()
        var graphIndexes = [Data: Int]()

        var queue = cells
        while !queue.isEmpty {
            let cell = queue.removeLast()
            let hash = cell.representationHash

            guard graphIndexes[hash] == nil
            else {
                continue
            }

            graphIndexes[hash] = graphElements.count
            graphElements.append((cell, hash, cell.children.map(\.representationHash)))

            queue.append(contentsOf: cell.children)
        }

        var visiting = Set<Data>()
        var visited = Set<Data>()

        var sortedHashes = [Data]()

        func dfsv(_ hash: Data) throws(BOCEncodingError) {
            guard !visiting.contains(hash)
            else {
                throw .topologicalSortingCycle
            }

            guard !visited.contains(hash)
            else {
                return
            }

            visiting.insert(hash)

            guard let index = graphIndexes[hash]
            else {
                fatalError("Inconsistent graph state; couldn't find index of hash")
            }

            for child in graphElements[index].childrenHashes.reversed() {
                try dfsv(child)
            }

            visiting.remove(hash)
            visited.insert(hash)

            sortedHashes.append(hash)
        }

        // DFS over all graph elements
        for graphElement in graphElements {
            guard !visited.contains(graphElement.hash)
            else {
                continue
            }
            try dfsv(graphElement.hash)
        }

        // Reverse so that children come first in final ordering
        sortedHashes.reverse()

        // Build a map from hash => sorted index
        var indicesMap = [Data: Int]()
        for (i, hash) in sortedHashes.enumerated() {
            indicesMap[hash] = i
        }

        var sortedCells: [SortedCell] = []
        sortedCells.reserveCapacity(sortedHashes.count)

        for hash in sortedHashes {
            guard let index = graphIndexes[hash]
            else {
                fatalError("Inconsistent graph state: couldn't find index of hash")
            }

            let graphElement = graphElements[index]
            let childrenIndices = graphElement.childrenHashes.compactMap({ indicesMap[$0] })
            sortedCells.append((graphElement.cell, childrenIndices))
        }

        var rootIndices: [Int] = []
        rootIndices.reserveCapacity(cells.count)

        for cell in cells {
            guard let index = indicesMap[cell.representationHash]
            else {
                fatalError("Inconsistent graph state: couldn't find index of hash")
            }
            rootIndices.append(index)
        }

        return (sortedCells, rootIndices)
    }
}

extension BOCEncoder {
    /// Serializes each cell in the topologically sorted array into bits, returning:
    /// - A combined `BitStorage`
    /// - An array of offsets (in bytes) to each cell's start
    ///
    /// Used by `encode(_:)` when writing the final BOC payload.
    ///
    /// - Parameter cells: The sorted array `(cell, [childIndex])`.
    /// - Parameter referenceByteWidth: Number of bytes used to store child indices.
    ///
    /// - Returns: A tuple `(bitArray, offsets)`.
    @inline(__always)
    func serialize(
        _ cells: [SortedCell],
        withReferenceByteWidth referenceByteWidth: Int
    ) -> (BitStorage, indices: [Int]) {
        var storage = BitStorage()
        var indices = [Int]()
        for cell in cells {
            let cellData = cell.0.underlyingCell.data
            let cellLevel = cellData.precalculated.level

            storage.append(bitPattern: cellData.referencesDescriptor(for: cellLevel))
            storage.append(bitPattern: cellData.bitsDescriptor())
            storage.append(contentsOf: cellData.storage.cellAligned())

            for child in cell.children {
                storage.append(bitPattern: child, truncatingToByteWidth: referenceByteWidth)
            }

            indices.append(storage.count / 8)
        }

        return (storage, indices)
    }
}
