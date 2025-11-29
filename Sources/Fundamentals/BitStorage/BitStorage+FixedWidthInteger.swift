//
//  Created by Anton Spivak
//

public extension FixedWidthInteger {
    /// Creates a new fixed-width integer from an entire `BitStorage`,
    /// truncating (or sign-extending) any excess bits to fit `Self.bitWidth`.
    ///
    /// This initializer reads all bits in `source[0 ..< source.count]` as the
    /// integer’s binary representation. If the number of bits in `source`
    /// exceeds `Self.bitWidth`, the high-order bits are discarded. If `source`
    /// has fewer bits than `Self.bitWidth`, the missing bits are sign-extended
    /// if `Self` is signed, or zero-extended if `Self` is unsigned.
    ///
    /// ```swift
    /// // Example: Suppose 'storage' has 12 bits representing the value 0b101101101101.
    /// let storage = BitStorage()
    /// storage.append(bitPattern: 0b101101101101 as UInt16)
    ///
    /// // For a FixedWidthInteger like UInt8, only the lower 8 bits are kept.
    /// let narrowValue = UInt8(truncatingIfNeeded: storage)
    /// // narrowValue now contains 0b1101101 (0xDD), discarding the higher bits.
    /// ```
    ///
    /// - Parameter source: The `BitStorage` whose bits form the binary
    ///   representation of the integer.
    /// - Complexity: O(*n*), where *n* is `source.count`.
    @inlinable @inline(__always)
    init(truncatingIfNeeded source: __shared BitStorage) {
        self.init(truncatingIfNeeded: source[0 ..< source.count])
    }

    /// Creates a new fixed-width integer from an entire `BitStorage.SubSequence`,
    /// truncating (or sign-extending) any excess bits to fit `Self.bitWidth`.
    ///
    /// This initializer reads all bits in `source[0 ..< source.count]` as the
    /// integer’s binary representation. If the number of bits in `source`
    /// exceeds `Self.bitWidth`, the high-order bits are discarded. If `source`
    /// has fewer bits than `Self.bitWidth`, the missing bits are sign-extended
    /// if `Self` is signed, or zero-extended if `Self` is unsigned.
    ///
    /// ```swift
    /// // Example: Suppose 'storage' has 12 bits representing the value 0b101101101101.
    /// let storage = BitStorage()
    /// storage.append(bitPattern: 0b101101101101 as UInt16)
    ///
    /// // For a FixedWidthInteger like UInt8, only the lower 8 bits are kept.
    /// let narrowValue = UInt8(truncatingIfNeeded: storage)
    /// // narrowValue now contains 0b1101101 (0xDD), discarding the higher bits.
    /// ```
    ///
    /// - Parameter source: The `BitStorage.SubSequence` whose bits form the binary
    ///   representation of the integer.
    /// - Complexity: O(*n*), where *n* is `source.count`.
    @inlinable @inline(__always)
    init(truncatingIfNeeded source: __shared BitStorage.SubSequence) {
        self.init(_truncatingIfNeeded: source, bitWidth: Self.bitWidth)
    }
}
