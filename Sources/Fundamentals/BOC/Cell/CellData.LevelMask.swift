//
//  Created by Anton Spivak
//

// MARK: - CellData.LevelMask

extension CellData {
    /// A bitmask type for tracking which “levels” (0..3) are set or “significant”
    /// in a TON cell. Each bit in `rawValue` indicates a particular level:
    /// - bit #0 => level 1
    /// - bit #1 => level 2
    /// - bit #2 => level 3
    /// and so on.
    ///
    /// **Example**:
    /// ```swift
    /// let mask = CellData.LevelMask.with(level: 2)
    /// print(mask.highestLevel) // prints '2'
    /// ```
    @usableFromInline
    struct LevelMask: OptionSet {
        // MARK: Lifecycle

        /// Initializes a new mask with a raw 32-bit integer.
        /// Typically use `with(level:)` or integer literal conformances
        /// to build a mask for a specific level range.
        @usableFromInline
        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        // MARK: Internal

        /// The underlying 32-bit integer that stores bit flags.
        @usableFromInline
        let rawValue: UInt32

        /// The highest level enabled in this mask.
        /// If `rawValue == 0`, returns `0`. Otherwise, uses `leadingZeroBitCount`
        /// to compute the effective maximum level.
        ///
        /// **Example**:
        /// ```swift
        /// let mask = CellData.LevelMask(rawValue: 0b0010)
        /// print(mask.highestLevel) // 2 (level #2 is the highest set)
        /// ```
        @usableFromInline @inline(__always)
        var highestLevel: UInt32 { UInt32(32) - UInt32(rawValue.leadingZeroBitCount) }

        /// Returns a new `LevelMask` with exactly one bit set corresponding
        /// to the specified `level`. If `level == 0`, returns an empty mask.
        ///
        /// **Example**:
        /// ```swift
        /// let single = CellData.LevelMask.with(level: 1)
        /// // single.rawValue == 0b0001
        /// ```
        static func with(level: UInt32) -> Self {
            checkLevelWithFatalError(level)
            if level > 0 {
                return Self(rawValue: 1 << UInt32(level - 1))
            }
            return .init(rawValue: 0)
        }

        /// Merges (`OR`s) this mask with another, combining their active bits.
        /// - Parameter mask: Another `LevelMask` to combine.
        ///
        /// **Example**:
        /// ```swift
        /// var levels = CellData.LevelMask(rawValue: 0b0001)
        /// levels.combine(with: .init(rawValue: 0b0100))
        /// // levels.rawValue == 0b0101
        /// ```
        @inline(__always)
        mutating func combine(with mask: LevelMask) {
            formUnion(mask)
        }

        /// Checks if the specified `level` bit is active in this mask.
        /// Returns `true` if `level == 0` or if the bit for `level` is set.
        ///
        /// **Example**:
        /// ```swift
        /// let mask = CellData.LevelMask(rawValue: 0b010)
        /// print(mask.contains(level: 2)) // true
        /// print(mask.contains(level: 1)) // false
        /// ```
        func contains(level: UInt32) -> Bool {
            Self.checkLevelWithFatalError(level)
            if level > 0 {
                return contains(.with(level: level))
            }
            return true
        }

        /// Returns a version of this mask whose set bits do not exceed
        /// the specified `highestLevel`. For example, if `highestLevel == 2`,
        /// bits corresponding to level 3 and up are cleared.
        ///
        /// **Example**:
        /// ```swift
        /// let mask = CellData.LevelMask(rawValue: 0b111)
        /// let trimmed = mask.trimmingTo(highestLevel: 2)
        /// // trimmed.rawValue == 0b011
        /// ```
        func trimmingTo(highestLevel: UInt32) -> Self {
            Self.checkLevelWithFatalError(highestLevel)
            if highestLevel > 0 {
                return intersection(.init(rawValue: (1 << highestLevel) - 1))
            }
            return .init(rawValue: 0)
        }

        // MARK: Private

        private static func checkLevelWithFatalError(_ level: UInt32) {
            guard level < 32
            else {
                fatalError("Level out of range (0 ..< 32)")
            }
        }
    }
}

// MARK: - CellData.LevelMask + ExpressibleByIntegerLiteral

extension CellData.LevelMask: ExpressibleByIntegerLiteral {
    /// Allows creating a `LevelMask` by integer literal, mapping that integer
    /// to a single set bit for the corresponding level. If `value == 0`, returns
    /// an empty mask.
    ///
    /// **Example**:
    /// ```swift
    /// let mask: CellData.LevelMask = 3
    /// // means level #3 is active
    /// ```
    @usableFromInline
    init(integerLiteral value: UInt32) {
        self = .with(level: value)
    }
}

extension CellData.LevelMask {
    /// Shifts all bits to the right by 1, effectively lowering the highest
    /// set level by 1. Useful in Merkle proofs where a child's level is
    /// typically parent's level + 1.
    ///
    /// **Example**:
    /// ```swift
    /// let mask = CellData.LevelMask(rawValue: 0b0100) // level 3
    /// let reduced = mask.reducingHighestLevel()
    /// // reduced.rawValue == 0b0010
    /// ```
    @inline(__always)
    func reducingHighestLevel() -> Self {
        .init(rawValue: rawValue >> 1)
    }
}

// MARK: - CellData.LevelMask + Sendable

extension CellData.LevelMask: Sendable {}

// MARK: - CellData.LevelMask + Hashable

extension CellData.LevelMask: Hashable {}
