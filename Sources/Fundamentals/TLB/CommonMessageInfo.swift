//
//  Created by Anton Spivak
//

// MARK: - CommonMessageInfo

public enum CommonMessageInfo {
    case `internal`(MessageInfoInternal)
    case externalIn(MessageInfoExternalIn)
    case externalOut(MessageInfoExternalOut)
}

// MARK: Hashable

extension CommonMessageInfo: Hashable {}

// MARK: Sendable

extension CommonMessageInfo: Sendable {}

// MARK: CellCodable

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
///
/// ext_in_msg_info$10
///  src:MsgAddressExt
///  dest:MsgAddressInt
///  import_fee:Grams
///  = CommonMsgInfo;
///
/// ext_out_msg_info$11
///  src:MsgAddressInt
///  dest:MsgAddressExt
///  created_lt:uint64
///  created_at:uint32
///  = CommonMsgInfo;
/// ```
extension CommonMessageInfo: CellCodable {
    // MARK: Lifecycle

    public init(from container: inout CellDecodingContainer) throws {
        if let value = try? MessageInfoInternal(from: &container) {
            self = .internal(value)
        } else if let value = try? MessageInfoExternalIn(from: &container) {
            self = .externalIn(value)
        } else {
            self = try .externalOut(.init(from: &container))
        }
    }

    // MARK: Public

    public func encode(to container: inout CellEncodingContainer) throws {
        switch self {
        case let .internal(`internal`):
            try `internal`.encode(to: &container)
        case let .externalIn(externalIn):
            try externalIn.encode(to: &container)
        case let .externalOut(externalOut):
            try externalOut.encode(to: &container)
        }
    }
}
