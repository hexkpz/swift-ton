//
//  Created by Anton Spivak
//

// MARK: - MessageInfoExternalIn

public struct MessageInfoExternalIn {
    // MARK: Lifecycle

    public init(source: ExternalAddress?, destination: InternalAddress, importFee: CurrencyValue) {
        self.source = source
        self.destination = destination
        self.importFee = importFee
    }

    // MARK: Public

    public let source: ExternalAddress?
    public let destination: InternalAddress

    public let importFee: CurrencyValue
}

// MARK: CellCodable

///
/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L130
/// ```
/// ext_in_msg_info$10
///  src:MsgAddressExt
///  dest:MsgAddressInt
///  import_fee:Grams
///  = CommonMsgInfo;
/// ```
extension MessageInfoExternalIn: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        guard try container.decode(Bool.self), try !container.decode(Bool.self)
        else {
            throw TLBCodingError.invalidEnumerationFlagValue(for: Self.self)
        }

        self.source = try container.decodeIfPresent(ExternalAddress.self)
        self.destination = try container.decode(InternalAddress.self)
        self.importFee = try container.decode(CurrencyValue.self)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(true)
        try container.encode(false)

        try container.encodeIfPresent(source)
        try container.encode(destination)
        try container.encode(importFee)
    }
}

// MARK: Hashable

extension MessageInfoExternalIn: Hashable {}

// MARK: Sendable

extension MessageInfoExternalIn: Sendable {}
