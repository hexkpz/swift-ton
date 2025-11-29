//
//  Created by Anton Spivak
//

import BigInt

// MARK: - StateInit

public struct StateInit {
    // MARK: Lifecycle

    public init(
        splitDepth: UInt32?,
        tickTock: TickTock?,
        code: Cell?,
        data: Cell?,
        libraries: [HashmapE.UInt256: SimpleLibrary]
    ) {
        self.splitDepth = splitDepth
        self.tickTock = tickTock
        self.code = code
        self.data = data
        self.libraries = libraries
    }

    // MARK: Public

    public let splitDepth: UInt32?
    public let tickTock: TickTock?

    public let code: Cell?
    public let data: Cell?

    public let libraries: [HashmapE.UInt256: SimpleLibrary]
}

// MARK: Hashable

extension StateInit: Hashable {}

// MARK: Sendable

extension StateInit: Sendable {}

// MARK: CellCodable

///
/// https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L141
/// ```
/// _
///  split_depth:(Maybe (## 5))
///  special:(Maybe TickTock)
///  code:(Maybe ^Cell)
///  data:(Maybe ^Cell)
///  library:(HashmapE 256 SimpleLib)
///  = StateInit;
///  ```
extension StateInit: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        self.splitDepth = try container.decodeIfPresent(UInt32.self, truncatingToBitWidth: 5)
        self.tickTock = try container.decodeIfPresent(TickTock.self)

        self.code = try container.decodeIfPresent(Cell.self)
        self.data = try container.decodeIfPresent(Cell.self)

        self.libraries = try container.decode(contentsOf: [HashmapE.UInt256: SimpleLibrary].self)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encodeIfPresent(splitDepth, truncatingToBitWidth: 5)
        try container.encodeIfPresent(tickTock)

        try container.encodeIfPresent(code)
        try container.encodeIfPresent(data)

        try container.encode(contentsOf: libraries)
    }
}
