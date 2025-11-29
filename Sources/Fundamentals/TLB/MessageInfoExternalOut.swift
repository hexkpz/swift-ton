//
//  Created by Anton Spivak
//

// MARK: - MessageInfoExternalOut

public struct MessageInfoExternalOut {
    // MARK: Lifecycle

    public init(
        source: InternalAddress,
        destination: ExternalAddress,
        createdLt: UInt64,
        createdAt: UInt32
    ) {
        self.source = source
        self.destination = destination
        self.createdLt = createdLt
        self.createdAt = createdAt
    }

    // MARK: Public

    public let source: InternalAddress
    public let destination: ExternalAddress

    public let createdLt: UInt64
    public let createdAt: UInt32
}

// MARK: CellCodable

///
/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L139
/// ```
/// ext_out_msg_info$11
///  src:MsgAddressInt
///  dest:MsgAddressExt
///  created_lt:uint64
///  created_at:uint32
///  = CommonMsgInfo;
/// ```
///
/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L132
/// ```
/// ext_out_msg_info$11
///  src:MsgAddressInt
///  dest:MsgAddressExt
///  created_lt:uint64
///  created_at:uint32
///  = CommonMsgInfoRelaxed;
/// ```
extension MessageInfoExternalOut: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        guard try container.decode(Bool.self), try container.decode(Bool.self)
        else {
            throw TLBCodingError.invalidEnumerationFlagValue(for: Self.self)
        }

        self.source = try container.decode(InternalAddress.self)
        self.destination = try container.decode(ExternalAddress.self)
        self.createdLt = try container.decode(UInt64.self)
        self.createdAt = try container.decode(UInt32.self)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(true)
        try container.encode(true)

        try container.encode(source)
        try container.encode(destination)
        try container.encode(createdLt)
        try container.encode(createdAt)
    }
}

// MARK: Hashable

extension MessageInfoExternalOut: Hashable {}

// MARK: Sendable

extension MessageInfoExternalOut: Sendable {}
