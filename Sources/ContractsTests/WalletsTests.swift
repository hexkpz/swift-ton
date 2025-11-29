//
//  Created by Anton Spivak
//

import Testing
import Foundation

@testable import Contracts

// MARK: - WalletsTests

public struct WalletsTests {
    typealias WalletContractTestData = (publicKey: Data?, address: Address)

    @Test("Test Wallet V3R2", arguments: [
        (Data(
            hexadecimalString: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522"
        ), "EQA0D_5WdusaCB-SpnoE6l5TzdBmgOkzTcXrdh0px6g3zJSk"),
    ] as [WalletContractTestData])
    func testWalletV3R2(_ tuple: WalletContractTestData) throws {
        let publicKey = try #require(tuple.publicKey)
        try #expect(WalletV3R2(publicKey: publicKey).address == InternalAddress(tuple.address))
    }

    @Test("Test Wallet V4R2", arguments: [
        (Data(
            hexadecimalString: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522"
        ), "EQDnBF4JTFKHTYjulEJyNd4dstLGH1m51UrLdu01_tw4z2Au"),
    ] as [WalletContractTestData])
    func testWalletV4R2(_ tuple: WalletContractTestData) throws {
        let publicKey = try #require(tuple.publicKey)
        try #expect(WalletV4R2(publicKey: publicKey).address == InternalAddress(tuple.address))
    }

    @Test("Test Wallet V5R1", arguments: [
        (Data(
            hexadecimalString: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522"
        ), "UQBiUbwjoB56b7CYtoiPnY5vPh2Fwjva6jEPBhqnttjQKpce"),
    ] as [WalletContractTestData])
    func testWalletV5R1(_ tuple: WalletContractTestData) throws {
        let publicKey = try #require(tuple.publicKey)
        try #expect(WalletV5R1(publicKey: publicKey).address == InternalAddress(tuple.address))
    }
}
