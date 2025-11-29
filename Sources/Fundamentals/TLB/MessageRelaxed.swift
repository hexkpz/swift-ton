//
//  Created by Anton Spivak
//

// MARK: - MessageRelaxed

public struct MessageRelaxed {
    // MARK: Lifecycle

    public init(info: CommonMessageInfoRelaxed, stateInit: StateInit?, body: Cell) {
        self.info = info
        self.stateInit = stateInit
        self.body = body
    }

    // MARK: Public

    public let info: CommonMessageInfoRelaxed
    public let stateInit: StateInit?
    public let body: Cell
}

// MARK: Hashable

extension MessageRelaxed: Hashable {}

// MARK: Sendable

extension MessageRelaxed: Sendable {}

// MARK: CellCodable

///
/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L159
/// ```
/// message$_ {X:Type}
///  info:CommonMsgInfoRelaxed
///  init:(Maybe (Either StateInit ^StateInit))
///  body:(Either X ^X)
///  = MessageRelaxed X;
/// ```
extension MessageRelaxed: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        self.info = try container.decode(contentsOf: CommonMessageInfoRelaxed.self)
        self.stateInit = try container.dissociateIfPossibleIfPresent(StateInit.self)
        self.body = try container.dissociateIfPossible(.ordinary)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(contentsOf: info)
        try container.concatIfPossibleIfPresent(stateInit, preserving: .init(storage: 1))
        try container.concatIfPossible(body)
    }
}

public extension MessageRelaxed {
    static func `internal`(
        to destionationAddress: InternalAddress,
        value: CurrencyValue,
        bounce: Bool,
        stateInit: StateInit?,
        body: Cell = Cell()
    ) -> MessageRelaxed {
        .init(
            info: .internal(.init(
                isInstantHypercubeRoutingDisabled: true,
                bounce: bounce,
                isBounced: false,
                source: nil,
                destination: destionationAddress,
                value: .init(coins: value, others: [:]),
                instantHypercubeRoutingFee: 0,
                forwardFee: 0,
                createdLt: 0,
                createdAt: 0
            )),
            stateInit: stateInit,
            body: body
        )
    }
}
