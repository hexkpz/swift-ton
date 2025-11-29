//
//  Created by Anton Spivak
//

///  A custom operator `~<` for lexicographical comparison of same-length BitStorage.
///  Interprets `false < true`, returning `true` if `lhs` is lexicographically  `<=` `rhs`.
infix operator ~<: ComparisonPrecedence

// MARK: - HashmapE.Edge

extension HashmapE {
    /// An `Edge` represents a top-level piece of the trie, including:
    /// - A `label` describing the common prefix.
    /// - A `node` specifying either a leaf or a fork.
    struct Edge<V> where V: Value {
        // MARK: Lifecycle

        /// Builds a new `Edge` from a dictionary `[BitStorage: V]`. It finds
        /// the shared prefix among keys, creates a `Label` for that prefix,
        /// and constructs a `Node` for any further branching.
        ///
        /// - Parameters:
        ///   - value: The map of `(BitStorage -> V)` entries.
        ///   - maximumPrefixBitWidth: The maximum prefix bits that may remain.
        init(_ value: [BitStorage: V], _ maximumPrefixBitWidth: Int) throws {
            precondition(!value.isEmpty, "Couldn't build an edge from a empty map.")
            let prefix = BitStorage(value.keys.prefix())
            self.label = .init(prefix, maximumPrefixBitWidth: maximumPrefixBitWidth)
            self.node = try .init(prefix, value, maximumPrefixBitWidth - prefix.count)
        }

        // MARK: Internal

        let label: Label
        let node: Node<V>
    }
}

// MARK: - HashmapE.Node

extension HashmapE {
    indirect enum Node<V> where V: Value {
        /// A branching node with two edges: left and right.
        case fork(Edge<V>, Edge<V>)

        /// A terminal node storing a single value `V`.
        case leaf(V)

        // MARK: Lifecycle

        /// Constructs a node by checking how many entries are in the map:
        /// - If exactly one, produce a `leaf` directly.
        /// - Otherwise, partition keys by the bit right after `prefix`.
        ///
        /// - Parameters:
        ///   - prefix: The current shared prefix in bits.
        ///   - value: The map `[BitStorage: V]`.
        ///   - maximumPrefixLength: The number of bits still allowed after prefix.
        init(
            _ prefix: BitStorage,
            _ value: [BitStorage: V],
            _ maximumPrefixLength: Int
        ) throws {
            precondition(!value.isEmpty, "Couldn't build a node from a empty map.")
            if let first = value.first, value.count == 1 {
                self = .leaf(first.value)
            } else {
                /// Do fork
                /// Splits the dictionary by the value of the first bit of the keys. 0-prefixed keys go into left map, 1-prefixed keys go into the right one.
                /// First bit is removed from the keys.
                ///
                /// Because keys couldn't be same we will always have left and right
                /// For same key we will have only one value, so
                /// So here we can be sure that initial precondition not fire up
                ///
                /// Subkey also will be always +1 length to prefix,
                /// bacause prefix could not be same for all elements
                /// (we could be here only if values have at least two different key/value pairs)

                var left = [BitStorage: V]()
                var right = [BitStorage: V]()

                for (key, value) in value {
                    precondition(
                        !key.isEmpty && key.count > prefix.count,
                        "Couldn't fork a node from a map with malformed keys"
                    )

                    let trimmedKey = BitStorage(key[prefix.count + 1 ..< key.count])
                    if key[prefix.count] {
                        // Right with first true bit
                        right[trimmedKey] = value
                    } else {
                        // Left with first false bit
                        left[trimmedKey] = value
                    }
                }

                self = try .fork(
                    .init(left, maximumPrefixLength - 1),
                    .init(right, maximumPrefixLength - 1)
                )
            }
        }
    }
}

// MARK: - HashmapE.Edge + CellEncodable

extension HashmapE.Edge: CellEncodable {
    init(from container: inout CellDecodingContainer, keyBitWidth: Int) throws {
        fatalError("HashmapE.Edge decoding from container is not implemented.")
    }

    /// Encodes this edge by encoding its `label` first, then either:
    /// - For a fork: encode `left` and `right`.
    /// - For a leaf: encode the value in a “leaf container”.
    ///
    /// - Parameter container: The encoding container to write into.
    /// - Throws: Any error from writing bits or child cells.
    func encode(to container: inout CellEncodingContainer) throws {
        try label.encode(to: &container)
        switch node {
        case let .fork(left, right):
            try container.encode(left)
            try container.encode(right)
        case let .leaf(value):
            try value.encode(toLeafContainer: &container)
        }
    }
}

private extension Collection where Element == BitStorage {
    /// Returns the common prefix among all bit strings in this collection
    /// by comparing the lexicographically smallest and largest items.
    ///
    /// - Returns: A `BitStorage.SubSequence` representing the largest shared
    ///   initial segment of bits, or empty if there's none.
    @inline(__always)
    func prefix() -> BitStorage.SubSequence {
        precondition(!isEmpty, "Couldn't find a prefix from an empty map")

        let sorted = self.sorted(by: ~<)
        guard sorted.count > 1
        else {
            return sorted[0][0 ..< sorted[0].count]
        }

        let first = sorted[0]
        let last = sorted[sorted.count - 1]

        var i = 0
        while i < first.count, first[i] == last[i] {
            i += 1
        }

        return first[0 ..< i]
    }
}

private extension BitStorage {
    ///  A custom operator `~<` for lexicographical comparison of same-length BitStorage.
    ///  Interprets `false < true`, returning `true` if `lhs` is lexicographically  `<=` `rhs`.
    @inline(__always)
    static func ~< (_ lhs: Self, rhs: Self) -> Bool {
        precondition(!lhs.isEmpty, "Couldn't compare empty BitStorage")
        precondition(!rhs.isEmpty, "Couldn't compare empty BitStorage")
        precondition(lhs.count == rhs.count, "Couldn't compare two different sized BitStorage")
        for i in 0 ..< lhs.count {
            let lhs = lhs[i]
            let rhs = rhs[i]
            if !lhs && rhs {
                return true
            }
            if lhs && !rhs {
                return false
            }
        }
        return true
    }
}
