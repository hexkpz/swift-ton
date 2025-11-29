//
//  Created by Anton Spivak
//

// MARK: - BitStorage

/// A bit-level storage that organizes its bits in MSB-first order using a
/// big-endian representation.
///
/// This type maintains the total number of stored bits and provides methods
/// for appending new bits. Because it uses a big-endian, MSB-first layout,
/// the highest-indexed bit is conceptually placed at the beginning of the
/// sequence, similar to how binary numbers are typically represented.
///
/// ### Usage
/// You can create an empty `BitStorage` instance and then append bits with
/// the `append(_:)` or `appending(_:)` methods:
/// ```swift
/// var storage = BitStorage()
/// storage.append(true)  // Appends a '1' bit
/// storage.append(false) // Appends a '0' bit
/// // Now 'storage' has 2 bits
/// ```
///
/// - Note: Internally, bits are stored in `_words` with the total count
///   tracked by `_count`. You normally don't need to manipulate these
///   properties directly unless you're extending `BitStorage` with low-level
///   operations.
public struct BitStorage {
    // MARK: Lifecycle

    /// Creates an empty bit storage.
    ///
    /// - Complexity: O(1)
    public init() {
        self._count = 0
        self._words = []
    }

    public init(repeating value: Bool, count: Int) {
        self._count = count
        self._words = []

        _truncateToBitWidth()
        guard value
        else {
            return
        }

        // TODO: Rewrite with bit `_word` mask
        for i in 0 ..< count { self[i] = true }
    }

    // MARK: Public

    /// Appends a single bit to the end of this storage.
    ///
    /// This increases the total bit count by one. If `value` is `true`, the
    /// appended bit is set (1); otherwise, it is unset (0).
    ///
    /// ```swift
    /// var bits = BitStorage()
    /// bits.append(true)  // Appends a 1 bit
    /// bits.append(false) // Appends a 0 bit
    /// // bits now contains 2 bits
    /// ```
    /// - Parameter value: The bit (`true` for 1, `false` for 0) to append.
    /// - Complexity: O(1) amortized.
    public mutating func append(_ value: Bool) {
        _count += 1
        _truncateToBitWidth()

        guard value
        else {
            return
        }

        let position = _words[bitIndex: _count - 1]
        _words[bitPosition: position] = true
    }

    /// Returns a new `BitStorage` instance with the specified bit appended.
    ///
    /// This method creates a copy of the existing bits, then appends the new bit.
    /// The original `BitStorage` remains unchanged.
    ///
    /// ```swift
    /// let original = BitStorage()
    /// let updated = original.appending(true)
    /// // original remains empty
    /// // updated has 1 bit set to 'true'
    /// ```
    /// - Parameter value: The bit (`true` for 1, `false` for 0) to append.
    /// - Returns: A new `BitStorage` instance containing all original bits plus
    ///   the new bit.
    /// - Complexity: O(n), where n is the number of bits in this storage.
    @inlinable @inline(__always)
    public func appending(_ value: Bool) -> Self {
        var copy = self
        copy.append(value)
        return copy
    }

    // MARK: Internal

    /// The internal array of `_Word` values storing this collection’s bits.
    @usableFromInline
    var _words: [_Word]

    /// The total number of bits in this storage.
    @usableFromInline
    var _count: Int
}

// MARK: Equatable

extension BitStorage: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs._count == rhs._count
        else {
            return false
        }
        return lhs._words == rhs._words
    }
}

// MARK: Hashable

extension BitStorage: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_count)
        hasher.combine(_words)
    }
}

// MARK: Sendable

extension BitStorage: Sendable {}
