//
//  Created by Anton Spivak
//

public extension BitStorage {
    /// Creates a new `BitStorage` by copying the bits from the specified subsequence.
    ///
    /// This initializer reads bits from `elements` and creates a new storage
    /// of the exact same length. The `_words` array is built by reducing
    /// the subsequence’s bit range into the minimal set of words needed.
    ///
    /// ```swift
    /// let baseStorage = BitStorage([true, false, true, false])
    /// let slice = baseStorage[1..<3] // [false, true]
    /// let newStorage = BitStorage(slice)
    /// // newStorage.count == 2, holding bits [false, true]
    /// ```
    ///
    /// - Parameter elements: A `BitStorage.SubSequence` whose bits are copied
    ///   to the new storage.
    @inlinable @inline(__always)
    init(_ elements: __shared BitStorage.SubSequence) {
        _count = elements.count
        _words = elements._words
    }

    /// Appends the bits from a `BitStorage.SubSequence` to the end of this storage.
    ///
    /// This method increases the bit count by `elements.count`, merging the
    /// word array of the subsequence into the current storage.
    ///
    /// ```swift
    /// var bits = BitStorage([true, true])
    /// let slice = BitStorage([false, false, true])[1..<3] // [false, true]
    /// bits.append(contentsOf: slice)
    /// // bits now holds [true, true, false, true]
    /// ```
    ///
    /// - Parameter elements: The subsequence of bits to append.
    mutating func append(contentsOf elements: __shared BitStorage.SubSequence) {
        guard !elements.isEmpty
        else {
            return
        }

        let _count = count
        self._count += elements.count
        _words._merge(with: elements._words, fromBitCount: _count, targetBitCount: self._count)
    }

    /// Returns a copy of this storage with the bits from the provided subsequence appended.
    ///
    /// This method creates a new `BitStorage` by copying `self` and appending
    /// the given bits to the copy, leaving the original storage unchanged.
    ///
    /// ```swift
    /// let base = BitStorage([true, true])
    /// let slice = BitStorage([false, false, true])[1..<3] // [false, true]
    /// let combined = base.appending(contentsOf: slice)
    /// // combined == [true, true, false, true]
    /// // base remains unchanged
    /// ```
    ///
    /// - Parameter elements: The subsequence of bits to append.
    /// - Returns: A new `BitStorage` containing bits from the original storage
    ///   plus the appended bits.
    @inlinable @inline(__always)
    func appending(contentsOf elements: __shared BitStorage.SubSequence) -> BitStorage {
        var copy = self
        copy.append(contentsOf: elements)
        return copy
    }
}

extension BitStorage.SubSequence {
    /// An internal property that computes the `_Word` array for this subsequence’s bit range.
    @usableFromInline @inline(__always)
    var _words: [BitStorage._Word] { base._words._reduced(forBitRange: startIndex ..< endIndex) }
}
