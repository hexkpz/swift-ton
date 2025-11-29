//
//  Created by Anton Spivak
//

import Foundation

// MARK: - CellData.PrecalculatedData

extension CellData {
    /// Represents intermediate precomputed data for a cell, including
    /// preallocated arrays for depths and hashes across various levels.
    ///
    /// Use this to store and retrieve level-based results (e.g., hash
    /// and depth at different “significant” levels in a TON cell).
    ///
    /// - Note: The `levels` property indicates which levels are “active”
    ///  in this cell. The arrays `depths` and `hashes` have positions
    ///  aligned with these levels.
    ///
    /// **Example Usage**:
    /// ```swift
    /// var data = CellData.PrecalculatedData(.init(rawValue: 0b101))
    /// data.set(hash: myHash, with: .init(rawValue: 0b001))
    /// let depth0 = precalc.depth(at: 0)
    /// ```
    struct PrecalculatedData {
        // MARK: Lifecycle

        /// Initializes a new precomputed data set with a given level mask.
        /// Creates the `depths` and `hashes` arrays, sized based on the
        /// number of significant levels.
        ///
        /// - Parameter levels: A `LevelMask` describing which levels are active.
        init(_ levels: LevelMask) {
            self.levels = levels

            let expectedElementsCount = levels.expectedElementsCount
            self.depths = .init(repeating: 0, count: expectedElementsCount)
            self.hashes = .init(repeating: Data(), count: expectedElementsCount)
        }

        // MARK: Internal

        /// A bitmask representing which levels are present. Its `highestLevel`
        /// can be used to quickly check the maximum level in this cell.
        let levels: LevelMask

        /// The maximum enabled level from the `levels` mask.
        ///
        /// **Example**:
        /// ```swift
        /// if precalc.level > 2 {
        ///    // handle deeper level logic
        /// }
        /// ```
        var level: UInt32 { levels.highestLevel }

        // MARK: Private

        private var depths: [UInt16]
        private var hashes: [Data]
    }
}

extension CellData.PrecalculatedData {
    /// Assigns a new hash for the specified `levels` mask subset.
    ///
    /// - Parameters:
    ///  - hash: The computed `Data` hash value for that set of levels.
    ///  - levels: The mask identifying the exact level position (e.g., 0, 1, 2...).
    ///
    /// **Example**:
    /// ```swift
    /// data.set(hash: someHashValue, with: .with(level: 2))
    /// ```
    @inline(__always)
    mutating func set(hash: Data, with levels: CellData.LevelMask) {
        hashes[levels.targetElementIndex] = hash
    }

    /// Retrieves the hash for a specific level.
    ///
    /// - Parameter level: The level to query. (0-based)
    /// - Returns: The `Data` hash stored for that level.
    ///
    /// **Example**:
    /// ```swift
    /// let lvl1Hash = data.hash(at: 1)
    /// ```
    func hash(at level: UInt32) -> Data {
        precondition(!hashes.isEmpty, "Cell must have at least 0-level (representation) hash")
        return hashes[levels.trimmingTo(highestLevel: level).targetElementIndex]
    }
}

extension CellData.PrecalculatedData {
    /// Assigns a new depth for the specified `levels` mask subset.
    ///
    /// - Parameters:
    ///  - depth: The computed depth value (UInt16) for that set of levels.
    ///  - levels: The mask identifying the exact level position.
    ///
    /// **Example**:
    /// ```swift
    /// data.set(depth: 5, with: .with(level: 2))
    /// ```
    @inline(__always)
    mutating func set(depth: UInt16, with levels: CellData.LevelMask) {
        depths[levels.targetElementIndex] = depth
    }

    /// Retrieves the depth for a specific level.
    ///
    /// - Parameter level: The 0-based level index.
    /// - Returns: The stored `UInt16` depth for that level.
    ///
    /// **Example**:
    /// ```swift
    /// let lvl2Depth = precalc.depth(at: 2)
    /// ```
    func depth(at level: UInt32) -> UInt16 {
        precondition(!depths.isEmpty, "Cell must have at least 0-level (representation) depth")
        return depths[levels.trimmingTo(highestLevel: level).targetElementIndex]
    }
}

// MARK: - CellData.PrecalculatedData + Sendable

extension CellData.PrecalculatedData: Sendable {}

// MARK: CellDataLevel.Mask

private extension CellData.LevelMask {
    /// Returns how many bits (levels) are set in `rawValue`.
    /// This effectively maps to the index used when storing or retrieving
    /// a level's hash/depth in the arrays.
    ///
    /// **Example**:
    /// If `rawValue = 0b101`, then `2` bits are set, so the
    /// “targetElementIndex” would be `2`.
    @inline(__always)
    var targetElementIndex: Int { rawValue.nonzeroBitCount }

    /// Returns the total number of hash/depth elements needed.
    /// This is `targetElementIndex + 1`, ensuring we always have at
    /// least one slot for level 0.
    ///
    /// **Example**:
    /// If `rawValue = 0b101`, then `targetElementIndex = 2`,
    /// so `expectedElementsCount = 3`.
    @inline(__always)
    var expectedElementsCount: Int { targetElementIndex + 1 }
}
