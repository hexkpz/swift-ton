//
//  Created by Anton Spivak
//

import Testing

@testable import Fundamentals

// MARK: - AddressTests

struct AlgorithmsTests {
    // MARK: Internal

    @Test("CRC16-CCIT (XMODEM)", arguments: [("test", "9B06"), ("", "0000"), ("testtest", "F126")])
    func crc16ccit(_ data: (String, String)) {
        var hash = CRC16CCIT()
        hash.update([UInt8](data.0.utf8))
        #expect(hexadecimalString(hash.finalize()) == data.1)
    }

    @Test(
        "CRC32-C (ISCSI)",
        arguments: [("test", "86A072C0"), ("", "00000000"), ("testtest", "46557539")]
    )
    func crc32c(_ data: (String, String)) {
        var hash = CRC32C()
        hash.update([UInt8](data.0.utf8))
        #expect(hexadecimalString(hash.finalize()) == data.1)
    }

    // MARK: Private

    private func hexadecimalString(_ digest: any DigestProtocol) -> String {
        digest.withUnsafeBytes({ [UInt8]($0).hexadecimalString.uppercased() })
    }
}
