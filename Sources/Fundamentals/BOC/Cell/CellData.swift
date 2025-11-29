//
//  Created by Anton Spivak
//

import Crypto

#if canImport(Darwin)
import Darwin
#elseif canImport(Musl)
import Musl
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Bionic)
import Bionic
#else
#error("Unsupported platform")
#endif

// MARK: - CellData

@usableFromInline
struct CellData {
    // MARK: Lifecycle

    init(
        kind: Cell.Kind,
        precalculated: PrecalculatedData,
        storage: BitStorage,
        children: [Cell]
    ) {
        self.kind = kind
        self.precalculated = precalculated
        self.storage = storage
        self.children = children
    }

    // MARK: Internal

    /// The categorized type of this cell, used to interpret constraints or special logic.
    let kind: Cell.Kind

    /// Precomputed hash and depth data for various levels of this cell.
    let precalculated: PrecalculatedData

    /// Bit storage for the cell’s content.
    let storage: BitStorage

    /// Direct children (subcells) referenced by this cell.
    let children: [Cell]
}

// MARK: Sendable

extension CellData: Sendable {}

extension CellData {
    /// Computes an 8-bit “references descriptor,” encoding the number of children,
    /// whether the cell is exotic, and the current level.
    /// - Parameter level: Level index (e.g., 0..3).
    /// - Returns: A single byte (`UInt8`) describing child count, exotic flag, and level.
    ///
    /// **Example**:
    /// ```swift
    /// let d1 = cellData.referencesDescriptor(for: 1)
    /// print(descriptor) // e.g. 0x21 if 1 child, exotic=0, level=1
    /// ```
    ///
    @usableFromInline
    func referencesDescriptor(for level: UInt32) -> UInt8 {
        precondition(children.count >= 0 && children.count <= 4, "Children must be in 0..4")
        let referencesDescriptor = UInt32(children.count) + 8 * (kind.isExotic ? 1 : 0) + 32 * level
        precondition(
            referencesDescriptor <= UInt32(UInt8.max),
            "referencesDescriptor must fit into UInt8"
        )
        return UInt8(referencesDescriptor)
    }

    /// Splits a references descriptor into `(children, isExotic)`.
    ///
    /// - Parameter referencesDescriptor: The descriptor byte previously produced.
    /// - Returns: A tuple with the number of children and whether the cell is exotic.
    ///
    /// **Example**:
    /// ```swift
    /// let (children, isExotic) = CellData._referencesDescriptorinformation(from: descriptor)
    /// if isExotic { ... } // handle exotic
    /// ```
    @usableFromInline
    static func _referencesDescriptorinformation(
        from referencesDescriptor: UInt8
    ) -> (children: Int, isExotic: Bool) {
        (Int(referencesDescriptor) % 8, (referencesDescriptor & 8) != 0)
    }

    /// Produces an 8-bit “bits descriptor” that encodes how the cell’s bit storage is subdivided
    /// (including potential padding alignment).
    ///
    /// - Returns: A single `UInt8` describing how many bytes are used for the bits,
    ///  factoring in both floor and ceil for alignment.
    ///
    /// **Example**:
    /// ```swift
    /// let d2 = cellData.bitsDescriptor()
    /// // used for later serialization
    /// ```
    @usableFromInline
    func bitsDescriptor() -> UInt8 {
        let bitsDescriptor = floor(Double(storage.count) / 8) + ceil(Double(storage.count) / 8)
        precondition(bitsDescriptor <= Double(UInt8.max), "bitsDescriptor must fit into UInt8")
        return UInt8(bitsDescriptor)
    }

    /// Interprets a bits descriptor into `(bytesCount, isAligned)`.
    ///
    /// - Parameter bitsDescriptor: The descriptor byte from `bitsDescriptor()`.
    /// - Returns: A tuple with the computed byte-length and an alignment flag.
    ///
    /// **Example**:
    /// ```swift
    /// let (bytesCount, isAligned) = CellData._bitsDescriptorInformation(from: d2)
    /// ```
    @usableFromInline
    static func _bitsDescriptorInformation(
        from bitsDescriptor: UInt8
    ) -> (bytesCount: Int, isAligned: Bool) {
        (Int(ceil(Double(bitsDescriptor) / 2)), (bitsDescriptor % 2) != 0)
    }

    /// Retrieves the depth at a given level from `precalculated` data.
    ///
    /// - Parameter level: The level index (e.g., 0).
    /// - Returns: A `UInt16` representing the depth associated with that level.
    ///
    /// **Example**:
    /// ```swift
    /// let depth2 = cellData.depth(at: 2)
    /// ```
    @usableFromInline @inline(__always)
    func depth(at level: UInt32) -> UInt16 {
        precalculated.depth(at: level)
    }

    /// Retrieves the hash at a given level from `precalculated` data.
    ///
    /// - Parameter level: The level index (e.g., 0..3).
    /// - Returns: The `Data` hash for that level.
    ///
    /// **Example**:
    /// ```swift
    /// let lvlHash = cellData.hash(at: 1)
    /// ```
    @usableFromInline @inline(__always)
    func hash(at level: UInt32) -> Data {
        precalculated.hash(at: level)
    }

    /// Builds a “representation” of this cell for a specific level, packaging
    /// the references descriptor, bits descriptor, raw storage, and references'
    /// depths/hashes into a single `Data`.
    ///
    /// - Parameter level: The level index used when reading each child.
    /// - Returns: A `Data` that includes descriptors, bit contents,
    ///  child depths, and child hashes.
    ///
    /// **Example**:
    /// ```swift
    /// let rep = cellData.representation(0)
    /// // used for hashing or serialization
    /// ```
    @usableFromInline
    func representation(_ level: UInt32) -> Data {
        let storage = storage.cellAlignedData()
        var result = Data(
            repeating: 0x00,
            count: 2 + storage.count + (2 + 32) * children.count
        )

        result[0] = referencesDescriptor(for: level)
        result[1] = bitsDescriptor()

        result.replaceSubrange(2 ..< 2 + storage.count, with: storage)
        for i in 0 ..< children.count {
            let childData = children[i].underlyingCell.data
            let childDataLevel: UInt32 = switch childData.kind {
            case .merkleProof, .merkleUpdate: level + 1
            default: level
            }

            let depth = childData.depth(at: childDataLevel)
            let hash = childData.hash(at: childDataLevel)

            let doffset = 2 + storage.count + i * 2
            result[doffset] = UInt8((depth >> 8) & 0xFF)
            result[doffset + 1] = UInt8(depth & 0xFF)

            let hoffset = 2 + storage.count + children.count * 2 + i * 32
            precondition(hash.count == 32, "Hash must be exactly 32 bytes")
            result.replaceSubrange(hoffset ..< hoffset + hash.count, with: hash)
        }

        return result
    }
}
