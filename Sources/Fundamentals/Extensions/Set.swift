//
//  Created by Anton Spivak
//

// MARK: - Set + _CellCodable

extension Set: _CellCodable
    where
    Element: HashmapE.Key,
    Element: HashmapE.FixedWidthKey {}

// MARK: - Set + CellCodable

/// Extends `Set` to conform to `CellCodable` (and `_CellCodable`) when its elements
/// satisfy `HashmapE.Key & HashmapE.FixedWidthKey`.
///
/// Internally, this uses a `HashmapE` representation to store set elements
/// (where each set element becomes a key in the dictionary, mapped to an
/// `EmptyHashmapEValue` value). That dictionary is then serialized as
/// TON cells.
///
/// **Example**:
/// ```swift
/// // Suppose we have a set of UInt32 integers
/// let sample: Set<UInt32> = [10, 42]
///
/// // Encode the set into a cell
/// let cell = try Cell(sample)
///
/// // Decode back
/// let decoded = try cell.decode(Set<UInt32>.self)
/// print(decoded)  // [10, 42]
/// ```
///
/// **Reference**:
/// See [TON docs on HashmapE](https://docs.ton.org/tvm.pdf) for details on the underlying
/// dictionary encoding structure.
extension Set: CellCodable
    where
    Element: HashmapE.Key,
    Element: HashmapE.FixedWidthKey
{
    /// Initializes a `Set` from a `Cell` by decoding a `HashmapE` then reading
    /// its `[Element: EmptyHashmapEValue]`.
    ///
    /// - Parameter container: The decoding container holding bits/children.
    /// - Throws: `CellDecodingError` if the data is malformed.
    public init(from container: inout CellDecodingContainer) throws {
        let dictionary = try container
            .decode(contentsOf: HashmapE.self)
            .decode([Element: EmptyHashmapEValue].self)
        self = .init(dictionary.keys)
    }

    /// Encodes this `Set` to a `HashmapE`, by treating each element as a key
    /// mapped to an empty value (`EmptyHashmapEValue`), then storing
    /// that dictionary in the container.
    ///
    /// - Parameter container: The encoding container for bits/children.
    /// - Throws: `CellEncodingError` if constraints are exceeded.
    public func encode(to container: inout CellEncodingContainer) throws {
        let dictionary = Dictionary(uniqueKeysWithValues: map({
            ($0, EmptyHashmapEValue())
        }))

        try container.encode(contentsOf: HashmapE(dictionary))
    }

    private typealias _KeyValue = [Element: EmptyHashmapEValue]
}

// MARK: - EmptyHashmapEValue

/// A placeholder, empty value type stored in the `HashmapE` representation
/// of a `Set`. Each set element is a key mapped to this `EmptyHashmapEValue`.
private struct EmptyHashmapEValue: HashmapE.Value {
    // MARK: Lifecycle

    init() {}

    init(fromLeafContainer container: inout CellDecodingContainer) throws {}

    // MARK: Internal

    func encode(toLeafContainer container: inout CellEncodingContainer) throws {}
}
