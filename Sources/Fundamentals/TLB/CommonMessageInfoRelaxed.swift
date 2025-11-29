//
//  Created by Anton Spivak
//

// MARK: - CommonMessageInfoRelaxed

public enum CommonMessageInfoRelaxed {
    case `internal`(MessageInfoInternal)
    case externalOut(MessageInfoExternalOut)
}

// MARK: Hashable

extension CommonMessageInfoRelaxed: Hashable {}

// MARK: Sendable

extension CommonMessageInfoRelaxed: Sendable {}

// MARK: CellCodable

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
///
/// ext_out_msg_info$11
///  src:MsgAddressInt
///  dest:MsgAddressExt
///  created_lt:uint64
///  created_at:uint32
///  = CommonMsgInfoRelaxed;
/// ```
extension CommonMessageInfoRelaxed: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        if let value = try? MessageInfoInternal(from: &container) {
            self = .internal(value)
        } else if let value = try? MessageInfoExternalOut(from: &container) {
            self = .externalOut(value)
        } else {
            throw TLBCodingError("`CommonMessageInfoRelaxed` must not have `MessageInfoExternalIn`")
        }
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        switch self {
        case let .internal(`internal`):
            try `internal`.encode(to: &container)
        case let .externalOut(externalOut):
            try externalOut.encode(to: &container)
        }
    }
}
