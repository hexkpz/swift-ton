//
//  Created by Anton Spivak
//

// MARK: - HashmapE.Label

extension HashmapE {
    /// A label containing a prefix bit sequence (`prefixBitStorage`) and
    /// the maximum prefix bits allowed (`maximumPrefixBitWidth`). This label
    /// is encoded in short/long/same mode, depending on its length and uniformity.
    struct Label {
        // MARK: Lifecycle

        init(_ prefixBitStorage: BitStorage.SubSequence, maximumPrefixBitWidth: Int) {
            self.init(BitStorage(prefixBitStorage), maximumPrefixBitWidth: maximumPrefixBitWidth)
        }

        init(_ prefixBitStorage: BitStorage, maximumPrefixBitWidth: Int) {
            self.prefixBitStorage = prefixBitStorage
            self.maximumPrefixBitWidth = maximumPrefixBitWidth
        }

        // MARK: Internal

        let prefixBitStorage: BitStorage
        let maximumPrefixBitWidth: Int
    }
}

// MARK: - HashmapE.Label + BitStorageRepresentable

extension HashmapE.Label {
    /// Creates a label by decoding short/long/same modes from the container.
    ///
    /// - short `'0'`: unary(length) + `prefixValue`
    /// - long `'10'`: read length (k bits), then read that many prefix bits
    /// - same `'11'`: read a single bit (0/1), then length (k bits), repeating that bit
    ///
    /// For simplicity, `keyLength` is set to the prefix length, but more advanced
    /// logic might keep track of the full dictionary's bit width.
    init(from container: inout CellDecodingContainer, maximumPrefixBitWidth: Int) throws {
        let k = Int.bitWidth - maximumPrefixBitWidth.leadingZeroBitCount
        if try !container.decode(Bool.self) {
            // short mode '0'
            var n = 0 // read unary(n): sequence of 'true' bits, terminated by a 'false'
            while try container.decode(Bool.self) { n += 1 }

            prefixBitStorage = try container.decode(bitWidth: n)
        } else if try !container.decode(Bool.self) {
            // long mode '10'
            let n = try container.decode(Int.self, truncatingToBitWidth: k)
            prefixBitStorage = try container.decode(bitWidth: n)
        } else {
            // same mode '11'
            let value = try container.decode(Bool.self) // 0 or 1
            let n = try container.decode(Int.self, truncatingToBitWidth: k)
            prefixBitStorage = BitStorage(repeating: value, count: n)
        }
        self.maximumPrefixBitWidth = maximumPrefixBitWidth
    }

    /// Encodes a label into a bit stream, choosing the shortest possible mode
    /// (short, long, or same) following the TON rules:
    ///
    /// - short mode `'0'` => `2n + 2` bits (if `n` is small or `k >= n`)
    /// - long mode `'10'` => `2 + k + n` bits (if `k < n`)
    /// - same mode `'11'` => `3 + k` bits (if all bits in prefixValue are the same, `n >= 2`, and `k < 2n - 1`)
    func encode(to container: inout CellEncodingContainer) throws {
        let n = prefixBitStorage.count
        let k = Int.bitWidth - maximumPrefixBitWidth.leadingZeroBitCount

        if let bit = prefixBitStorage.sameBit, n > 1 && k < 2 * n - 1 {
            // same mode '11'
            try container.encode(true)
            try container.encode(true)

            try container.encode(bit)
            try container.encode(BitStorage(bitPattern: n, truncatingToBitWidth: k))
        } else if k < n {
            // long mode '10'
            try container.encode(true)
            try container.encode(false)

            try container.encode(BitStorage(bitPattern: n, truncatingToBitWidth: k))
            try container.encode(prefixBitStorage)
        } else {
            // short mode '0'
            try container.encode(false)

            // unary
            for _ in 0 ..< n { try container.encode(true) }
            try container.encode(false)

            try container.encode(prefixBitStorage)
        }
    }
}

private extension BitStorage {
    /// Returns `true` if the entire storage is set to 1 bits,
    /// `false` if the entire storage is 0 bits,
    /// or `nil` if there's a mix of 0 and 1.
    @inline(__always)
    var sameBit: Bool? {
        guard let first = first
        else {
            return nil
        }

        for i in 0 ..< count where self[i] != first { return nil }
        return first
    }
}
