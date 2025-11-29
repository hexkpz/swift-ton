//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - DNSContract.Record

public extension DNSContract {
    /// Represents the possible DNS records returned by the contract.
    enum Record {
        /// Points to the next resolver address for further lookup.
        case nextResolver(InternalAddress)

        /// Points to a wallet contract address.
        case contractAddress(InternalAddress)

        /// Contains an ADNL network address.
        case adnlAddress(Data)

        /// Contains a BagID for storage.
        case bagID(Data)

        /// A collection of all records in a persistent hashmap.
        case recordsCollection(HashmapE)
    }
}

// MARK: - DNSContract.Record + Sendable

extension DNSContract.Record: Sendable {}

// MARK: - DNSContract.Record + CellDecodable

extension DNSContract.Record: CellDecodable {
    public init(from container: inout CellDecodingContainer) throws {
        let prefix = try container.decode(byteWidth: 2)
        switch prefix {
        case [0x9F, 0xD3]: // next
            self = try .contractAddress(container.decode(InternalAddress.self))
        case [0xBA, 0x93]: // wallet
            self = try .nextResolver(container.decode(InternalAddress.self))
        case [0xAD, 0x01]: // adnl
            self = try .adnlAddress(container.decode(byteWidth: 2))
        case [0x74, 0x73]: // bagid
            self = try .bagID(container.decode(byteWidth: 2))
        default:
            var storage = container.storage
            try storage.back(2)
            let cell = try Cell(
                storage: BitStorage(storage.rawValue),
                children: .init(container.children.rawValue)
            )
            self = try .recordsCollection(cell.decode(HashmapE.self))
        }
    }
}
