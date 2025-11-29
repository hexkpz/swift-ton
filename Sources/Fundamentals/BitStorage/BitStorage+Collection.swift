//
//  Created by Anton Spivak
//

// MARK: - BitStorage + Sequence

extension BitStorage: Sequence {
    public typealias Element = Bool
    public typealias Iterator = IndexingIterator<BitStorage>
}

// MARK: - BitStorage + RandomAccessCollection

extension BitStorage: RandomAccessCollection {
    public typealias Index = Int
    public typealias SubSequence = Slice<BitStorage>
    public typealias Indices = Range<Int>

    /// The total number of bits in this storage.
    @inlinable @inline(__always)
    public var count: Int { Int(_count) }

    /// The starting index of this collection, always `0`.
    @inlinable @inline(__always)
    public var startIndex: Int { 0 }

    /// The ending index of this collection, equal to the number of bits.
    @inlinable @inline(__always)
    public var endIndex: Int { count }

    /// Returns the index immediately after `i`.
    @inlinable @inline(__always)
    public func index(after i: Int) -> Int { i + 1 }

    /// Returns the index immediately before `i`.
    @inlinable @inline(__always)
    public func index(before i: Int) -> Int { i - 1 }

    /// Advances the given index by one position.
    @inlinable @inline(__always)
    public func formIndex(after i: inout Int) { i += 1 }

    /// Moves the given index back by one position.
    @inlinable @inline(__always)
    public func formIndex(before i: inout Int) { i -= 1 }

    /// Returns `i` offset by `distance`.
    @inlinable @inline(__always)
    public func index(_ i: Int, offsetBy distance: Int) -> Int { i + distance }

    /// Returns an index offset by `distance` from `i`,
    /// or `nil` if that move would pass `limit`.
    public func index(
        _ i: Index, offsetBy distance: Int, limitedBy limit: Index
    ) -> Index? {
        let l = self.distance(from: i, to: limit)
        if distance > 0 ? l >= 0 && l < distance : l <= 0 && distance < l {
            return nil
        }
        return index(i, offsetBy: distance)
    }

    /// Returns the distance between two indices.
    @inlinable @inline(__always)
    public func distance(from start: Int, to end: Int) -> Int { end - start }

    /// Accesses the bit at the specified position.
    ///
    /// - Parameter position: A valid index of the collection.
    /// - Returns: `true` if the bit at `position` is set, otherwise `false`.
    /// - Precondition: `position` must be in `0..<count`.
    public subscript(position: Int) -> Bool {
        get {
            precondition(position >= 0 && position < _count, "Index out of bounds")
            let position = _words[bitIndex: position]
            return _words[bitPosition: position]
        }
        set {
            precondition(position >= 0 && position < _count, "Index out of bounds")
            let position = _words[bitIndex: position]
            _words[bitPosition: position] = newValue
        }
    }

    /// Returns a slice of this bit storage covering `bounds`.
    ///
    /// - Parameter bounds: A valid range within `[startIndex, endIndex]`.
    /// - Returns: A slice of the bits in the specified range.
    public subscript(bounds: Range<Int>) -> SubSequence {
        precondition(bounds.lowerBound >= 0 && bounds.upperBound <= _count, "Out of bounds")
        return Slice(base: self, bounds: bounds)
    }
}

// MARK: - BitStorage + MutableCollection

extension BitStorage: MutableCollection {}

public extension BitStorage {
    /// Creates a new `BitStorage` from an existing one, copying all bits.
    ///
    /// - Parameter elements: Another `BitStorage` whose bits are copied.
    @inlinable @inline(__always)
    init(_ elements: BitStorage) {
        self.init()
        append(contentsOf: elements)
    }

    /// Appends all bits from another `BitStorage` to this one.
    ///
    /// - Parameter elements: The `BitStorage` to append.
    @inlinable @inline(__always)
    mutating func append(contentsOf elements: __shared BitStorage) {
        append(contentsOf: elements[0 ..< elements.count])
    }

    /// Returns a new `BitStorage` containing the bits of this storage
    /// followed by the bits of another `BitStorage`.
    ///
    /// - Parameter elements: The bits to append.
    /// - Returns: A new `BitStorage` instance containing the combined bits.
    @inlinable @inline(__always)
    func appending(contentsOf elements: __shared BitStorage) -> Self {
        var copy = self
        copy.append(contentsOf: elements)
        return copy
    }
}

public extension BitStorage {
    /// Creates a new `BitStorage` from any `Sequence` of `Bool`.
    ///
    /// - Parameter elements: A sequence of `Bool` values to store.
    @inlinable @inline(__always)
    init<T>(_ elements: __shared T) where T: Sequence, T.Element == Element {
        self.init()
        append(contentsOf: elements)
    }

    /// Appends bits from any `Sequence` of `Bool` to this `BitStorage`.
    ///
    /// If `elements` is a `BitStorage` or a `BitStorage.SubSequence`, this
    /// method delegates to specialized overloads. Otherwise, it calls
    /// `_append(contentsOf:)` to handle arbitrary sequences efficiently.
    ///
    /// - Parameter elements: A sequence of bits (`Bool`).
    mutating func append<T>(
        contentsOf elements: __shared T
    ) where T: Sequence, T.Element == Element {
        if let elements = elements as? BitStorage {
            append(contentsOf: elements)
        } else if let elements = elements as? BitStorage.SubSequence {
            append(contentsOf: elements)
        } else {
            _append(contentsOf: elements)
        }
    }

    /// Returns a copy of this storage with bits from the specified sequence appended.
    ///
    /// - Parameter elements: A sequence of `Bool` bits to append.
    /// - Returns: A new `BitStorage` containing the combined bits.
    @inlinable @inline(__always)
    func appending<T>(
        contentsOf elements: __shared T
    ) -> Self where T: Sequence, T.Element == Element {
        var copy = self
        copy.append(contentsOf: elements)
        return copy
    }

    /// Appends bits from an arbitrary sequence of `Bool` into this storage.
    /// This is a helper method for the general `append(contentsOf:)` above.
    internal mutating func _append<T>(
        contentsOf elements: __shared T
    ) where T: Sequence, T.Element == Element {
        var iterator = elements.makeIterator()
        let elements = iterator._elements()
        guard !elements.isEmpty
        else {
            return
        }

        let _count = _count
        self._count += elements.count
        _words._merge(with: elements.0, fromBitCount: _count, targetBitCount: self._count)
    }
}

extension IteratorProtocol where Element == BitStorage.Element {
    /// Consumes all bits from the iterator, packing them into `_Word` blocks.
    /// Returns the array of words, total bit count, and a flag indicating
    /// if any bits were found.
    mutating func _elements() -> ([BitStorage._Word], count: Int, isEmpty: Bool) {
        let bitWidth = BitStorage._Word.bitWidth

        var words: [BitStorage._Word] = []
        var count = 0

        var word = BitStorage._Word()
        while let element = next() {
            count += 1
            word <<= 1

            if element {
                word |= 1
            }

            if count % bitWidth == 0 {
                words.append(word)
                word = 0
            }
        }

        let remaining = bitWidth - (count % bitWidth)
        if remaining < bitWidth {
            word <<= remaining
            words.append(word)
        }

        return (words, count, count == 0)
    }
}
