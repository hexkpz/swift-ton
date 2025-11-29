//
//  Created by Anton Spivak
//

import Foundation

// MARK: - CellDecodable

/// A protocol for types that can be constructed from a TON `Cell` via
/// a `Cell.decode(_ type: (any CellDecodable.Type))` method.
///
/// Conforming types typically specify their `kind` (for example, `.ordinary`
/// or `.merkleProof`), then implement `init(from:)` to read bits and/or
/// child cells using a `CellDecodingContainer`. This allows you to parse
/// data stored in TON cells (including Merkle proofs, on-chain objects,
/// or smart contract states) directly into your Swift structures.
///
/// **Usage Example**:
/// ```swift
/// struct MyModel: CellDecodable {
///     static var kind: Cell.Kind { .merkleProof }
///
///     init(from container: inout CellDecodingContainer) throws {
///         // Read bits, child cells, etc., as needed for your model.
///         let flag = try container.decode(Bool.self)
///         // ...
///     }
/// }
/// ```
public protocol CellDecodable: _CellCodable {
    /// Initializes `Self` from a `CellDecodingContainer`, reading
    /// the necessary bits and/or child cells.
    ///
    /// - Parameter container: The container providing access to
    ///   the remaining bits and children in the original cell.
    /// - Throws: Any error encountered while decoding.
    ///
    /// Typical usage:
    /// ```swift
    /// init(from container: inout CellDecodingContainer) throws {
    ///     // consume bits, child references, etc.
    /// }
    /// ```
    init(from container: inout CellDecodingContainer) throws
}

// MARK: - CellDecoder

@usableFromInline
struct CellDecoder {
    // MARK: Lifecycle

    @usableFromInline
    init() {}

    // MARK: Internal

    @usableFromInline
    func decode<T>(_ type: T.Type, from cell: Cell) throws -> T where T: CellDecodable {
        var container = CellDecodingContainer(cell)
        return try T(from: &container)
    }
}

// MARK: - CellDecodingError

/// An error that can occur during cell decoding, such as a mismatch in expected `Cell.Kind`
/// for a child cell.
public enum CellDecodingError: Error {
    /// Indicates a child cell was expected to have a specific `kind`
    /// (e.g., `.merkleProof`), but the actual `kind` encountered
    /// was different.
    case childKindMismatch(expected: Cell.Kind, actual: Cell.Kind)
}

// MARK: CustomStringConvertible

extension CellDecodingError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .childKindMismatch(expected, actual):
            "Expected child kind is '\(expected)', but found '\(actual)' instead."
        }
    }
}

// MARK: LocalizedError

extension CellDecodingError: LocalizedError {
    public var errorDescription: String? { description }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ error: CellDecodingError) {
        appendLiteral("\(error.description)")
    }
}

// MARK: - CellDecodingContainer

/// A mutable container that provides sequential access to a cell’s bits
/// and child cells in the TON blockchain context. This container is used
/// internally during decoding to parse bit-level and child-level data
/// from an on-chain or in-memory cell representation.
///
/// It wraps two `ContinuousReader` instances — one for the cell’s bit storage
/// (`_storage`) and one for the cell’s children (`_children`). As you decode,
/// these readers' positions advance, ensuring each field is consumed in order.
public struct CellDecodingContainer: ~Copyable {
    // MARK: Lifecycle

    init(_ cell: Cell) {
        self.init(
            cell.kind,
            cell.storage[0 ..< cell.storage.count],
            cell.children[0 ..< cell.children.count]
        )
    }

    init(_ kind: Cell.Kind, _ storage: BitStorage.SubSequence, _ children: [Cell].SubSequence) {
        self._kind = kind
        self._storage = .init(storage)
        self._children = .init(children)
    }

    // MARK: Public

    /// Provides a read-only `ContinuousReader` for the remaining bits in this cell’s storage.
    @inlinable @inline(__always)
    public var storage: ContinuousReader<BitStorage> { ContinuousReader(_storage) }

    /// Provides a read-only `ContinuousReader` for the remaining child cells in this container.
    @inlinable @inline(__always)
    public var children: ContinuousReader<[Cell]> { ContinuousReader(_children) }

    // MARK: Internal

    /// The cell kind we expect for child decoding. Typically used if a child is expected
    /// to share the same kind or you need extra validation logic.
    @usableFromInline
    let _kind: Cell.Kind

    /// A `ContinuousReader` for bit-level storage within this cell.
    @usableFromInline
    var _storage: ContinuousReader<BitStorage>

    /// A `ContinuousReader` for child cells, consumed one at a time.
    @usableFromInline
    var _children: ContinuousReader<[Cell]>
}

public extension CellDecodingContainer {
    /// Reads and returns a single bit as a `Bool`, advancing the storage
    /// position by 1 bit.
    ///
    /// - Throws: `BoundariesError` if not enough bits remain.
    /// - Returns: A single bit interpreted as `Bool`.
    @inlinable @inline(__always)
    mutating func decode(_ value: Bool.Type) throws (BoundariesError) -> Bool {
        try _storage.read()
    }

    /// Reads a raw `BitStorage` of a given `bitWidth`, if specified, otherwise
    /// reads all remaining bits. Returns those bits in a new `BitStorage` object.
    ///
    /// - Parameter bitWidth: How many bits to read, or `nil` to read all remaining bits.
    /// - Throws: `BoundariesError` if there are not enough bits to satisfy the read.
    /// - Returns: A `BitStorage` object holding the requested bits.
    mutating func decode(bitWidth: Int? = nil) throws (BoundariesError) -> BitStorage {
        if let bitWidth {
            try BitStorage(_storage.read(bitWidth))
        } else {
            try BitStorage(_storage.read(_storage.remaining.count))
        }
    }
}

public extension CellDecodingContainer {
    /// Reads `byteWidth` bytes from the bit storage as a `Data`. If `nil`,
    /// reads the entire remaining bit storage (assuming it’s byte-aligned).
    ///
    /// - Parameter byteWidth: The number of bytes to read, or `nil` for all remaining.
    /// - Throws: `BoundariesError` if not enough bits remain or alignment is violated.
    /// - Returns: A `Data` containing the bytes read.
    mutating func decode(byteWidth: Int? = nil) throws (BoundariesError) -> Data {
        if let byteWidth {
            precondition(byteWidth >= 0, "Could't decode byte collection with negative width")
            return try BitStorage(_storage.read(byteWidth * 8))._data(byChunkSize: 8)
        } else {
            let remaining = _storage.remaining.count
            precondition(
                remaining % 8 == 0,
                "Couldn't decode byte collection with non-byte aligned remaining bits"
            )
            return try BitStorage(_storage.read(remaining))._data(byChunkSize: 8)
        }
    }
}

public extension CellDecodingContainer {
    /// Reads a `FixedWidthInteger` of type `V`, with an optional bitWidth limit.
    /// If `bitWidth` is `nil`, defaults to `V.bitWidth`.
    ///
    /// - Parameters:
    ///   - type: The integer type to read.
    ///   - bitWidth: How many bits to read, or `nil` to use `V.bitWidth`.
    /// - Returns: The decoded integer.
    /// - Throws: `BoundariesError` if there are insufficient bits.
    @inlinable @inline(__always)
    mutating func decode<V>(
        _ type: V.Type,
        truncatingToBitWidth bitWidth: Int? = nil
    ) throws (BoundariesError) -> V where V: FixedWidthInteger {
        try _storage.read(type, truncatingToBitWidth: bitWidth)
    }

    /// Reads an optional fixed-width integer from the cell, using a presence bit.
    /// If that bit is `true`, reads the next bits to form the integer. Otherwise returns `nil`.
    ///
    /// - Parameter bitWidth: How many bits to read if present; defaults to `V.bitWidth`.
    /// - Returns: The integer if present, else `nil`.
    /// - Throws: `BoundariesError` if insufficient bits remain.
    /// - Note: `Maybe (X)`
    @inlinable @inline(__always)
    mutating func decodeIfPresent<V>(
        _ type: V.Type,
        truncatingToBitWidth bitWidth: Int? = nil
    ) throws -> V? where V: FixedWidthInteger {
        try _storage.readIfPresent(type, truncatingToBitWidth: bitWidth)
    }
}

public extension CellDecodingContainer {
    /// Reads a type conforming to `ExpressibleByBitStorage` from the bit storage.
    /// This is useful for large numeric or custom binary-encoded data.
    ///
    /// - Parameter type: The type to read, must implement `init(bitStorage:inout)`.
    /// - Returns: A decoded instance of `V`.
    /// - Throws: `BoundariesError` if insufficient bits remain.
    @inlinable @inline(__always)
    mutating func decode<V>(_ type: V.Type) throws -> V where V: ExpressibleByBitStorage {
        try _storage.read(type)
    }

    /// Reads an optional type conforming to `ExpressibleByBitStorage`, first
    /// checking a presence bit. If absent, returns `nil`.
    ///
    /// - Returns: The decoded instance, or `nil` if absent.
    /// - Note: `Maybe (X)`
    @inlinable @inline(__always)
    mutating func decodeIfPresent<V>(_ type: V.Type) throws -> V? where V: ExpressibleByBitStorage {
        try _storage.readIfPresent(type)
    }

    /// Reads a type conforming to `ExpressibleByBitStorage` and
    /// `CustomOptionalBitStorageRepresentable`, where "nil" is indicated
    /// by a custom bit pattern rather than a single presence bit.
    ///
    /// - Returns: A decoded instance or `nil` if it matches the "nil" pattern.
    /// - Note: `Maybe (X)`
    @inlinable @inline(__always)
    mutating func decodeIfPresent<T>(
        _ type: T.Type
    ) throws -> T? where T: ExpressibleByBitStorage & CustomOptionalBitStorageRepresentable {
        try _storage.readIfPresent(type)
    }
}

public extension CellDecodingContainer {
    /// Reads the next child cell, ensuring its `kind` matches `T.kind`, then
    /// decodes it into `T` by calling `init(from:)`.
    ///
    /// - Parameter type: A `CellDecodable` type expecting a particular cell kind.
    /// - Returns: A decoded instance of `T`.
    /// - Throws:
    ///   - `BoundariesError` if no child cell is available.
    ///   - `CellDecodingError.childKindMismatch` if the child’s kind is not `T.kind`.
    ///   - Any error thrown by `T.init(from:)`.
    mutating func decode<T>(_ type: T.Type) throws -> T where T: CellDecodable {
        let child = try _children.read()
        guard child.kind == T.kind
        else {
            throw CellDecodingError.childKindMismatch(expected: T.kind, actual: child.kind)
        }
        var container = CellDecodingContainer(child)
        return try T(from: &container)
    }

    /// Decodes a `CellDecodable` inline from the current container’s data (bits/children)
    /// without extracting a separate child. This is typically used if you want to parse
    /// the existing cell content directly. For instance, a container might hold a nested
    /// structure in the same cell.
    ///
    /// - Parameter value: The `CellDecodable` type to decode from the container.
    /// - Returns: A decoded instance of `T`.
    /// - Throws: Any error from `T.init(from:)`.
    @inlinable @inline(__always)
    mutating func decode<T>(contentsOf value: T.Type) throws -> T where T: CellDecodable {
        try T(from: &self)
    }

    /// Reads an optional child cell by checking a presence bit first. If `true`, decodes
    /// the next child as `T`. If `false`, returns `nil`.
    ///
    /// - Parameter type: The type conforming to `CellDecodable`.
    /// - Returns: A decoded instance of `T` if present, else `nil`.
    /// - Throws: `BoundariesError` if bit or child cell are missing,
    ///   or `CellDecodingError` for a mismatched kind or decode failure.
    /// - Note: `Maybe (X)`
    @inlinable @inline(__always)
    mutating func decodeIfPresent<T>(_ type: T.Type) throws -> T? where T: CellDecodable {
        guard try _storage.read()
        else {
            return nil
        }
        return try decode(type)
    }

    /// Attempts to decode data from the *current container* if the presence bit is `false`,
    /// otherwise decodes the next child cell if the presence bit is `true`. This pattern is
    /// known as `Either X ^X`, often used in TL-B for optional direct or referenced data.
    ///
    /// - Parameter type: The `CellDecodable` type to decode.
    /// - Returns: The resulting instance of `T`.
    /// - Throws: If reading bits or child cells fails, or if `CellDecodingError` arises.
    ///
    /// **Example**:
    /// ```swift
    /// let item = try container.dissociateIfPossible(MyData.self)
    /// // if the next bit is '0', parse MyData from the same container,
    /// // otherwise parse it from the next child cell
    /// ```
    mutating func dissociateIfPossible<T>(_ type: T.Type) throws -> T where T: CellDecodable {
        guard try !_storage.read()
        else {
            // If the presence bit is true, decode from the next single child cell
            return try decode(type)
        }
        // If false, parse from current container bits/children
        return try T(from: &self)
    }

    /// Like `dissociateIfPossible(_:)`, but returns an optional. If the presence bit is
    /// `false`, returns `nil`. Otherwise, attempts to decode from either the next child
    /// or the current container, depending on the bit.
    ///
    /// - Parameter type: A `CellDecodable` type to parse if present.
    /// - Returns: A `T` instance if present, or `nil` otherwise.
    /// - Throws: If reading bits/child cells fails, or `CellDecodingError`.
    /// - Note: `Maybe (Either X ^X)`
    mutating func dissociateIfPossibleIfPresent<T>(
        _ type: T.Type
    ) throws -> T? where T: CellDecodable {
        guard try _storage.read()
        else {
            return nil
        }
        return try dissociateIfPossible(type)
    }
}

public extension CellDecodingContainer {
    /// Reads the next child cell directly (without kind checks) from `_children`.
    /// This is useful for raw reading if you don’t know the child's kind or plan
    /// to decode it manually.
    ///
    /// - Parameter type: A `Cell.Type` placeholder indicating you want the raw cell.
    /// - Returns: The child `Cell`.
    /// - Throws: `BoundariesError` if no child cell is available.
    @inlinable @inline(__always)
    mutating func decode(_ type: Cell.Type) throws (BoundariesError) -> Cell {
        try _children.read()
    }

    /// Decodes a new `Cell` by detaching the remaining bits/children from this container,
    /// optionally leaving some space behind. Typically used for advanced merges of cell data.
    ///
    /// - Parameters:
    ///   - kind: The `Cell.Kind` for the new cell.
    ///   - space: An optional reservation (bits/children) you do not want to consume here.
    /// - Returns: A newly constructed `Cell` with the bits/children read.
    /// - Throws: `BoundariesError` if there aren’t enough bits/children.
    mutating func decode(
        contentsOf kind: Cell.Kind,
        withLeftover space: CellContainerSpace? = nil
    ) throws -> Cell {
        return try Cell(
            kind,
            storage: .init(_storage.read(_storage.remaining.count - space.storage)),
            children: .init(_children.read(_children.remaining.count - space.children))
        )
    }

    /// Reads an optional child cell by checking a presence bit. If `true`, returns the
    /// next child cell; if `false`, returns `nil`.
    ///
    /// - Parameter type: A `Cell.Type` placeholder for raw cell reading.
    /// - Returns: The child `Cell` if present, otherwise `nil`.
    /// - Throws: `BoundariesError` if bit or child are missing.
    /// - Note: `Maybe (X)`
    mutating func decodeIfPresent(_ type: Cell.Type) throws (BoundariesError) -> Cell? {
        guard try _storage.read()
        else {
            return nil
        }
        return try _children.read()
    }

    /// Attempts to either detach the remaining data as a new cell (if the presence bit is `true`)
    /// or decode a single child cell (if it's `false`). This parallels `dissociateIfPossible(_:)`
    /// but for raw `Cell` usage.
    ///
    /// - Parameters:
    ///   - kind: The `Cell.Kind` to apply if we detach from the current container.
    ///   - space: An optional `CellContainerSpace` if you want to preserve some bits/children.
    /// - Returns: The resulting `Cell`.
    /// - Throws: If the bit or child reads fail, or if cell constraints are violated.
    /// - Note: `Either X ^X`
    mutating func dissociateIfPossible(
        _ kind: Cell.Kind,
        withLeftover space: CellContainerSpace? = nil
    ) throws -> Cell {
        guard try !_storage.read()
        else {
            // If presence bit is true, decode the next single child cell.
            return try decode(Cell.self)
        }

        // Otherwise, detach the leftover bits/children as a new cell of the specified kind.
        return try Cell(
            kind,
            storage: .init(_storage.read(_storage.remaining.count - space.storage)),
            children: .init(_children.read(_children.remaining.count - space.children))
        )
    }

    /// An optional version of `dissociateIfPossible(_:withLeftover:)`. If the presence bit
    /// is `false`, returns `nil`. Otherwise, detaches or reads the child cell as described.
    ///
    /// - Parameters:
    ///   - kind: The `Cell.Kind` for the new cell or for validation.
    ///   - space: Optional leftover space not to consume.
    /// - Returns: The resulting `Cell` if present, else `nil`.
    /// - Throws: If reading or cell building fails.
    /// - Note: `Maybe (Either X ^X)`
    mutating func dissociateIfPossibleIfPresent(
        _ kind: Cell.Kind,
        withLeftover space: CellContainerSpace? = nil
    ) throws -> Cell? {
        guard try _storage.read()
        else {
            return nil
        }
        return try dissociateIfPossible(kind, withLeftover: space)
    }
}
