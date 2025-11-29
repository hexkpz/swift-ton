//
//  Created by Anton Spivak
//

// MARK: - Dictionary + _CellCodable

extension Dictionary: _CellCodable
    where
    Key: HashmapE.Key,
    Key: HashmapE.FixedWidthKey,
    Value: HashmapE.Value {}

// MARK: - Dictionary + CellCodable

/// Extends `Dictionary` to conform to `CellCodable` (and `_CellCodable`) when its keys
/// satisfy `HashmapE.Key & HashmapE.FixedWidthKey` and values satisfy `HashmapE.Value`.
///
/// This allows dictionaries to be stored as a TON `HashmapE`, where each key/value
/// is encoded as part of the cell-based trie structure.
///
/// **Example**:
/// ```swift
/// let dict: [UInt32: VUInt5] = [10: VUInt5(...), 42: VUInt5(...)]
///
/// // Encode into a cell
/// let cell = try Cell(dict)
///
/// // Decode back
/// let decoded = try cell.decode([UInt32: VUInt5].self)
/// print(decoded)  // same as 'dict'
/// ```
///
/// **Reference**:
/// See [TON docs on HashmapE](https://docs.ton.org/tvm.pdf) for advanced dictionary usage.
extension Dictionary: CellCodable
    where
    Key: HashmapE.Key,
    Key: HashmapE.FixedWidthKey,
    Value: HashmapE.Value
{
    /// Decodes a dictionary by reading a `HashmapE` from the container,
    /// then further decoding that into `[Key: Value]`.
    ///
    /// - Parameter container: A `CellDecodingContainer` to read from.
    /// - Throws: `CellDecodingError` if there's an issue parsing the bits or children.
    public init(from container: inout CellDecodingContainer) throws {
        self = try container.decode(contentsOf: HashmapE.self).decode(Self.self)
    }

    /// Encodes this dictionary into a `HashmapE`, storing each key/value pair
    /// in the underlying trie structure, then adds it to the container.
    ///
    /// - Parameter container: A `CellEncodingContainer` for writing bits/children.
    /// - Throws: `CellEncodingError` if constraints (bits or children) are exceeded.
    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(contentsOf: HashmapE(self))
    }
}
