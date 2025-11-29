//
//  Created by Anton Spivak
//

import Foundation

// MARK: - Cell

/// Represents a fundamental building block (or "cell") within TON's data layout,
/// holding bits in its `storage` and zero or more child `Cell`s. A `Cell` can also
/// be “exotic” (like `.merkleProof`), but `.ordinary` is most common.
///
/// **Example**:
/// ```swift
/// // Creating a simple empty cell
/// let emptyCell = Cell()
/// print(emptyCell.storage.count)   // 0 bits
/// print(emptyCell.children.count)  // 0 children
/// ```
///
/// **Reference**:
/// See [TON docs](https://docs.ton.org/ton.pdf) for more on cell architecture and usage.
public struct Cell {
    // MARK: Lifecycle

    /// Creates an empty `.ordinary` Cell with no bits and no children.
    /// Often used as a placeholder or for testing small logic.
    ///
    /// **Example**:
    /// ```swift
    /// let empty = Cell()
    /// // empty.storage.count == 0
    /// // empty.children.isEmpty == true
    /// ```
    @inlinable @inline(__always)
    public init() {
        try! self.init(.ordinary, storage: [], children: [])
    }

    /// Builds a `Cell` of a given `kind`, directly specifying its bit `storage`
    /// and an array of child cells. The initializer enforces the cell constraints
    /// (e.g., max bits, max children).
    ///
    /// - Parameters:
    ///   - kind: The `Cell.Kind` (e.g. `.ordinary` or `.merkleProof`).
    ///   - storage: The raw bit contents (`BitStorage`) for this cell.
    ///   - children: The immediate subcells (child `Cell`s).
    /// - Throws: `Cell.ConstraintError` if the cell constraints are violated.
    ///
    /// **Example**:
    /// ```swift
    /// // Suppose we have some bitStorage and childCell:
    /// let c = try Cell(.ordinary, storage: bitStorage, children: [childCell])
    /// print(c.kind)      // .ordinary
    /// print(c.storage)   // the bitStorage provided
    /// print(c.children)  // [childCell]
    /// ```
    public init(
        _ kind: Kind = .ordinary,
        storage: BitStorage,
        children: [Cell]
    ) throws (Cell.ConstraintError) {
        try self.init(underlyingCell: UnderlyingCell(kind, storage: storage, children: children))
    }

    @inline(__always)
    init(underlyingCell: UnderlyingCell) {
        self.underlyingCell = underlyingCell
    }

    // MARK: Public

    /// The `Cell.Kind` classification of this cell, indicating exotic or ordinary type.
    @inlinable @inline(__always)
    public var kind: Kind { underlyingCell.kind }

    /// The highest "level" among this cell and its ancestors, used in advanced
    /// Merkle-based proofs. For standard usage, typically `0`.
    @inlinable @inline(__always)
    public var level: UInt32 { underlyingCell.levels.highestLevel }

    /// The raw bits stored in this cell.
    @inlinable @inline(__always)
    public var storage: BitStorage { underlyingCell.storage }

    /// The immediate child `Cell`s contained within this cell.
    @inlinable @inline(__always)
    public var children: [Cell] { underlyingCell.children }

    // MARK: Internal

    /// The underlying representation that holds the cell data, including
    /// its bits and precomputed hash information.
    @usableFromInline
    var underlyingCell: UnderlyingCell
}

public extension Cell {
    /// Initializes a `Cell` by encoding any type conforming to `CellEncodable`.
    /// Calls into a `CellEncoder` internally.
    ///
    /// - Parameter value: A `CellEncodable` instance to be serialized.
    /// - Throws: `CellEncodingError` if the `value` exceeds bit or child constraints.
    ///
    /// **Example**:
    /// ```swift
    /// struct MyData: CellEncodable { ... }
    /// let cell = try Cell(MyData(...)) // automatically encodes MyData
    /// ```
    @inlinable @inline(__always)
    init<T>(_ value: T) throws where T: CellEncodable {
        self = try CellEncoder().encode(value)
    }

    /// Attempts to decode this cell into a type conforming to `CellDecodable`,
    /// calling `CellDecoder` internally. The type’s `kind` is validated (if applicable).
    ///
    /// - Parameter type: The `CellDecodable` type to decode to.
    /// - Returns: A newly constructed instance of `type`, if decoding succeeds.
    /// - Throws: `CellDecodingError` or other errors if the data is malformed.
    ///
    /// **Example**:
    /// ```swift
    /// struct MyData: CellDecodable { ... }
    /// let myData = try cell.decode(MyData.self)
    /// ```
    @inlinable @inline(__always)
    func decode<T>(_ type: T.Type) throws -> T where T: CellDecodable {
        try CellDecoder().decode(type, from: self)
    }
}

public extension Cell {
    /// Retrieves the 0-level (base) hash (32-byte representation) for this cell,
    /// often used for representation checks or DAG-based equality. This is
    /// distinct from any Merkle proof, which might use higher-level indices.
    ///
    /// **Example**:
    /// ```swift
    /// let hash = cell.representationHash
    /// print(hash.hexadecimalString) // 32-byte cryptographic hash
    /// ```
    @inlinable @inline(__always)
    var representationHash: Data { underlyingCell.data.hash(at: 0) }
}

// MARK: Sendable

extension Cell: Sendable {}

// MARK: Equatable

extension Cell: Equatable {
    /// Equality is determined by comparing the 0-level (base) hash.
    /// If two cells have the same base hash, they are considered equal.
    ///
    /// - Note: This does not guarantee identical child structure in
    ///   certain exotic cases, but is typically sufficient for DAG comparisons.
    @inlinable @inline(__always)
    public static func == (lhs: Cell, rhs: Cell) -> Bool {
        lhs.representationHash == rhs.representationHash
    }
}

// MARK: Hashable

extension Cell: Hashable {
    /// Combines the 0-level hash into a `Hasher`.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(representationHash)
    }
}

// MARK: CustomStringConvertible

extension Cell: CustomStringConvertible {
    /// A textual representation of the cell, showing bit size, contents
    /// in a Fift-like hexadecimal nibble dump, and recursively describing
    /// child cells with indentation.
    ///
    /// **Example**:
    /// ```swift
    /// let c = try Cell(.ordinary, storage: BitStorage("1101"), children: [])
    /// print(c)
    /// // Example output: "4[1101]"
    /// ```
    @inlinable @inline(__always)
    public var description: String { description(0) }

    @usableFromInline
    func description(_ indentation: Int) -> String {
        let indent = String(repeating: " ", count: indentation)
        let size = "\(storage.count)"

        var description = "\(indent)"
        description.append("\(size)[\(storage.nibbleFiftHexadecimalString())]")

        if !children.isEmpty {
            description.append(" -> {\n")
            let children = children
                .map({ $0.description(indentation + size.count + 1) })
                .joined(separator: ",\n")
            description.append("\(children)\n\(indent)}")
        }

        return description
    }
}

// MARK: CustomDebugStringConvertible

extension Cell: CustomDebugStringConvertible {
    @inlinable @inline(__always)
    public var debugDescription: String { description }
}

public extension String.StringInterpolation {
    /// Inserts a multiline textual description of a single `Cell`.
    ///
    /// **Example**:
    /// ```swift
    /// print("Details: \(describing: cell)")
    /// ```
    mutating func appendInterpolation(describing value: Cell) {
        appendLiteral("\n\(value.description)")
    }

    /// Inserts multiline descriptions for each `Cell` in a collection, labeling
    /// how many cells are printed, followed by each cell's `description`.
    ///
    /// **Example**:
    /// ```swift
    /// let cells = [cell1, cell2]
    /// print("\(describing: cells)")
    /// ```
    mutating func appendInterpolation<T>(
        describing value: T
    ) where T: Collection, T.Element == Cell {
        appendLiteral("\n\(value._described())")
    }
}

extension Collection where Element == Cell {
    func _described(_ indentation: Int = 0) -> String {
        map({ $0.description(indentation) }).joined(separator: ",\n")
    }
}
