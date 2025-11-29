//
//  Created by Anton Spivak
//

// MARK: - MessageInfoInternal

public struct MessageInfoInternal {
    // MARK: Lifecycle

    public init(
        isInstantHypercubeRoutingDisabled: Bool,
        bounce: Bool,
        isBounced: Bool,
        source: InternalAddress?,
        destination: InternalAddress,
        value: CurrencyCollection,
        instantHypercubeRoutingFee: CurrencyValue,
        forwardFee: CurrencyValue,
        createdLt: UInt64,
        createdAt: UInt32
    ) {
        self.isInstantHypercubeRoutingDisabled = isInstantHypercubeRoutingDisabled

        self.bounce = bounce
        self.isBounced = isBounced

        self.source = source
        self.destination = destination
        self.value = value

        self.instantHypercubeRoutingFee = instantHypercubeRoutingFee
        self.forwardFee = forwardFee

        self.createdLt = createdLt
        self.createdAt = createdAt
    }

    // MARK: Public

    public let isInstantHypercubeRoutingDisabled: Bool

    public let bounce: Bool
    public let isBounced: Bool

    public let source: InternalAddress?
    public let destination: InternalAddress

    public let value: CurrencyCollection

    public let instantHypercubeRoutingFee: CurrencyValue
    public let forwardFee: CurrencyValue

    public let createdLt: UInt64
    public let createdAt: UInt32
}

// MARK: CellCodable

///
/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L126
/// ```
/// int_msg_info$0
///  ihr_disabled:Bool
///  bounce:Bool
///  bounced:Bool
///  src:MsgAddressInt
///  dest:MsgAddressInt
///  value:CurrencyCollection
///  ihr_fee:Grams
///  fwd_fee:Grams
///  created_lt:uint64
///  created_at:uint32
///  = CommonMsgInfo
/// ```
///
/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L135
/// ```
/// int_msg_info$0
///  ihr_disabled:Bool
///  bounce:Bool
///  bounced:Bool
///  src:MsgAddressInt
///  dest:MsgAddressInt
///  value:CurrencyCollection
///  ihr_fee:Grams
///  fwd_fee:Grams
///  created_lt:uint64
///  created_at:uint32
///  = CommonMsgInfoRelaxed
/// ```
extension MessageInfoInternal: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        guard try !container.decode(Bool.self)
        else {
            throw TLBCodingError.invalidEnumerationFlagValue(for: Self.self)
        }

        self.isInstantHypercubeRoutingDisabled = try container.decode(Bool.self)

        self.bounce = try container.decode(Bool.self)
        self.isBounced = try container.decode(Bool.self)

        self.source = try container.decodeIfPresent(InternalAddress.self)
        self.destination = try container.decode(InternalAddress.self)

        self.value = try .init(from: &container)

        self.instantHypercubeRoutingFee = try container.decode(CurrencyValue.self)
        self.forwardFee = try container.decode(CurrencyValue.self)

        self.createdLt = try container.decode(UInt64.self)
        self.createdAt = try container.decode(UInt32.self)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(false)

        try container.encode(isInstantHypercubeRoutingDisabled)

        try container.encode(bounce)
        try container.encode(isBounced)

        try container.encodeIfPresent(source)
        try container.encode(destination)

        try value.encode(to: &container)

        try container.encode(instantHypercubeRoutingFee)
        try container.encode(forwardFee)

        try container.encode(createdLt)
        try container.encode(createdAt)
    }
}

// MARK: Hashable

extension MessageInfoInternal: Hashable {}

// MARK: Sendable

extension MessageInfoInternal: Sendable {}
