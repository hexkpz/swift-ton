//
//  Created by Anton Spivak
//

//
//  Created by Anton Spivak
//
import Foundation

// MARK: - CellComponent

/// A lightweight abstraction representing a single data encoding operation
/// (e.g., appending a `Bool`, a `BitStorage`, an optional integer, a `Cell`, etc.)
/// to a `CellEncodingContainer`. Each `CellComponent` stores a closure that knows
/// how to perform the encoding when executed, enabling you to easily collect and
/// apply these components in sequence.
///
/// **Example**:
/// ```swift
/// // Create multiple components
/// let components: [CellComponent] = [
///     .init(true),             // encodes a single bit
///     .init(42, truncatingToBitWidth: 8), // encodes 42 in 8 bits
///     .init(someEncodableModel) // encodes a child cell
/// ]
///
/// // Build a cell of kind .ordinary
/// let cell = try components.build(.ordinary)
/// print(cell)
/// ```
public struct CellComponent {
    // MARK: Lifecycle

    /// Creates a component representing a single `Bool` bit.
    /// When applied, this appends one bit to the container’s storage.
    @inlinable @inline(__always)
    public init(_ value: Bool) {
        self.value = { try $0.encode(value) }
    }

    /// Creates a component for a `BitStorage`, appending all its bits to
    /// the container.
    @inlinable @inline(__always)
    public init(_ value: BitStorage) {
        self.value = { try $0.encode(value) }
    }

    /// Creates a component for a `Data`, encoding its bytes as bits
    /// in big-endian format into the container.
    @inlinable @inline(__always)
    public init(_ value: Data) {
        self.value = { try $0.encode(value) }
    }

    // MARK: Internal

    /// The core closure that takes a `CellEncodingContainer` and encodes
    /// the stored value into it.
    @usableFromInline
    let value: (_ container: inout CellEncodingContainer) throws -> Void
}

public extension CellComponent {
    /// Creates a component that encodes a fixed-width integer, optionally
    /// truncating to a specific bit width.
    ///
    /// **Example**:
    /// ```swift
    /// // encodes 42 into 8 bits
    /// let intComponent = CellComponent(42, truncatingToBitWidth: 8)
    /// ```
    @inlinable @inline(__always)
    init<T>(_ value: T, truncatingToBitWidth bitWidth: Int? = nil) where T: FixedWidthInteger {
        self.value = { try $0.encode(value, truncatingToBitWidth: bitWidth) }
    }

    /// Creates a component encoding an optional integer, preceded by a
    /// presence bit. If `nil`, encodes `false`; otherwise, encodes `true`
    /// and the integer bits.
    ///
    /// **Example**:
    /// ```swift
    /// let optionalInt: Int? = 100
    /// let component = CellComponent(ifPresent: optionalInt)
    /// ```
    /// - Note: `Maybe (X)`
    @inlinable @inline(__always)
    init<T>(
        ifPresent value: T?,
        truncatingToBitWidth bitWidth: Int? = nil
    ) where T: FixedWidthInteger {
        self.value = { try $0.encodeIfPresent(value, truncatingToBitWidth: bitWidth) }
    }
}

public extension CellComponent {
    /// Creates a component for any `BitStorageConvertible`. When applied,
    /// it calls `appendTo(...)` on your type to add bits to the container.
    @inlinable @inline(__always)
    init<T>(_ value: T) where T: BitStorageConvertible {
        self.value = { try $0.encode(value) }
    }

    /// Creates a component for an optional `BitStorageConvertible`, using
    /// a presence bit. If absent, encodes `false`. If present, encodes `true`
    /// and the bits.
    ///
    /// - Note: `Maybe (X)`
    @inlinable @inline(__always)
    init<T>(ifPresent value: T?) where T: BitStorageConvertible {
        self.value = { try $0.encodeIfPresent(value) }
    }

    /// Creates a component for an optional `BitStorageConvertible & CustomOptionalBitStorageRepresentable`,
    /// which may use a custom "nil" pattern instead of a simple presence bit.
    ///
    /// - Note: `Maybe (X)`
    @inlinable @inline(__always)
    init<T>(
        ifPresent value: T?
    ) where T: BitStorageConvertible & CustomOptionalBitStorageRepresentable {
        self.value = { try $0.encodeIfPresent(value) }
    }
}

public extension CellComponent {
    /// Creates a component that appends a child cell from a `CellEncodable`.
    ///
    /// **Example**:
    /// ```swift
    /// let component = CellComponent(MyEncodableStruct())
    /// // When applied, it encodes a new child cell from MyEncodableStruct
    /// ```
    @inlinable @inline(__always)
    init<T>(_ value: T) where T: CellEncodable {
        self.value = { try $0.encode(value) }
    }

    /// Creates a component that appends the encoded bits and children of `value`
    /// directly into the container (rather than as a separate child).
    ///
    /// **Example**:
    /// ```swift
    /// let component = CellComponent(contentsOf: MyEncodableStruct())
    /// // Merges MyEncodableStruct's bits and children with the current container
    /// ```
    @inlinable @inline(__always)
    init<T>(contentsOf value: T) where T: CellEncodable {
        self.value = { try $0.encode(contentsOf: value) }
    }

    /// Creates a component encoding an optional `CellEncodable`, preceded by a
    /// presence bit (`false` if nil, `true` if non-nil). If present, it becomes
    /// a nested child cell.
    ///
    /// - Note: `Maybe (X)`
    @inlinable @inline(__always)
    init<T>(ifPresent value: T?) where T: CellEncodable {
        self.value = { try $0.encodeIfPresent(value) }
    }

    /// Creates a component that tries to merge `value`’s bits/children into
    /// the current container if there's enough space, or appends it as
    /// a child cell otherwise. Writes one bit to indicate merging or not.
    ///
    /// **Example**:
    /// ```swift
    /// let c = CellComponent(concatIfPossible: MyEncodableStruct())
    /// ```
    /// - Note: `Either X ^X`
    @inlinable @inline(__always)
    init<T>(
        concatIfPossible value: T,
        preserving space: CellContainerSpace? = nil
    ) where T: CellEncodable {
        self.value = { try $0.concatIfPossible(value, preserving: space) }
    }

    /// Similar to `concatIfPossible`, but for an optional `CellEncodable`.
    /// If `value` is `nil`, writes `false`. If non-nil, writes `true` and
    /// merges or appends as a child.
    ///
    /// - Note: `Maybe (Either X ^X)`
    @inlinable @inline(__always)
    init<T>(
        concatIfPossibleIfPresent value: T?,
        preserving space: CellContainerSpace? = nil
    ) where T: CellEncodable {
        self.value = { try $0.concatIfPossibleIfPresent(value, preserving: space) }
    }
}

public extension CellComponent {
    /// Creates a component that appends a raw `Cell` as a child of the container.
    @inlinable @inline(__always)
    init(_ value: Cell) {
        self.value = { try $0.encode(value) }
    }

    /// Creates a component that merges the contents of an existing `Cell`
    /// into the container’s bits/children directly, rather than storing
    /// it as a child.
    @inlinable @inline(__always)
    init(contentsOf value: Cell) {
        self.value = { try $0.encode(contentsOf: value) }
    }

    /// Creates a component that appends an optional `Cell`, using a presence bit.
    /// If `nil`, writes `false`; otherwise `true` and a child cell.
    ///
    /// - Note: `Maybe (X)`
    @inlinable @inline(__always)
    init(ifPresent value: Cell?) {
        self.value = { try $0.encodeIfPresent(value) }
    }

    /// Creates a component that tries to merge an existing `Cell` in place
    /// if space is available, otherwise appends it as a child. One bit
    /// is written to indicate merging or not.
    ///
    /// - Note: `Either X ^X`
    @inlinable @inline(__always)
    init(
        concatIfPossible value: Cell,
        preserving space: CellContainerSpace? = nil
    ) {
        self.value = { try $0.concatIfPossible(value, preserving: space) }
    }

    /// Similar to `concatIfPossible(value:)`, but handles an optional `Cell`.
    /// If absent, writes `false`. If present, writes `true` and merges or appends.
    ///
    /// - Note: `Maybe (Either X ^X)`
    @inlinable @inline(__always)
    init(
        concatIfPossibleIfPresent value: Cell?,
        preserving space: CellContainerSpace? = nil
    ) {
        self.value = { try $0.concatIfPossibleIfPresent(value, preserving: space) }
    }
}

// MARK: CellComponent.Value

public extension Array where Element == CellComponent {
    /// Builds a single `Cell` from an array of `CellComponent`s by creating
    /// a `CellEncodingContainer`, applying each component’s closure,
    /// then finalizing with `container.finilize()`.
    ///
    /// **Example**:
    /// ```swift
    /// let components: [CellComponent] = [
    ///     .init(true),                // bit
    ///     .init(42),                  // int
    ///     .init(MyEncodableStruct())  // nested child
    /// ]
    /// let cell = try components.build(.ordinary)
    /// print(cell)
    /// ```
    ///
    /// - Parameter kind: The `Cell.Kind` of the resulting cell (e.g., `.ordinary`).
    /// - Returns: A newly constructed `Cell` containing all encoded data.
    /// - Throws: Any encoding error if constraints are exceeded.
    @inline(__always)
    func build(_ kind: Cell.Kind) throws -> Cell {
        var container = CellEncodingContainer(kind)
        try forEach({ try $0.value(&container) })
        return try container.finilize()
    }
}
