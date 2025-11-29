//
//  Created by Anton Spivak
//

/// A typealias that combines both `BitStorageConvertible` and `ExpressibleByBitStorage`.
public typealias BitStorageRepresentable = BitStorageConvertible & ExpressibleByBitStorage

// MARK: - BitStorageConvertible

/// A protocol for types that can append their bit representation to a
/// `BitStorage` instance.
///
/// Conforming types should implement `appendTo(_:)`, which writes their
/// bit pattern into the provided `BitStorage`.
public protocol BitStorageConvertible {
    /// Appends the bit representation of the conforming type
    /// into the specified `BitStorage`.
    ///
    /// - Parameter bitStorage: The storage to which bits are appended.
    func appendTo(_ bitStorage: inout BitStorage)
}

public extension BitStorageConvertible {
    /// Returns a new `BitStorage` containing the bits of the conforming type.
    ///
    /// This default implementation creates an empty `BitStorage` and calls
    /// `appendTo(_:)` to populate it.
    ///
    /// ```swift
    /// struct MyStruct: BitStorageConvertible {
    ///     func appendTo(_ bitStorage: inout BitStorage) {
    ///         // Implementation details...
    ///     }
    /// }
    ///
    /// let myStruct = MyStruct()
    /// let storage = myStruct.bitStorage
    /// // 'storage' now contains the bits for 'myStruct'
    /// ```
    var bitStorage: BitStorage {
        var bitStorage = BitStorage()
        appendTo(&bitStorage)
        return bitStorage
    }

    func appendTo(_ container: inout CellEncodingContainer) throws(CellEncodingError) {
        try container.encode(bitStorage)
    }
}

// MARK: - ExpressibleByBitStorage

/// A protocol for types that can be initialized from a `BitStorage` by
/// consuming bits in sequence, as provided by a `ContinuousReader<BitStorage>`.
///
/// Conforming types must implement an initializer that takes an
/// `inout ContinuousReader<BitStorage>` and reads the necessary bits
/// to fully construct `Self`.
public protocol ExpressibleByBitStorage {
    /// Initializes the conforming type by reading bits from a continuous
    /// `BitStorage` reader.
    ///
    /// - Parameter bitStorage: A `ContinuousReader` wrapping a `BitStorage`,
    ///   from which the type should consume bits.
    /// - Throws: Any error encountered while parsing bits.
    init(bitStorage: inout ContinuousReader<BitStorage>) throws
}

public extension ExpressibleByBitStorage {
    /// Initializes the conforming type from a plain `BitStorage` by internally
    /// creating a `ContinuousReader`.
    ///
    /// ```swift
    /// struct MyStruct: ExpressibleByBitStorage {
    ///     init(bitStorage: inout ContinuousReader<BitStorage>) throws {
    ///         // Implementation details...
    ///     }
    /// }
    ///
    /// let storage = BitStorage([true, false, true])
    /// let myStruct = try MyStruct(bitStorage: storage)
    /// ```
    ///
    /// - Parameter bitStorage: The `BitStorage` from which bits are read.
    /// - Throws: Any error encountered while parsing bits.
    init(bitStorage: BitStorage) throws {
        var bitStorage = ContinuousReader<BitStorage>(bitStorage)
        try self.init(bitStorage: &bitStorage)
    }

    /// Initializes the conforming type from a `BitStorage.SubSequence` by
    /// creating a `ContinuousReader`.
    ///
    /// ```swift
    /// let fullStorage = BitStorage([true, true, false])
    /// let subsequence = fullStorage[0..<2] // [true, true]
    ///
    /// struct MyStruct: ExpressibleByBitStorage {
    ///     init(bitStorage: inout ContinuousReader<BitStorage>) throws {
    ///         // Implementation details...
    ///     }
    /// }
    ///
    /// let myStruct = try MyStruct(bitStorage: subsequence)
    /// // 'myStruct' is initialized from the subsequence bits
    /// ```
    ///
    /// - Parameter bitStorage: A subsequence of a `BitStorage`.
    /// - Throws: Any error encountered while parsing bits.
    init(bitStorage: BitStorage.SubSequence) throws {
        var bitStorage = ContinuousReader<BitStorage>(bitStorage)
        try self.init(bitStorage: &bitStorage)
    }
}

// MARK: - CustomOptionalBitStorageRepresentable

/// A protocol that provides a special "nil" bit storage representation
/// for optional-like TL-B types.
///
/// Conforming types declare a static `nilBitStorageRepresentation`,
/// which represents a "nil" value in bits.
public protocol CustomOptionalBitStorageRepresentable {
    /// A special `BitStorage` that indicates `nil` or an absence of value.
    static var nilBitStorageRepresentation: BitStorage { get }
}
