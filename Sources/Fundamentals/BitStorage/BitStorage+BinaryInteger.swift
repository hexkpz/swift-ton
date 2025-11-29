//
//  Created by Anton Spivak
//

public extension BinaryInteger {
    /// Initializes a new integer from the bits in the given `BitStorage`,
    /// truncating any excess bits to fit the integer type’s bit width if necessary.
    ///
    /// This initializer reads all bits in `source[0 ..< source.count]` in a
    /// left-to-right fashion, with the least significant bit in the rightmost
    /// position of the slice. It discards (truncates) any bits that exceed the
    /// integer’s capacity (e.g., if `Self` is `Int32`, it keeps at most 32 bits).
    ///
    /// ```swift
    /// let storage = BitStorage()
    /// // Suppose we append bits that correspond to the value 42
    /// storage.append(bitPattern: 42 as Int)
    ///
    /// // The following creates an integer by extracting bits from `storage`.
    /// let intValue = Int(truncatingIfNeeded: storage)
    /// // intValue == 42
    /// ```
    ///
    /// - Parameter source: The bit storage (`BitStorage`) from which to create the integer.
    init(truncatingIfNeeded source: __shared BitStorage) {
        self.init(truncatingIfNeeded: source[0 ..< source.count])
    }

    /// Initializes a new integer from the bits in the given `BitStorage.SubSequence`,
    /// truncating any excess bits to fit the integer type’s bit width if necessary.
    ///
    /// This initializer reads all bits in `source[0 ..< source.count]` in a
    /// left-to-right fashion, with the least significant bit in the rightmost
    /// position of the slice. It discards (truncates) any bits that exceed the
    /// integer’s capacity (e.g., if `Self` is `Int32`, it keeps at most 32 bits).
    ///
    /// ```swift
    /// let storage = BitStorage()
    /// // Suppose we append bits that correspond to the value 42
    /// storage.append(bitPattern: 42 as Int)
    ///
    /// // The following creates an integer by extracting bits from `storage`.
    /// let intValue = Int(truncatingIfNeeded: storage)
    /// // intValue == 42
    /// ```
    ///
    /// - Parameter source: The bit storage (`BitStorage.SubSequence`) from which to create the integer.
    init(truncatingIfNeeded source: __shared BitStorage.SubSequence) {
        self.init(_truncatingIfNeeded: source, bitWidth: source.count)
    }

    /// Initializes a new integer from a subrange of bits, explicitly specifying
    /// the intended bit width.
    @usableFromInline
    internal init(_truncatingIfNeeded source: __shared BitStorage.SubSequence, bitWidth: Int) {
        guard !source.isEmpty
        else {
            self = .zero
            return
        }

        // TODO: Optimize loading by 64-bit chunks
        var value: Self = .zero
        for i in (source.count - min(source.count, bitWidth)) ..< source.count {
            value <<= 1
            guard source[source.startIndex + i]
            else {
                continue
            }
            value |= 1
        }
        self = value
    }
}

public extension BitStorage {
    /// Creates a new `BitStorage` from a given integer's bit pattern.
    ///
    /// All bits of `value` are appended in a big-endian order, meaning the
    /// most significant bit of `value` appears at the beginning of the bit
    /// sequence. The resulting storage has exactly enough bits to represent
    /// the integer, with no truncation.
    ///
    /// ```swift
    /// let storage = BitStorage(bitPattern: 42 as Int)
    /// // `storage` now holds the bit pattern for decimal 42 (e.g., 0b101010)
    /// ```
    ///
    /// - Parameter value: The integer value whose bits should be stored.
    /// - Complexity: O(*n*) where *n* is the number of bits in `value`.
    @inlinable @inline(__always)
    init<T>(
        bitPattern value: __shared T
    ) where T: BinaryInteger {
        self.init()
        append(bitPattern: value, truncatingToBitWidth: nil)
    }

    /// Creates a new `BitStorage` from a given integer's bit pattern, optionally
    /// truncating to a specific bit width.
    ///
    /// If `truncatingToBitWidth` is provided, the storage is limited to that many
    /// bits, discarding any higher-order bits that exceed the specified width. If
    /// `nil`, the entire bit pattern is stored.
    ///
    /// ```swift
    /// // Create storage with all bits of `value`
    /// let fullStorage = BitStorage(bitPattern: 255 as UInt8, truncatingToBitWidth: nil)
    /// // Create storage with only the lower 4 bits of `value`
    /// let truncatedStorage = BitStorage(bitPattern: 255 as UInt8, truncatingToBitWidth: 4)
    /// // truncatedStorage contains 0b1111 (decimal 15)
    /// ```
    ///
    /// - Parameters:
    ///   - value: The integer value to be stored.
    ///   - bitWidth: An optional bit width to which the integer’s bits are truncated.
    /// - Complexity: O(*n*), where *n* is the number of bits in `value`.
    @inlinable @inline(__always)
    init<T>(
        bitPattern value: __shared T,
        truncatingToBitWidth bitWidth: Int?
    ) where T: BinaryInteger {
        self.init()
        append(bitPattern: value, truncatingToBitWidth: bitWidth)
    }
}

public extension BitStorage {
    /// Appends all bits of the given integer to the end of this `BitStorage`,
    /// preserving their order in big-endian format.
    ///
    /// If no bit width is provided, the entire bit pattern of `value` is appended.
    /// Otherwise, if `truncatingToBitWidth` is given, only the lower `bitWidth`
    /// bits are taken, discarding any remaining higher-order bits.
    ///
    /// ```swift
    /// var bits = BitStorage()
    /// bits.append(bitPattern: 255 as UInt8)
    /// // bits now holds the pattern for 0b11111111
    ///
    /// bits.append(bitPattern: 42 as Int, truncatingToBitWidth: 4)
    /// // This appends only the lower 4 bits of 42 (0b1010)
    /// // Now bits ends with 0b1010
    /// ```
    ///
    /// - Parameters:
    ///   - value: The integer value whose bits will be appended.
    ///   - bitWidth: An optional limit on the number of bits to append.
    @inlinable @inline(__always)
    mutating func append<T>(
        bitPattern value: __shared T
    ) where T: BinaryInteger {
        append(bitPattern: value, truncatingToBitWidth: nil)
    }

    /// Appends bits from the specified integer to this `BitStorage`, optionally
    /// truncating to a byte-based width.
    ///
    /// This method behaves like `append(bitPattern:truncatingToBitWidth:)`, but
    /// takes a `byteWidth` parameter. If provided, the integer is truncated to
    /// `byteWidth * 8` bits.
    ///
    /// ```swift
    /// var bits = BitStorage()
    ///
    /// // Appends the full 32-bit pattern for 1,000,000
    /// bits.append(bitPattern: 1_000_000 as Int, truncatingToByteWidth: nil)
    ///
    /// // Appends only the lower 16 bits of 1,000,000
    /// bits.append(bitPattern: 1_000_000 as Int, truncatingToByteWidth: 2)
    /// ```
    ///
    /// - Parameters:
    ///   - value: The integer value whose bits to append.
    ///   - byteWidth: The number of bytes (each 8 bits) to include.
    @inlinable @inline(__always)
    mutating func append<T>(
        bitPattern value: __shared T,
        truncatingToByteWidth byteWidth: Int?
    ) where T: BinaryInteger {
        var bitWidth: Int? = nil
        if let byteWidth {
            bitWidth = byteWidth * 8
        }
        append(bitPattern: value, truncatingToBitWidth: bitWidth)
    }

    /// Appends bits from the specified integer to this storage, optionally
    /// truncating to a given bit width.
    ///
    /// If `bitWidth` is provided, only the lower `bitWidth` bits of `value` are
    /// appended. If `bitWidth` exceeds `value.bitWidth`, zero-extension (for
    /// unsigned types) or sign-extension (for signed types) does not occur here;
    /// the extra bits simply remain as zeros in the final representation.
    ///
    /// Internally, the bits are interpreted in big-endian format, so the highest
    /// bits of `value` appear at the front of the appended segment.
    ///
    /// ```swift
    /// var bits = BitStorage()
    ///
    /// // Append the entire bit pattern of 42 (0b101010)
    /// bits.append(bitPattern: 42 as UInt8, truncatingToBitWidth: nil)
    ///
    /// // Append only 3 bits from 42 (result: 0b010)
    /// bits.append(bitPattern: 42 as UInt8, truncatingToBitWidth: 3)
    /// ```
    ///
    /// - Parameters:
    ///   - value: The integer to read bits from.
    ///   - bitWidth: If not `nil`, the maximum number of bits to append.
    mutating func append<T>(
        bitPattern value: __shared T,
        truncatingToBitWidth bitWidth: Int?
    ) where T: BinaryInteger {
        let valueWordBitWidth = T.Words.Element.bitWidth
        var targetBitWidth = value.bitWidth

        if let bitWidth {
            precondition(bitWidth >= 0, "Bit width must be positive")
            targetBitWidth = bitWidth
        }

        // reverse to BE sort array of words
        var words = value.words.reversed().map({ _Word(truncatingIfNeeded: $0) })
        let significatWordsCount =
            targetBitWidth / valueWordBitWidth +
            (targetBitWidth % valueWordBitWidth > 0 ? 1 : 0)

        if significatWordsCount < words.count {
            words.removeFirst(words.count - significatWordsCount)
        } else if significatWordsCount > words.count {
            words.insert(
                contentsOf: [_Word](repeating: 0, count: significatWordsCount - words.count),
                at: 0
            )
        }

        let allBitsCount = words.count * _Word.bitWidth
        let signifactBitsRange = (allBitsCount - targetBitWidth) ..< allBitsCount
        if signifactBitsRange.lowerBound > 0 {
            words = words._reduced(forBitRange: signifactBitsRange)
        }

        let _count = _count
        self._count += targetBitWidth

        _words._merge(with: words, fromBitCount: _count, targetBitCount: self._count)
    }
}
