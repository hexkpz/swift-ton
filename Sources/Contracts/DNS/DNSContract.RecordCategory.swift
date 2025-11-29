//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - DNSContract.RecordCategory

public extension DNSContract {
    /// Categories of DNS records supported by the DNSContract.
    enum RecordCategory {
        /// Next Resolver Contract Address
        case next

        /// Contract Address
        case wallet

        /// ANDL address or BagID
        case site

        /// Bag ID
        case storage
    }
}

// MARK: - DNSContract.RecordCategory + Sendable

extension DNSContract.RecordCategory: Sendable {}

extension Optional where Wrapped == DNSContract.RecordCategory {
    /// Converts an optional RecordCategory into a Tuple.Element for TVM calls.
    var asTupleElement: Tuple.Element {
        switch self {
        case .none: .number([0x00])
        case .next: .number(Data("dns_next_resolver".utf8).sha256)
        case .wallet: .number(Data("wallet".utf8).sha256)
        case .site: .number(Data("site".utf8).sha256)
        case .storage: .number(Data("storage".utf8).sha256)
        }
    }
}
