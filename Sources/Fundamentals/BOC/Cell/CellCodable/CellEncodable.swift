//
//  Created by Anton Spivak
//

import Foundation

// MARK: - CellEncodable

/// A protocol for types that can be transformed into a `Cell` via
/// `Cell.init(_ encodable: any CellEncodable)`.
///
/// Conforming types should define:
/// - A static `kind: Cell.Kind` indicating the TON cell type (e.g. `.ordinary`).
/// - An `encode(to:)` method that writes the data into a `CellEncodingContainer`.
///
/// **Usage Example**:
/// ```swift
/// struct MyModel: CellEncodable {
///     static var kind: Cell.Kind { .ordinary }
///
///     func encode(to container: inout CellEncodingContainer) throws {
///         // Write bits, integers, or child cells
///         try container.encode(true)
///         try container.encode(42, truncatingToBitWidth: 8)
///         // possibly child cells:
///         try container.encode(NestedModel())
///     }
/// }
///
/// // Later:
/// let cell = try Cell(MyModel())
/// print(cell)
/// ```
public protocol CellEncodable: _CellCodable {
    /// Encodes this instance into the provided `CellEncodingContainer`.
    ///
    /// - Parameter container: The container that accumulates bits and child cells.
    /// - Throws: Any error encountered during encoding, such as exceeding cell bit limits.
    ///
    /// Conforming types should call methods like `container.encode(...)` or
    /// `container.concatIfPossible(...)` to add their data.
    func encode(to container: inout CellEncodingContainer) throws
}

// MARK: - CellEncoder

@usableFromInline
struct CellEncoder {
    // MARK: Lifecycle

    @usableFromInline
    init() {}

    // MARK: Internal

    /// Encodes a given `CellEncodable` value into a `Cell`.
    ///
    /// - Parameter value: The object conforming to `CellEncodable`.
    ///
    /// - Throws:
    ///   - `CellEncodingError` if the object violates some cell constraint
    ///   - `any Error` for any other encoding failure
    /// - Returns: A fully built `Cell` containing the encoded bits
    ///   and children.
    @usableFromInline
    func encode<T>(_ value: T) throws -> Cell where T: CellEncodable {
        var container = CellEncodingContainer(T.kind)
        try value.encode(to: &container)
        return try container.finilize()
    }
}

// MARK: - CellEncodingError

/// A typealias to `Cell.ConstraintError`, representing potential encoding
/// constraint violations (e.g., exceeding 1023 bits for `.ordinary` cells).
public typealias CellEncodingError = Cell.ConstraintError

// MARK: - CellEncodingContainer

/// A mutable container for accumulating bit storage and child references
/// before building a final `Cell`. During `encode(to:)`, call methods like
/// `encode(_:)`, `encodeIfPresent(_:)`, or `concatIfPossible(_:)` to write
/// data.
public struct CellEncodingContainer: ~Copyable {
    // MARK: Lifecycle

    init(_ kind: Cell.Kind) {
        self._kind = kind
    }

    init(_ cell: Cell) {
        self._kind = cell.kind
        self._storage = cell.storage
        self._children = cell.children
    }

    init(_ container: borrowing CellEncodingContainer) {
        self._kind = container._kind
        self._storage = container._storage
        self._children = container._children
    }

    // MARK: Public

    /// Returns the accumulated `BitStorage`.
    @inlinable @inline(__always)
    public var storage: BitStorage { _storage }

    /// Returns the accumulated child cells.
    @inlinable @inline(__always)
    public var children: [Cell] { _children }

    // MARK: Internal

    /// The final `Cell.Kind` (e.g., `.ordinary`) for which this container is building a cell.
    let _kind: Cell.Kind

    /// Accumulated bits for this cell.
    @usableFromInline
    var _storage: BitStorage = []

    /// Accumulated child `Cell`s nested under this cell.
    @usableFromInline
    var _children: [Cell] = []

    /// Finalizes the encoding process, checking any minimum bit or child requirements
    /// for `kind`, then returns a new `Cell`.
    ///
    /// - Throws: `CellEncodingError` if constraints (like min bits) are not met.
    /// - Returns: A fully-constructed `Cell`.
    @inline(__always)
    consuming func finilize() throws -> Cell {
        try _storage.checkMinimumValue(for: _kind)
        return try Cell(_kind, storage: _storage, children: _children)
    }
}

// MARK: CellEncodingContainer.RemainingData

public extension CellEncodingContainer {
    /// A type capturing how many bits and child references remain until
    /// we hit the maximum allowed for `kind`.
    typealias RemainingData = (storage: Int, children: Int)

    /// Returns a tuple describing how many more bits and child cells can be encoded
    /// without exceeding the maximum limits for this container’s `kind`.
    var remaining: RemainingData {
        (
            _storage.capacity(for: _kind) - _storage.count,
            _children.capacity(for: _kind) - _children.count
        )
    }
}

extension CellEncodingContainer {
    /// Attempts to concatenate another container’s bits and children
    /// if there is enough space, or encodes it as a separate child otherwise.
    ///
    /// Writes one bit to indicate the choice:
    /// - `false`: merging in the same cell
    /// - `true`: storing as a child cell
    ///
    /// - Parameters:
    ///   - container: Another `CellEncodingContainer` to combine with.
    ///   - space: An optional `CellContainerSpace` reservation.
    /// - Throws: `CellEncodingError` if any constraints are violated.
    /// - Note: `Either X ^X`
    mutating func concatIfPossible(
        _ container: consuming CellEncodingContainer,
        preserving space: CellContainerSpace?
    ) throws {
        let storage = _storage.count + container._storage.count + space.storage
        let children = _children.count + container._children.count + space.children

        var isConcatenationPossible = false
        do {
            // Simulate with dummy arrays of bits/children for capacity checks
            try [Bool](repeating: false, count: storage).checkMaximumValue(for: _kind)
            try [Cell](repeating: Cell(), count: children).checkMaximumValue(for: _kind)

            isConcatenationPossible = true
        } catch {}

        if isConcatenationPossible {
            try encode(false) // merging in the same cell

            _storage.append(contentsOf: container._storage)
            try _storage.checkMaximumValue(for: _kind)

            _children.append(contentsOf: container._children)
            try _children.checkMaximumValue(for: _kind)
        } else {
            try encode(true) // store as child cell
            try encode(container.finilize())
        }
    }
}

public extension CellEncodingContainer {
    /// Appends a single `Bool` bit to `storage`.
    ///
    /// - Parameter value: The bit to encode.
    /// - Throws: `CellEncodingError` if the container is out of space for bits.
    mutating func encode(_ value: Bool) throws (CellEncodingError) {
        _storage.append(value)
        try _storage.checkMaximumValue(for: _kind)
    }

    /// Appends multiple bits (any `Bool` collection) to `storage`.
    ///
    /// - Parameter value: The bits to encode.
    /// - Throws: `CellEncodingError` if bit space is exceeded.
    mutating func encode<T>(
        _ value: T
    ) throws (CellEncodingError) where T: Collection, T.Element == Bool {
        _storage.append(contentsOf: value)
        try _storage.checkMaximumValue(for: _kind)
    }
}

public extension CellEncodingContainer {
    /// Encodes a `Data` as bits in big-endian format.
    ///
    /// - Parameter data: The bytes to encode.
    /// - Throws: `CellEncodingError` if storage capacity is exceeded.
    mutating func encode(_ data: Data) throws (CellEncodingError) {
        _storage.append(contentsOf: BitStorage(data))
        try _storage.checkMaximumValue(for: _kind)
    }
}

public extension CellEncodingContainer {
    /// Encodes a `BinaryInteger` with optional truncation to a specified bit width.
    ///
    /// - Parameters:
    ///   - value: The integer to encode.
    ///   - bitWidth: If non-`nil`, truncates to that many bits.
    /// - Throws: `CellEncodingError` if constraints are exceeded.
    mutating func encode<T>(
        _ value: T,
        truncatingToBitWidth bitWidth: Int? = nil
    ) throws (CellEncodingError) where T: BinaryInteger {
        _storage.append(bitPattern: value, truncatingToBitWidth: bitWidth)
        try _storage.checkMaximumValue(for: _kind)
    }

    /// Encodes an optional integer, using a single presence bit first.
    ///
    /// - Parameters:
    ///   - value: The integer to encode, or `nil`.
    ///   - bitWidth: If non-`nil`, truncates the integer to that many bits.
    /// - Throws: `CellEncodingError` if constraints are exceeded.
    /// - Note: `Maybe (X)`
    mutating func encodeIfPresent<T>(
        _ value: T?,
        truncatingToBitWidth bitWidth: Int? = nil
    ) throws (CellEncodingError) where T: BinaryInteger {
        switch value {
        case .none:
            _storage.append(false)
            try _storage.checkMaximumValue(for: _kind)
        case let .some(value):
            _storage.append(true)
            try encode(value, truncatingToBitWidth: bitWidth)
        }
    }
}

public extension CellEncodingContainer {
    /// Encodes a type conforming to `BitStorageConvertible`.
    ///
    /// - Parameter value: The object to encode, which writes its bits via `appendTo(...)`.
    /// - Throws: `CellEncodingError` if capacity is exceeded.
    mutating func encode<T>(
        _ value: T
    ) throws (CellEncodingError) where T: BitStorageConvertible {
        value.appendTo(&_storage)
        try _storage.checkMaximumValue(for: _kind)
    }

    /// Encodes an optional `BitStorageConvertible`, with a presence bit.
    ///
    /// - Parameter value: The optional object to encode.
    /// - Throws: `CellEncodingError` if capacity is exceeded.
    /// - Note: `Maybe (X)`
    mutating func encodeIfPresent<T>(
        _ value: T?
    ) throws (CellEncodingError) where T: BitStorageConvertible {
        switch value {
        case .none:
            _storage.append(false)
            try _storage.checkMaximumValue(for: _kind)
        case let .some(value):
            _storage.append(true)
            try encode(value)
        }
    }

    /// Encodes an optional `BitStorageConvertible & CustomOptionalBitStorageRepresentable`
    /// using a custom nil bit pattern or presence logic.
    ///
    /// - Parameter value: The optional to encode.
    /// - Throws: `CellEncodingError` if capacity is exceeded.
    /// - Note: `Maybe (X)`
    mutating func encodeIfPresent<T>(
        _ value: T?
    ) throws (CellEncodingError)
        where T: BitStorageConvertible & CustomOptionalBitStorageRepresentable
    {
        switch value {
        case .none:
            _storage.append(contentsOf: T.nilBitStorageRepresentation)
            try _storage.checkMaximumValue(for: _kind)
        case let .some(value):
            try encode(value)
        }
    }
}

public extension CellEncodingContainer {
    /// Encodes a nested `CellEncodable` as a child cell.
    ///
    /// - Parameter value: The object to encode, which forms a separate cell.
    /// - Throws: `CellEncodingError` if child count or bit constraints are exceeded.
    mutating func encode<T>(_ value: T) throws where T: CellEncodable {
        var container = CellEncodingContainer(_kind)
        try value.encode(to: &container)

        try _children.append(container.finilize())
        try _children.checkMaximumValue(for: _kind)
    }

    /// Encodes the contents of a `CellEncodable` directly into this container,
    /// rather than as a separate child. The encodable type’s `encode(to:)`
    /// method writes bits/children to this container.
    ///
    /// - Parameter value: A `CellEncodable` whose data merges with the current container.
    /// - Throws: `CellEncodingError` if constraints are violated.
    mutating func encode<T>(contentsOf value: T) throws where T: CellEncodable {
        try value.encode(to: &self)
    }

    /// Encodes an optional `CellEncodable`, preceded by a presence bit.
    ///
    /// - Parameter value: The encodable object, or `nil`.
    /// - Throws: `CellEncodingError` if constraints are exceeded.
    /// - Note: `Maybe (X)`
    mutating func encodeIfPresent<T>(_ value: T?) throws where T: CellEncodable {
        switch value {
        case .none:
            _storage.append(false)
            try _storage.checkMaximumValue(for: _kind)
        case let .some(value):
            _storage.append(true)
            try encode(value)
        }
    }

    /// Attempts to merge `value` into this container’s bits/children if space allows,
    /// or appends it as a distinct child cell otherwise. A bit is written to indicate
    /// which approach was taken (`false` for merging, `true` for separate child).
    ///
    /// - Parameters:
    ///   - value: A `CellEncodable` to either merge or store as child.
    ///   - space: Optional leftover bits/children to preserve in this container.
    /// - Throws: `CellEncodingError` if constraints are violated.
    /// - Note: `Either X ^X`
    mutating func concatIfPossible<T>(
        _ value: T,
        preserving space: CellContainerSpace? = nil
    ) throws where T: CellEncodable {
        var container = CellEncodingContainer(T.kind)
        try value.encode(to: &container)
        try concatIfPossible(container, preserving: space)
    }

    /// Version of `concatIfPossible(_:)` for an optional `CellEncodable`. If `nil`, writes
    /// a `false` bit and does nothing else. If non-nil, writes `true` then attempts merging
    /// or storing as child.
    ///
    /// - Parameter value: The optional encodable object to process.
    /// - Parameter space: Reservation of bits/children not to exceed.
    /// - Throws: `CellEncodingError` if constraints fail.
    /// - Note: `Maybe (Either X ^X)`
    mutating func concatIfPossibleIfPresent<T>(
        _ value: T?,
        preserving space: CellContainerSpace? = nil
    ) throws where T: CellEncodable {
        switch value {
        case .none:
            _storage.append(false)
            try _storage.checkMaximumValue(for: _kind)
        case let .some(value):
            _storage.append(true)
            try concatIfPossible(value, preserving: space)
        }
    }
}

public extension CellEncodingContainer {
    /// Directly appends a pre-built `Cell` as a child to this container.
    ///
    /// - Parameter value: The cell to nest under this container’s cell.
    /// - Throws: `CellEncodingError` if child count is exceeded.
    mutating func encode(_ value: Cell) throws (CellEncodingError) {
        _children.append(value)
        try _children.checkMaximumValue(for: _kind)
    }

    /// Merges the storage/children of an existing `Cell` into this container,
    /// appending them directly to `storage` and `children`.
    ///
    /// - Parameter value: The cell whose bits/children are appended.
    /// - Throws: `CellEncodingError` if capacity is exceeded.
    mutating func encode(contentsOf value: Cell) throws (CellEncodingError) {
        _storage.append(contentsOf: value.storage)
        try _storage.checkMaximumValue(for: _kind)

        _children.append(contentsOf: value.children)
        try _children.checkMaximumValue(for: _kind)
    }

    /// Encodes an optional `Cell` with a presence bit. If `nil`, writes `false`.
    /// Otherwise, writes `true` and encodes the cell as a child.
    ///
    /// - Parameter value: The optional cell.
    /// - Throws: `CellEncodingError` if capacity is exceeded.
    /// - Note: `Maybe (X)`
    mutating func encodeIfPresent(_ value: Cell?) throws (CellEncodingError) {
        switch value {
        case .none:
            _storage.append(false)
            try _storage.checkMaximumValue(for: _kind)
        case let .some(value):
            _storage.append(true)
            try encode(value)
        }
    }

    /// Merges or appends an existing `Cell`, writing a bit to indicate the approach:
    /// - `false`: merge the cell’s bits/children into the current container,
    /// - `true`: store the entire cell as a child.
    ///
    /// - Parameters:
    ///   - value: The cell to incorporate.
    ///   - space: Optional leftover bits/children to keep free.
    /// - Throws: `CellEncodingError` if constraints are exceeded.
    /// - Note: `Either X ^X`
    mutating func concatIfPossible(
        _ value: Cell,
        preserving space: CellContainerSpace? = nil
    ) throws {
        try concatIfPossible(CellEncodingContainer(value), preserving: space)
    }

    /// Similar to `concatIfPossible(_:)` but for an optional `Cell`. If `nil`, writes `false`
    /// and does nothing. If non-`nil`, writes `true` and attempts merging or storing as child.
    ///
    /// - Parameter value: The optional cell to incorporate.
    /// - Throws: `CellEncodingError` if constraints are exceeded.
    /// - Note: `Maybe (Either X ^X)`
    mutating func concatIfPossibleIfPresent(
        _ value: Cell?,
        preserving space: CellContainerSpace? = nil
    ) throws {
        switch value {
        case .none:
            _storage.append(false)
            try _storage.checkMaximumValue(for: _kind)
        case let .some(value):
            _storage.append(true)
            try concatIfPossible(value, preserving: space)
        }
    }
}
