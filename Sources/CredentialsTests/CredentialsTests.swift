//
//  Created by Anton Spivak
//

import Testing
import Contracts
import Crypto

@testable import Credentials

// MARK: - CredentialsTests

public struct CredentialsTests {
    typealias DerivationPathTestData = (
        mnemonica: Mnemonica,
        derivationPath: DerivationPath,
        address: Address
    )

    @Test("Test DerivationPath", arguments: [
        (
            "lend match creek slight wrong sting face plate oval april elbow margin",
            "m/44'/607'/0'",
            "UQAM_qgoGKDzcoU_eTFREXk9UvfpcxNtg8mSIoQc1zMe_Iqe"
        ),
    ] as [DerivationPathTestData])
    func testDerivationPath(_ tuple: DerivationPathTestData) throws {
        let credentials = try Credentials(tuple.mnemonica, derivationPath: tuple.derivationPath)
        let wallet = try WalletV4R2(workchain: .basic, credentials: credentials)
        #expect(wallet.address == InternalAddress(tuple.address))
    }
}
