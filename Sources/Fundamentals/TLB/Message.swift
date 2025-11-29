//
//  Created by Anton Spivak
//

// MARK: - Message

public struct Message {
    // MARK: Lifecycle

    public init(info: CommonMessageInfo, stateInit: StateInit?, body: Cell) {
        self.info = info
        self.stateInit = stateInit
        self.body = body
    }

    // MARK: Public

    public let info: CommonMessageInfo
    public let stateInit: StateInit?
    public let body: Cell
}

// MARK: Sendable

extension Message: Sendable {}

// MARK: Hashable

extension Message: Hashable {}

// MARK: CellCodable

/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L155
/// ```
/// message$_ {X:Type}
///  info:CommonMsgInfo
///  init:(Maybe (Either StateInit ^StateInit))
///  body:(Either X ^X)
///  = Message X;
/// ```
extension Message: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        self.info = try .init(from: &container)
        self.stateInit = try container.dissociateIfPossibleIfPresent(StateInit.self)
        self.body = try container.dissociateIfPossible(.ordinary)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try info.encode(to: &container)
        try container.concatIfPossibleIfPresent(stateInit, preserving: .init(storage: 1))
        try container.concatIfPossible(body)
    }
}

public extension Message {
    static func external(
        to destinationAddress: InternalAddress,
        with stateInit: StateInit? = nil,
        body: Cell = Cell()
    ) -> Self {
        .init(
            info: .externalIn(.init(source: nil, destination: destinationAddress, importFee: 0)),
            stateInit: stateInit,
            body: body
        )
    }
}
