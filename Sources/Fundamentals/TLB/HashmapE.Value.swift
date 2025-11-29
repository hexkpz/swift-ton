//
//  Created by Anton Spivak
//

import Foundation

// MARK: - HashmapE.Value

public extension HashmapE {
    /// Represents a value stored in a leaf node of the TON hashmap-e.
    /// A conforming type must provide ways to read/write itself from a
    /// "leaf container."
    ///
    /// **Example**:
    /// ```swift
    /// struct MyValue: HashmapE.Value {
    ///     init(fromLeafContainer c: inout CellDecodingContainer) throws { ... }
    ///     func encode(toLeafContainer c: inout CellEncodingContainer) throws { ... }
    /// }
    /// ```
    protocol Value {
        /// Initializes `Self` from a leaf container in the trie,
        /// reading any bits or child references if needed.
        init(fromLeafContainer container: inout CellDecodingContainer) throws

        /// Encodes `Self` into a leaf container, where no further forking is performed.
        func encode(toLeafContainer container: inout CellEncodingContainer) throws
    }
}

public extension CellDecodable where Self: HashmapE.Value {
    @inlinable @inline(__always)
    init(fromLeafContainer container: inout CellDecodingContainer) throws {
        try self.init(from: &container)
    }
}

public extension CellEncodable where Self: HashmapE.Value {
    @inlinable @inline(__always)
    func encode(toLeafContainer container: inout CellEncodingContainer) throws {
        try encode(to: &container)
    }
}

public extension ExpressibleByBitStorage where Self: HashmapE.Value {
    @inlinable @inline(__always)
    init(fromLeafContainer container: inout CellDecodingContainer) throws {
        self = try container.decode(Self.self)
    }
}

public extension BitStorageConvertible where Self: HashmapE.Value {
    @inlinable @inline(__always)
    func encode(toLeafContainer container: inout CellEncodingContainer) throws {
        try container.encode(self)
    }
}

public extension FixedWidthInteger where Self: HashmapE.Value {
    @inlinable @inline(__always)
    init(fromLeafContainer container: inout CellDecodingContainer) throws {
        self = try container.decode(Self.self)
    }

    @inlinable @inline(__always)
    func encode(toLeafContainer container: inout CellEncodingContainer) throws {
        try container.encode(self)
    }
}

// MARK: - Int + HashmapE.Value

extension Int: HashmapE.Value {}

// MARK: - Int8 + HashmapE.Value

extension Int8: HashmapE.Value {}

// MARK: - Int16 + HashmapE.Value

extension Int16: HashmapE.Value {}

// MARK: - Int32 + HashmapE.Value

extension Int32: HashmapE.Value {}

// MARK: - Int64 + HashmapE.Value

extension Int64: HashmapE.Value {}

// MARK: - UInt + HashmapE.Value

extension UInt: HashmapE.Value {}

// MARK: - UInt8 + HashmapE.Value

extension UInt8: HashmapE.Value {}

// MARK: - UInt16 + HashmapE.Value

extension UInt16: HashmapE.Value {}

// MARK: - UInt32 + HashmapE.Value

extension UInt32: HashmapE.Value {}

// MARK: - UInt64 + HashmapE.Value

extension UInt64: HashmapE.Value {}

// MARK: - Cell + HashmapE.Value

extension Cell: HashmapE.Value {
    @inlinable @inline(__always)
    public init(fromLeafContainer container: inout CellDecodingContainer) throws {
        self = try container.decode(Cell.self)
    }

    @inlinable @inline(__always)
    public func encode(toLeafContainer container: inout CellEncodingContainer) throws {
        try container.encode(self)
    }
}

// MARK: - BitStorage + HashmapE.Value

extension BitStorage: HashmapE.Value {
    @inlinable @inline(__always)
    public init(fromLeafContainer container: inout CellDecodingContainer) throws {
        self = try container.decode()
    }

    @inlinable @inline(__always)
    public func encode(toLeafContainer container: inout CellEncodingContainer) throws {
        try container.encode(self)
    }
}

// MARK: - Data + HashmapE.Value

extension Data: HashmapE.Value {
    @inlinable @inline(__always)
    public init(fromLeafContainer container: inout CellDecodingContainer) throws {
        self = try container.decode()
    }

    @inlinable @inline(__always)
    public func encode(toLeafContainer container: inout CellEncodingContainer) throws {
        try container.encode(self)
    }
}

// MARK: - VInt4 + HashmapE.Value

extension VInt4: HashmapE.Value {}

// MARK: - VUInt4 + HashmapE.Value

extension VUInt4: HashmapE.Value {}

// MARK: - VInt5 + HashmapE.Value

extension VInt5: HashmapE.Value {}

// MARK: - VUInt5 + HashmapE.Value

extension VUInt5: HashmapE.Value {}
