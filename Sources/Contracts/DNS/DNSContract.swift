//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - DNSContract

public struct DNSContract: ContractProtocol {
    // MARK: Lifecycle

    public init(rawValue: Contract) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public let rawValue: Contract

    /// Performs the core resolve logic, handling recursion when encountering next-resolver records.
    ///
    /// - Parameters:
    ///   - domain: The domain string or remaining suffix.
    ///   - category: Optional record category to filter.
    ///   - networkProvider: The provider used to query the blockchain.
    ///   - network: The network kind to target.
    /// - Returns: A `ResolveMethod.Response` with record and remaining domain.
    /// - Throws: DNSContract.Error on invalid input or unexpected responses.
    public func recursivelyResolve(
        _ domain: String,
        with category: RecordCategory?,
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws -> Record? {
        let result = try await execute(
            \.dnsresolve,
            arguments: (domain, category),
            using: networkProvider,
            in: network
        )

        guard let result
        else { return nil }

        switch result.record {
        case let .nextResolver(resolverAddress):
            if category == .next {
                return .nextResolver(resolverAddress)
            } else if let remainingDomain = result.remainingDomain {
                let contract = Self(address: resolverAddress)
                return try await contract.recursivelyResolve(
                    remainingDomain,
                    with: category,
                    using: networkProvider,
                    in: network
                )
            } else {
                throw Error.invalidResponse(
                    "Contraxt error: Got next resolver address without remaining domain"
                )
            }
        default:
            return result.record
        }
    }
}

public extension DNSContract {
    /// Recursively resolves a domain to its associated wallet contract address, if present.
    ///
    /// - Parameters:
    ///   - domain: The fully-qualified domain string to resolve.
    ///   - networkProvider: The provider used to query the blockchain.
    ///   - network: The network kind to target (defaults to `.mainnet`).
    /// - Returns: An `InternalAddress` if a wallet record was found, or `nil`.
    /// - Throws: DNSContract.Error on invalid input or response.
    func recursivelyResolveWalletAddress(
        _ domain: String,
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws -> InternalAddress? {
        let result = try await recursivelyResolve(
            domain,
            with: .wallet,
            using: networkProvider,
            in: network
        )

        switch result {
        case let .contractAddress(address):
            return address
        default:
            return nil
        }
    }

    /// Recursively resolves all records for a given domain, returning the raw hashmap if available.
    ///
    /// - Parameters:
    ///   - domain: The domain string to resolve.
    ///   - networkProvider: The provider used to query the blockchain.
    ///   - network: The network kind to target (defaults to `.mainnet`).
    /// - Returns: A `HashmapE` of records or `nil` if not present.
    /// - Throws: DNSContract.Error on invalid input or response.
    func recursivelyResolveAllRecords(
        _ domain: String,
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws -> HashmapE? {
        let result = try await recursivelyResolve(
            domain,
            with: nil,
            using: networkProvider,
            in: network
        )

        switch result {
        case let .recordsCollection(hashmap):
            return hashmap
        default:
            return nil
        }
    }
}

// MARK: ContractABI.Methods

extension DNSContract: ContractABI.Methods {
    /// Collection of on-chain methods exposed by the DNS contract.
    public struct MethodCollection {
        /// The DNS resolve method (dnsresolve).
        public var dnsresolve: ResolveMethod.Type { ResolveMethod.self }
    }
}
