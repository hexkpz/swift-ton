//
//  Created by Anton Spivak
//

// MARK: - TickTock

public struct TickTock {
    // MARK: Lifecycle

    init(tick: Bool, tock: Bool) {
        self.tick = tick
        self.tock = tock
    }

    // MARK: Public

    public let tick: Bool
    public let tock: Bool
}

// MARK: Hashable

extension TickTock: Hashable {}

// MARK: Sendable

extension TickTock: Sendable {}

// MARK: CellCodable

///
/// https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L139
/// ```
/// tick_tock$_
///  tick:Bool
///  tock:Bool
///  = TickTock;
///  ```
extension TickTock: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        self.tick = try container.decode(Bool.self)
        self.tock = try container.decode(Bool.self)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(tick)
        try container.encode(tock)
    }
}
