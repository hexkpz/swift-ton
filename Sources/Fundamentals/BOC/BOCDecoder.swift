//
//  Created by Anton Spivak
//

import Foundation

// MARK: - BOCDecoder

struct BOCDecoder {
    // MARK: Lifecycle

    init(_ data: Data) {
        self.data = data
    }

    // MARK: Internal

    let data: Data
}

// MARK: Sendable

extension BOCDecoder: Sendable {}

// MARK: - BOCDecodingError

public enum BOCDecodingError: Error {
    /// The BOC header magic byte is incorrect or unrecognized.
    case invalidHeader

    /// CRC32 verification failed.
    case invalidCRC32

    /// A cell type was encountered that couldn’t be recognized.
    case unknownCellKind

    /// A root cell index was out of range or invalid.
    case invalidRootCellIndex

    /// The .cachingBits option was present, but it isn’t supported.
    case cacheBitsAreNotSupported
}

// MARK: CustomStringConvertible

extension BOCDecodingError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidHeader: "Couldn't parse BOC TL-B header byte"
        case .invalidCRC32: "Invalid CRC32 hashsum"
        case .unknownCellKind: "Unknown cell kind"
        case .invalidRootCellIndex: "Invalid top-level cell index"
        case .cacheBitsAreNotSupported: "Cache bits are not supported"
        }
    }
}

// MARK: LocalizedError

extension BOCDecodingError: LocalizedError {
    @inlinable @inline(__always)
    public var errorDescription: String? { description }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: BOCDecodingError) {
        appendLiteral("\(value.description)")
    }
}

extension BOCDecoder {
    /// Decodes the BOC data into a BOC.Data object, reading header bytes, options,
    /// and cells from the underlying `Data`. If any constraint fails
    /// (e.g., invalid CRC or unknown cell type), throws a BOCDecodingError.
    ///
    /// - Returns: A `BOC.Data` struct containing root cells and header info.
    /// - Throws: `BOCDecodingError` if parsing fails (invalid magic, CRC, etc.).
    ///
    func decode() throws -> BOC.Data {
        var storage: ContinuousReader<BitStorage> = ContinuousReader(data)
        guard let header = try BOC.HeaderByte(rawValue: storage.read(UInt32.self))
        else {
            throw BOCDecodingError.invalidHeader
        }

        var options: BOC.IncludedOptions = []

        let flags: (Bool, Bool)
        let referenceCountByteWidth: Int

        switch header {
        case .index, .indexWithCRC32c:
            flags = (false, false)
            referenceCountByteWidth = try Int(storage.read(UInt8.self))
        case .generic:
            if try storage.read() {
                options.insert(.indices)
            }
            if try storage.read() {
                options.insert(.crc32c)
            }
            if try storage.read() {
                options.insert(.cachingBits)
            }

            flags = try (storage.read(), storage.read())
            referenceCountByteWidth = try storage.read(Int.self, truncatingToBitWidth: 3)
        }

        if options.contains(.cachingBits) {
            throw BOCDecodingError.cacheBitsAreNotSupported
        }

        let contentsCountBytesWidth = try Int(storage.read(UInt8.self))
        let toplogicalSortedCellsCount = try storage.read(
            Int.self,
            truncatingToBitWidth: referenceCountByteWidth * 8
        )

        let rootCellsCount = try storage.read(
            Int.self,
            truncatingToBitWidth: referenceCountByteWidth * 8
        )

        // skip absent
        _ = try storage.read(referenceCountByteWidth * 8)

        let cellsSizeBytes = try storage.read(
            Int.self,
            truncatingToBitWidth: contentsCountBytesWidth * 8
        )

        var cellsStorage: BitStorage
        let cellsIndices: [Int]?
        var cellsRootIndecies: [Int] = []

        var crc32c: Data? = nil

        switch header {
        case .index, .indexWithCRC32c:
            cellsIndices = try readCellIndicies(
                from: &storage,
                withCellsCount: toplogicalSortedCellsCount,
                contentsCountBytesWidth: contentsCountBytesWidth
            )

            cellsStorage = try BitStorage(storage.read(cellsSizeBytes * 8))
            cellsRootIndecies = [0]

            guard header == .indexWithCRC32c
            else {
                crc32c = nil
                break
            }

            crc32c = try storage.read(UInt32.self).data()
        case .generic:
            for _ in 0 ..< rootCellsCount {
                try cellsRootIndecies.append(storage.read(
                    Int.self,
                    truncatingToBitWidth: referenceCountByteWidth * 8
                ))
            }

            if options.contains(.indices) {
                cellsIndices = try readCellIndicies(
                    from: &storage,
                    withCellsCount: toplogicalSortedCellsCount,
                    contentsCountBytesWidth: contentsCountBytesWidth
                )
            } else {
                cellsIndices = nil
            }

            cellsStorage = try BitStorage(storage.read(cellsSizeBytes * 8))
            if options.contains(.crc32c) {
                crc32c = try storage.read(UInt32.self).data()
            }
        }

        // BOC uses reversed (little-endian) CRC appended
        if let crc32c, Data(data[0 ..< data.count - 4].crc32c().reversed()) != crc32c {
            throw BOCDecodingError.invalidCRC32
        }

        // (currently unused) indices (TODO: Lazy loading of cells)
        _ = cellsIndices //

        let elements = try readCellElements(
            from: &cellsStorage,
            withReferenceCountByteWidth: referenceCountByteWidth,
            expectedElelementsCount: toplogicalSortedCellsCount
        )

        // Build each cell from the bottom up
        var finalCells: [Cell?] = .init(repeating: nil, count: elements.count)
        finalCells.reserveCapacity(elements.count)

        // Iterate from last to first so children are built first
        for i in stride(from: elements.count - 1, through: 0, by: -1) {
            let (storage, indices, isExotic) = elements[i]
            guard finalCells[i] == nil
            else {
                fatalError("BOC decoder inconsistency: cell #\(i) already exists")
            }

            // Gather children
            var children: [Cell] = []
            children.reserveCapacity(indices.count)

            for index in indices {
                guard let child = finalCells[index]
                else {
                    fatalError("BOC decoder inconsistency: chil cell #\(i) does not exist")
                }
                children.append(child)
            }

            // Parse cell kind if exotic
            if isExotic {
                guard storage.count >= 8,
                      let kind = Cell.Kind(rawValue: .init(truncatingIfNeeded: storage[0 ..< 8]))
                else {
                    throw BOCDecodingError.unknownCellKind
                }
                finalCells[i] = try Cell(kind, storage: storage, children: children)
            } else {
                finalCells[i] = try Cell(.ordinary, storage: storage, children: children)
            }
        }

        var rootCells = [Cell]()
        rootCells.reserveCapacity(rootCellsCount)

        // Gather root cells
        for index in cellsRootIndecies {
            guard let cell = finalCells[index]
            else {
                throw BOCDecodingError.invalidRootCellIndex
            }
            rootCells.append(cell)
        }

        return .init(includedOptions: options, headerFlags: flags, rootCells: rootCells)
    }
}

private extension BOCDecoder {
    /// A structure describing the raw data for one cell in the BOC:
    /// - its BitStorage
    /// - array of child indices
    /// - isExotic indicating if the cell type must be parsed from the first 8 bits
    typealias CellElement = (BitStorage, children: [Int], isExotic: Bool)

    /// Reads `expectedElelementsCount` cell descriptors from the raw bit storage,
    /// producing `(BitStorage, children, isExotic)`.
    ///
    /// - Parameters:
    ///  - storage: A `BitStorage` SubSequence used by `ContinuousReader`.
    ///  - referenceCountByteWidth: The width (in bytes) used to decode each child index.
    ///  - expectedElelementsCount: How many cell descriptors to read.
    ///
    /// - Returns: An array of cell elements with bits, child indices, and exotic flags.
    /// - Throws: `BoundariesError` or other decoding errors if data is insufficient or invalid.
    @inline(__always)
    func readCellElements(
        from storage: inout BitStorage,
        withReferenceCountByteWidth referenceCountByteWidth: Int,
        expectedElelementsCount: Int
    ) throws -> [CellElement] {
        var storage = ContinuousReader(storage)

        var result = [CellElement]()
        result.reserveCapacity(expectedElelementsCount)

        for _ in 0 ..< expectedElelementsCount {
            let rd = try CellData._referencesDescriptorinformation(from: storage.read(UInt8.self))
            let bd = try CellData._bitsDescriptorInformation(from: storage.read(UInt8.self))

            var cellDataStorage = try BitStorage(storage.read(bd.bytesCount * 8))
            if bd.isAligned {
                cellDataStorage.cellUnalign()
            }

            var cellChildren: [Int] = []
            for _ in 0 ..< rd.children {
                try cellChildren.append(storage.read(
                    Int.self,
                    truncatingToBitWidth: referenceCountByteWidth * 8
                ))
            }

            result.append((cellDataStorage, cellChildren, rd.isExotic))
        }

        return result
    }

    /// Reads indices if the BOC includes an index table, returning an array
    /// of integer offsets for each cell.
    ///
    /// - Parameters:
    ///  - storage: The bit reader to consume these offsets from.
    ///  - cellsCount: Number of topologically sorted cells.
    ///  - contentsCountBytesWidth: The width in bytes for each offset entry.
    ///
    /// - Returns: An array of integer offsets, each describing where a cell begins in bytes.
    /// - Throws: `BoundariesError` if insufficient bits remain in the data.
    @inline(__always)
    func readCellIndicies(
        from storage: inout ContinuousReader<BitStorage>,
        withCellsCount cellsCount: Int,
        contentsCountBytesWidth: Int
    ) throws -> [Int] {
        let elementBitsCount = contentsCountBytesWidth * 8
        let totalBitsCount = cellsCount * elementBitsCount
        precondition(contentsCountBytesWidth <= UInt64.bitWidth / 8)
        return try stride(from: 0, to: totalBitsCount, by: elementBitsCount)
            .map({ _ in try storage.read(Int.self, truncatingToBitWidth: elementBitsCount) })
    }
}
