//
//  Created by Anton Spivak
//

import Foundation

// MARK: - ContinuousReader

/// A sequential reader that allows pulling one element or a subrange
/// from a `RandomAccessCollection` without exceeding its bounds.
///
/// `ContinuousReader` maintains an internal "caret" index that marks the
/// current reading position. You can read individual elements or subranges,
/// and the `caret` will advance accordingly. If a read goes out of the
/// valid bounds, a `BoundariesError` is thrown.
public struct ContinuousReader<T>: ~Copyable where T: Collection, T.Index == Int {
    // MARK: Lifecycle

    /// Creates a new reader by wrapping the given collection, reading
    /// from its start to its end index.
    ///
    /// ```swift
    /// let array = [10, 20, 30]
    /// var reader = ContinuousReader(rawValue: array)
    /// // The reader can now read from the first to the last element.
    /// ```
    ///
    /// - Parameter rawValue: A collection to be read sequentially.
    @inlinable @inline(__always)
    public init(_ rawValue: T) {
        self.rawValue = rawValue[0 ..< rawValue.endIndex]
    }

    /// Creates a new reader from a subsequence, preserving the subrange
    /// as the read limit.
    ///
    /// - Parameter rawValue: A subsequence that defines the slice to read.
    @inlinable @inline(__always)
    public init(_ rawValue: T.SubSequence) {
        self.rawValue = rawValue
    }

    @inlinable @inline(__always)
    public init(_ continuousReader: borrowing ContinuousReader<T>) {
        self.rawValue = continuousReader.rawValue
        self.caret = continuousReader.caret
    }

    // MARK: Public

    /// The underlying subsequence that this reader is consuming.
    ///
    /// The `caret` index moves within this subsequence as elements are read.
    public let rawValue: T.SubSequence

    /// Returns the remaining portion of `rawValue` from the current `caret`
    /// position to the end of the subsequence.
    ///
    /// ```swift
    /// var reader = ContinuousReader(rawValue: [10, 20, 30][0..<3])
    /// _ = try? reader.read() // read 10
    /// // Now 'remainingCollectionData' might be [20, 30]
    /// ```
    @inlinable @inline(__always)
    public var remaining: T.SubSequence {
        rawValue[rawValue.startIndex + caret ..< rawValue.startIndex + rawValue.count]
    }

    /// Moves the `caret` backward by the specified `count`. Throws
    /// `BoundariesError` if the new `caret` would go below 0.
    ///
    /// - Parameter count: How many elements to revert.
    /// - Throws: `BoundariesError` if the new `caret` is out of bounds.
    public mutating func back(_ count: Int) throws(BoundariesError) {
        let _caret = caret - count
        guard _caret >= 0
        else {
            throw .init()
        }
        caret = _caret
    }

    /// Moves the `caret` to the very end of the remaining data, effectively
    /// "finishing" the read.
    @inlinable @inline(__always)
    public mutating func finish() {
        caret += remaining.count
    }

    /// Reads exactly one element, advancing `caret` by 1.
    ///
    /// - Throws: `BoundariesError` if no elements remain.
    /// - Returns: The next element from the collection.
    @inlinable @inline(__always)
    public mutating func read() throws(BoundariesError) -> T.Element {
        let value = try _read()
        caret += 1
        return value
    }

    /// Reads `count` elements as a `SubSequence`, advancing `caret` by `count`.
    ///
    /// - Parameter count: How many elements to read.
    /// - Throws: `BoundariesError` if fewer than `count` elements remain.
    /// - Returns: A subsequence containing the next `count` elements.
    @inlinable @inline(__always)
    public mutating func read(_ count: Int) throws(BoundariesError) -> T.SubSequence {
        let value = try _read(count)
        caret += count
        return value
    }

    // MARK: Internal

    /// The current reading position within `rawValue`.
    @usableFromInline
    var caret: Int = 0

    /// Reads a single element without advancing the `caret`.
    ///
    /// - Throws: `BoundariesError` if `caret` is out of bounds.
    @usableFromInline
    func _read() throws(BoundariesError) -> T.Element {
        guard caret < rawValue.count
        else {
            throw .init()
        }
        return rawValue[rawValue.startIndex + caret]
    }

    /// Reads `count` elements without advancing the `caret`.
    ///
    /// - Throws: `BoundariesError` if there are not enough elements remaining.
    @usableFromInline
    func _read(_ count: Int) throws(BoundariesError) -> T.SubSequence {
        let _caret = caret + count
        guard _caret <= rawValue.count
        else {
            throw .init()
        }
        return rawValue[rawValue.startIndex + caret ..< rawValue.startIndex + _caret]
    }
}

public extension ContinuousReader where T == BitStorage {
    /// Creates a reader from a `Data` by first converting
    /// the bytes into a `BitStorage`.
    ///
    /// - Parameter data: A collection of bytes to be converted
    ///   into `BitStorage`.
    @inlinable @inline(__always)
    init(_ data: Data) {
        self.init(BitStorage(data))
    }

    /// Reads a `FixedWidthInteger` of type `V`, expecting `bitWidth` bits
    /// (or `V.bitWidth` if `bitWidth` is `nil`), then truncates or sign-extends
    /// as needed.
    ///
    /// - Parameters:
    ///   - type: The integer type to read.
    ///   - bitWidth: An optional override of the number of bits to read.
    /// - Throws: `BoundariesError` if there are not enough bits remaining.
    /// - Returns: An integer of type `V`.
    mutating func read<V>(
        _ type: V.Type,
        truncatingToBitWidth bitWidth: Int? = nil
    ) throws(BoundariesError) -> V where V: FixedWidthInteger {
        try V(truncatingIfNeeded: read(bitWidth ?? V.bitWidth))
    }

    /// Reads an optional `FixedWidthInteger`, using a single bit to indicate
    /// presence (`true`) or absence (`false`). If the bit is `false`, this
    /// method returns `nil`. Otherwise, it reads `bitWidth` bits (or `V.bitWidth`)
    /// to form the integer.
    ///
    /// - Parameters:
    ///   - type: The integer type to read if present.
    ///   - bitWidth: An optional override of the number of bits to read.
    /// - Throws: `BoundariesError` if there are not enough bits remaining.
    /// - Returns: An optional integer of type `V`.
    @inlinable @inline(__always)
    mutating func readIfPresent<V>(
        _ type: V.Type,
        truncatingToBitWidth bitWidth: Int? = nil
    ) throws(BoundariesError) -> V? where V: FixedWidthInteger {
        guard try read()
        else {
            return nil
        }
        return try read(type, truncatingToBitWidth: bitWidth)
    }
}

public extension ContinuousReader where T == BitStorage {
    /// Reads a value `V` of any type conforming to `ExpressibleByBitStorage`
    /// by passing `self` as an inout reader to `V.init(bitStorage:)`.
    ///
    /// - Parameter type: The type conforming to `ExpressibleByBitStorage`.
    /// - Throws: `BoundariesError` if there are not enough bits to read `V`.
    /// - Returns: A newly created instance of `V`.
    @inlinable @inline(__always)
    mutating func read<V>(_ type: V.Type) throws -> V where V: ExpressibleByBitStorage {
        try V(bitStorage: &self)
    }

    /// Reads an optional value `V` of a type conforming to `ExpressibleByBitStorage`,
    /// using a single bit to indicate presence (`true`) or absence (`false`).
    /// If absent, returns `nil`.
    ///
    /// - Parameter type: The type conforming to `ExpressibleByBitStorage`.
    /// - Throws: `BoundariesError` if there are not enough bits remaining.
    /// - Returns: An optional `V`, or `nil` if the presence bit was `false`.
    mutating func readIfPresent<V>(_ type: V.Type) throws -> V? where V: ExpressibleByBitStorage {
        guard try read()
        else {
            return nil
        }
        return try V(bitStorage: &self)
    }

    /// Reads a value `V` that conforms to both `ExpressibleByBitStorage`
    /// and `CustomOptionalBitStorageRepresentable`, using the custom "nil"
    /// representation from `V.nilBitStorageRepresentation`. If the bits match
    /// that representation, returns `nil`. Otherwise, reverts the caret by
    /// 2 bits and reads `V`.
    ///
    /// This design implies the "nil" representation typically uses at least
    /// 2 bits, to allow a backward step and re-interpret the data if it's not nil.
    ///
    /// - Parameter type: A type conforming to both `ExpressibleByBitStorage`
    ///   and `CustomOptionalBitStorageRepresentable`.
    /// - Throws: `BoundariesError` if there are not enough bits to confirm nil
    ///   or read the full `V`.
    /// - Returns: An optional `V`, or `nil` if the read bits match the type’s
    ///   custom nil representation.
    mutating func readIfPresent<V>(
        _ type: V.Type
    ) throws -> V? where V: ExpressibleByBitStorage & CustomOptionalBitStorageRepresentable {
        let nilRepresentation = V.nilBitStorageRepresentation
        guard try BitStorage(read(nilRepresentation.count)) != nilRepresentation
        else {
            return nil
        }
        try back(2)
        return try read(type)
    }
}
