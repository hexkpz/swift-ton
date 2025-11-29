//
//  Created by Anton Spivak
//

// MARK: - HashmapE

/// A TON-style hashmap (hashmap-e) structure that can be either empty
/// or contain a serialized trie of `(key -> value)` mappings.
/// Each key must have a fixed bit width, and each value must conform
/// to `HashmapE.Value`.
///
/// This type is typically used to store dictionary-like data in a single
/// TON cell (or cell tree). The resulting cell can then be encoded or
/// decoded via `CellCodable`.
///
/// **Example usage** (public APIs only):
///
/// ```swift
/// // 1) Create a HashmapE from a Swift dictionary
/// let swiftDict: [Int32: UInt] = [42: 255, 10: 128]
/// // Initialize using the public init(_: keyBitWidth:)
/// let myMap = try HashmapE(swiftDict, keyBitWidth: 32)
///
/// // 2) Convert the HashmapE back into a Swift dictionary
/// //    using the public decode(keyBitWidth:) method
/// let decoded: [Int32: UInt] = try myMap.decode(keyBitWidth: 32)
/// // 'decoded' should match 'swiftDict'
/// ```
public struct HashmapE {
    // MARK: Lifecycle

    /// Internal initializer that constructs `HashmapE` from an array of `(Key, Value)` pairs,
    /// enforcing the same `keyBitWidth` for every key. If `data` is empty, the hashmap is empty.
    ///
    /// This method:
    /// 1. Verifies that all keys share the same bit width (`keyBitWidth`).
    /// 2. Converts each `(K, V)` into `[BitStorage: V]`.
    /// 3. Encodes the tree structure (`Edge`) into `contents` if non-empty.
    ///
    /// - Parameters:
    ///   - data: The array of key-value pairs to store.
    ///   - keyBitWidth: The required bit width for each key.
    /// - Throws: `TLBCodingError.hashmapEKeysMustBeSameSize` if any key does not
    ///   match `keyBitWidth`.
    @usableFromInline
    init<K, V>(data: [(K, V)], keyBitWidth: Int) throws where K: Key, V: Value {
        guard !data.isEmpty
        else {
            self.contents = nil
            return
        }

        var encodableData: [BitStorage: V] = [:]
        try data.forEach({ key, value in
            let key = key.keyRepresentation
            guard keyBitWidth == key.count
            else {
                throw TLBCodingError.hashmapEKeysMustBeSameSize()
            }
            encodableData[key] = value
        })

        var container = CellEncodingContainer(.ordinary)
        try Edge<V>(encodableData, keyBitWidth).encode(to: &container)

        self.contents = try container.finilize()
    }

    // MARK: Internal

    /// Decodes this `HashmapE` into a dictionary of type `[K: V]`, using
    /// the provided `keyBitWidth` to parse each key.
    ///
    /// If the `HashmapE` is empty (`contents == nil`), returns an empty dictionary.
    ///
    /// - Parameter keyBitWidth: The expected fixed bit width of every key.
    /// - Returns: A Swift dictionary with keys `K` and values `V`.
    /// - Throws: Any error during cell decoding or key/value parsing.
    @usableFromInline
    func _decode<K, V>(keyBitWidth: Int) throws -> [K: V] where K: Key, V: Value {
        guard let contents
        else {
            return [:]
        }

        var container = CellDecodingContainer(contents)
        var result: [K: V] = [:]

        try _decode(from: &container, keyBitWidth: keyBitWidth, to: &result)
        return result
    }

    // MARK: Private

    /// The serialized cell holding the dictionary data, or `nil` if empty.
    private let contents: Cell?
}

// MARK: Hashable

extension HashmapE: Hashable {}

// MARK: Sendable

extension HashmapE: Sendable {}

private extension HashmapE {
    /// Recursively decodes hashmap-e data from the given container into
    /// a dictionary `[K: V]`. This is an internal helper that:
    ///
    /// 1. Reads a `Label` indicating the common prefix.
    /// 2. If the prefix covers the entire `keyBitWidth`, treats the next
    ///    data as a `leaf`. Otherwise, branches into two child edges (left
    ///    and right).
    ///
    /// - Parameters:
    ///   - container: The decoding container representing a cell or subtree.
    ///   - assumedPrefixValue: The prefix bits accumulated so far.
    ///   - keyBitWidth: The total number of bits each key must have.
    ///   - maximumPrefixBitWidth: An optional cap on how many bits we still
    ///     can append to the prefix in this subtree.
    ///   - result: The dictionary into which decoded values are inserted.
    func _decode<K, V>(
        from container: inout CellDecodingContainer,
        assumedPrefixValue: BitStorage = [],
        keyBitWidth: Int,
        maximumPrefixBitWidth: Int? = nil,
        to result: inout [K: V]
    ) throws where K: Key, V: Value {
        let label = try Label(
            from: &container,
            maximumPrefixBitWidth: maximumPrefixBitWidth ?? keyBitWidth
        )

        let prefix = assumedPrefixValue.appending(contentsOf: label.prefixBitStorage)
        if keyBitWidth - prefix.count == 0 {
            let key = try K(keyRepresentation: prefix)
            result[key] = try V(fromLeafContainer: &container)
        } else {
            var left = try CellDecodingContainer(container.decode(Cell.self))
            try _decode(
                from: &left,
                assumedPrefixValue: prefix.appending(false),
                keyBitWidth: keyBitWidth,
                maximumPrefixBitWidth: keyBitWidth - label.prefixBitStorage.count - 1,
                to: &result
            )

            var right = try CellDecodingContainer(container.decode(Cell.self))
            try _decode(
                from: &right,
                assumedPrefixValue: prefix.appending(true),
                keyBitWidth: keyBitWidth,
                maximumPrefixBitWidth: keyBitWidth - label.prefixBitStorage.count - 1,
                to: &result
            )
        }
    }
}

// MARK: CellCodable

extension HashmapE: CellCodable {
    /// Initializes a `HashmapE` from a `CellDecodingContainer`. Reads a presence bit
    /// to decide if the hashmap is empty (`false`) or non-empty (`true`). In the
    /// latter case, decodes the cell into `contents`.
    ///
    /// - Parameter container: The container from which to decode this hashmap.
    /// - Throws: Any cell decoding error if the data is malformed.
    public init(from container: inout CellDecodingContainer) throws {
        guard try container.decode(Bool.self)
        else {
            self.contents = nil
            return
        }
        self.contents = try container.decode(Cell.self)
    }

    // MARK: Public

    /// Encodes this `HashmapE` into the given container. If `contents` is `nil`,
    /// writes a single `false` bit. Otherwise writes `true` plus the stored cell.
    ///
    /// - Parameter container: The container into which this hashmap is encoded.
    /// - Throws: Any error from writing bits or child cells.
    public func encode(to container: inout CellEncodingContainer) throws {
        guard let contents
        else {
            try container.encode(false)
            return
        }
        try container.encode(true)
        try container.encode(contents)
    }
}

public extension HashmapE {
    /// Creates a `HashmapE` from a Swift dictionary `[K: V]` where
    /// `K` also conforms to `FixedWidthKey`.
    /// `K.keyBitWidth` determines how many bits each key must have.
    ///
    /// **Example**:
    /// ```swift
    /// let dict: [Int32: UInt] = [10: 99, 42: 1000]
    /// let map = try HashmapE(dict)
    /// // 'map' now stores a TON-style tree of those dictionary
    /// ```
    ///
    /// - Parameter value: The dictionary of `(K, V)`.
    /// - Throws: If any key’s bit length is inconsistent, or on encoding error.
    @inlinable @inline(__always)
    init<K, V>(_ value: [K: V]) throws where K: Key, K: FixedWidthKey, V: Value {
        try self.init(data: value.map({ $0 }), keyBitWidth: K.keyBitWidth)
    }

    /// Decodes this `HashmapE` into a `[K: V]` dictionary, where `K` is
    /// a `FixedWidthKey`. Uses `K.keyBitWidth` as the key size.
    ///
    /// **Example**:
    /// ```swift
    /// let map: HashmapE = ...
    /// let decoded = try map.decode([Int32: UInt].self)
    /// // 'decoded' is the original Swift dictionary
    /// ```
    ///
    /// - Returns: The resulting `[K: V]`.
    /// - Throws: If decoding fails, e.g., if bits are malformed or do not match.
    @inlinable @inline(__always)
    func decode<K, V>(
        _ type: [K: V].Type
    ) throws -> [K: V] where K: Key, K: FixedWidthKey, V: Value {
        try _decode(keyBitWidth: K.keyBitWidth)
    }
}

public extension HashmapE {
    /// Creates a `HashmapE` from a dictionary `[K: V]` with a specified
    /// `keyBitWidth` (for types that are not `FixedWidthKey`).
    ///
    /// **Example**:
    /// ```swift
    /// let dict: [BigInt: UInt16] = [BigInt(12345): 55, BigInt(999): 44]
    /// let map = try HashmapE(dict, keyBitWidth: 256)
    /// // 'map' now encodes those big-int keys to 256 bits
    /// ```
    ///
    /// - Parameters:
    ///   - value: The dictionary of `(K, V)`.
    ///   - keyBitWidth: The expected bit size for each key.
    /// - Throws: If any key fails to match `keyBitWidth`.
    @inlinable @inline(__always)
    init<K, V>(_ value: [K: V], keyBitWidth: Int) throws where K: Key, V: Value {
        try self.init(data: value.map({ $0 }), keyBitWidth: keyBitWidth)
    }

    /// Decodes this `HashmapE` into `[K: V]`, enforcing a `keyBitWidth`
    /// for keys that are not necessarily `FixedWidthKey`.
    ///
    /// **Example**:
    /// ```swift
    /// let map: HashmapE = ...
    /// let keys = try map.decode([BigInt: UInt16].self, keyBitWidth: 256)
    /// // 'keys' might have huge integer keys, each stored in 256 bits
    /// ```
    ///
    /// - Parameter keyBitWidth: The bit size for keys in the stored data.
    /// - Returns: A newly decoded dictionary of `[K: V]`.
    /// - Throws: If decoding fails or data is malformed.
    @inlinable @inline(__always)
    func decode<K, V>(
        _ type: [K: V].Type,
        keyBitWidth: Int
    ) throws -> [K: V] where K: Key, V: Value {
        try _decode(keyBitWidth: keyBitWidth)
    }
}
