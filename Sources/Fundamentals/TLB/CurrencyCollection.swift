//
//  Created by Anton Spivak
//

// MARK: - CurrencyCollection

public struct CurrencyCollection {
    // MARK: Lifecycle

    public init(coins: CurrencyValue, others: [UInt32: VUInt5] = [:]) {
        self.coins = coins
        self.others = others
    }

    // MARK: Public

    public let coins: CurrencyValue

    ///
    /// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L121
    /// ```
    /// extra_currencies$_
    ///  dict:(HashmapE 32 (VarUInteger 32))
    ///  = ExtraCurrencyCollection;
    /// ```
    public let others: [UInt32: VUInt5]
}

// MARK: Hashable

extension CurrencyCollection: Hashable {}

// MARK: Sendable

extension CurrencyCollection: Sendable {}

// MARK: CellCodable

///
/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L123
/// ```
/// currencies$_
///  grams:Grams
///  other:ExtraCurrencyCollection
///  = CurrencyCollection;
/// ```
extension CurrencyCollection: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        self.coins = try container.decode(CurrencyValue.self)
        self.others = try container.decode(contentsOf: [UInt32: VUInt5].self)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(coins)
        try container.encode(contentsOf: others)
    }
}
