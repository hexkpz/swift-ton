//
//  Created by Anton Spivak
//

import Testing

@testable import Contracts

public struct WalletTypingsTests {
    typealias WalletIdentifierTest = (
        network: NetworkKind,
        context: WalletIdentifier.Context,
        rawValue: UInt32
    )

    @Test("Test WalletIdentifier", arguments: [
        (.mainnet, .client(.basic, .v5r1, 0), 2_147_483_409),
        (.mainnet, .client(.master, .v5r1, 0), 8_388_369),
        (.testnet, .client(.basic, .v5r1, 0), 2_147_483_645),
        (.testnet, .client(.master, .v5r1, 0), 8_388_605),
    ] as [WalletIdentifierTest])
    func testWalletIdentifier(_ tuple: WalletIdentifierTest) {
        let identifier = WalletIdentifier(network: tuple.network, context: tuple.context)
        #expect(identifier.rawValue == tuple.rawValue)
        #expect(identifier.context(for: tuple.network) == tuple.context)
    }
}
