//
//  Created by Anton Spivak
//

import Testing

@testable import Fundamentals

// MARK: - InternalAddressCodingTests

struct InternalAddressCodingTests {
    struct AddressDecodable: CellDecodable {
        // MARK: Lifecycle

        init(from container: inout CellDecodingContainer) throws {
            self.value = try container.decode(Address.self)
        }

        // MARK: Internal

        let value: Address
    }

    @Test(arguments: [
        (
            "0QAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4-QO",
            "533c181e960c018c6dc674ee26a5764077317fa08cbad6bfbc0c1a59edf9fe27"
        ),
        (
            "0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3",
            "533c181e960c018c6dc674ee26a5764077317fa08cbad6bfbc0c1a59edf9fe27"
        ),
        (
            "-1:3333333333333333333333333333333333333333333333333333333333333333",
            "809792c63d0514973bba96bde565a2d70eeef1e0fd43ef3a0531d446981a3d7e"
        ),
    ])
    func testAddresses(
        _ value: (Address, cellHash: Data)
    ) throws {
        let cellb: Cell = try Cell { value.0 }
        let cells: Cell = "\(value.0)"

        #expect(cellb == cells)
        #expect(cellb.representationHash == value.cellHash)

        let rawAddress = InternalAddress(value.0)
        try #expect(InternalAddress(cellb.decode(AddressDecodable.self).value) == rawAddress)
        try #expect(InternalAddress(cells.decode(AddressDecodable.self).value) == rawAddress)
    }
}
