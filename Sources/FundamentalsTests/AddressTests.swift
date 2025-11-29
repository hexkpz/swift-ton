//
//  Created by Anton Spivak
//

import Testing

@testable import Fundamentals

// MARK: - AddressTests

struct AddressTests {
    struct AddressMetadata {
        // MARK: Lifecycle

        init(
            _ string: String,
            _ workchain: Workchain,
            _ hash: String,
            _ isBounceable: Bool = false,
            _ isTestable: Bool = false
        ) {
            self.string = string
            self.workchain = workchain
            self.hash = hash
            self.isBounceable = isBounceable
            self.isTestable = isTestable
        }

        // MARK: Internal

        let string: String

        let workchain: Workchain
        let hash: String

        let isBounceable: Bool
        let isTestable: Bool
    }

    @Test("Friendly Addresses", arguments: [
        AddressMetadata(
            "0QAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4-QO",
            .basic,
            "2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3",
            false,
            false
        ),
        AddressMetadata(
            "kQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi47nL",
            .basic,
            "2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3",
            true,
            true
        ),
    ])
    func friendlyAddressParse(_ metadata: AddressMetadata) throws {
        let friendlyAddress = try #require(FriendlyAddress(rawValue: metadata.string))
        if metadata.isBounceable {
            #expect(friendlyAddress.options.contains(.bounceable))
        }
        if metadata.isTestable {
            #expect(friendlyAddress.options.contains(.testable))
        }

        #expect(friendlyAddress.workchain == metadata.workchain)
        #expect(friendlyAddress.hash == Data(hexadecimalString: metadata.hash))
        #expect(friendlyAddress.stringValue() == metadata.string)

        let friendlyAddress2 = try #require(FriendlyAddress(rawValue: friendlyAddress.stringValue(
            [.bounceable],
            .base64URL
        )))

        let friendlyAddress3 = try #require(FriendlyAddress(rawValue: friendlyAddress.stringValue(
            [],
            .base64
        )))

        #expect(friendlyAddress2 != friendlyAddress3)
        #expect(
            friendlyAddress2.stringValue([], .base64) == friendlyAddress3.stringValue([], .base64)
        )
    }

    @Test("Raw Addresses", arguments: [
        AddressMetadata(
            "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3",
            .basic,
            "2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3"
        ),
        AddressMetadata(
            "-1:3333333333333333333333333333333333333333333333333333333333333333",
            .master,
            "3333333333333333333333333333333333333333333333333333333333333333"
        ),
    ])
    func rawAddressParse(_ metadata: AddressMetadata) throws {
        let rawAddress = try #require(InternalAddress(metadata.string))
        #expect(rawAddress.workchain == metadata.workchain)
        #expect(rawAddress.hash == Data(hexadecimalString: metadata.hash))
        #expect(rawAddress.description == metadata.string.uppercased())
    }

    @Test("Convertible Addresses Tests", arguments: [
        AddressMetadata(
            "0QAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4-QO",
            .basic,
            "2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3",
            false,
            false
        ),
    ])
    func convertibleAddressesParse(_ metadata: AddressMetadata) throws {
        let friendlyAddress = try #require(FriendlyAddress(rawValue: metadata.string))
        #expect(friendlyAddress.workchain == InternalAddress(friendlyAddress).workchain)
        #expect(friendlyAddress.hash == InternalAddress(friendlyAddress).hash)

        let anyAddress = InternalAddress(friendlyAddress)
        #expect(anyAddress.workchain == friendlyAddress.workchain)
        #expect(anyAddress.hash == friendlyAddress.hash)
    }

    @Test("Invalid Addresses", arguments: [
        "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422",
        "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e",
        "ton://EQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4wJB",
        "EQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4wJ",
        "ton://transfer/EQDXDCFLXgiTrjGSNVBuvKPZVYlPn3J_u96xxLas3_yoRWRk",
        "0:EQDXDCFLXgiTrjGSNVBuvKPZVYlPn3J_u96xxLas3_yoRWRk",
        "",
    ])
    func invalidAddressParse(_ address: String) {
        #expect(FriendlyAddress(address) == nil)
        #expect(InternalAddress(address) == nil)
        #expect(Address(address) == nil)
    }
}
