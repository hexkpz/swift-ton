//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - Jetton.MinterContract

public extension Jetton {
    /// A wrapper around a Jetton minter contract on TON. The minter contract is
    /// responsible for creating new Jetton wallets (accounts) for users. Clients
    /// can use this type to query the minter for a user’s specific wallet address.
    struct MinterContract: ContractProtocol {
        // MARK: Lifecycle

        public init(rawValue: Contract) {
            self.rawValue = rawValue
        }

        // MARK: Public

        public let rawValue: Contract

        /// Fetches the Jetton wallet contract address for a given user’s TON address.
        ///
        /// This method invokes the on-chain `get_wallet_address` method, which returns
        /// the specific Jetton wallet address where the user can hold/burn Jettons.
        ///
        /// - Parameters:
        ///   - address: The user’s `InternalAddress` (TON address) for whom to derive
        ///              the Jetton wallet.
        ///   - networkProvider: A provider used to query the blockchain state.
        ///   - network: The target network (e.g., `.mainnet`, `.testnet`). Defaults to `.mainnet`.
        /// - Returns: A `WalletContract` instance wrapping the user’s Jetton wallet contract.
        /// - Throws:
        ///   - Errors from ABI encoding of the arguments.
        ///   - Network provider errors (e.g., connectivity issues).
        ///   - `Jetton.Error.invalidResponse` if the returned data cannot be decoded to a valid address.
        ///
        /// **Example**:
        /// ```swift
        /// let minter = Jetton.MinterContract(rawValue: myMinterContract)
        /// let userJettonWallet = try await minter.wallet(
        ///     for: ownerUserAddress,
        ///     using: myNetworkProvider,
        ///     in: .mainnet
        /// )
        /// ```
        public func wallet(
            for address: InternalAddress,
            using networkProvider: any NetworkProvider,
            in network: NetworkKind = .mainnet
        ) async throws -> WalletContract {
            try await .init(address: execute(
                \.getWalletAddress,
                arguments: address,
                using: networkProvider,
                in: network
            ))
        }
    }
}

// MARK: - Jetton.MinterContract + ContractABI.Methods

extension Jetton.MinterContract: ContractABI.Methods {
    /// A collection of on-chain methods available for the Jetton minter contract.
    public struct MethodCollection {
        /// The `get_wallet_address` method type, used to retrieve a user’s Jetton wallet address.
        public var getWalletAddress: GetWalletAddress.Type { GetWalletAddress.self }
    }
}

// MARK: - Jetton.MinterContract.GetWalletAddress

extension Jetton.MinterContract {
    /// A `Contract.Method` implementation for the `get_wallet_address` call.
    /// This method takes a user’s TON address (`InternalAddress`) as input and
    /// returns the Jetton wallet address (`InternalAddress`) where the user can
    /// send or receive Jetton tokens.
    open class GetWalletAddress: Contract.Method {
        // MARK: Lifecycle

        public required init(rawValue: RawValue) {
            self.rawValue = rawValue
        }

        // MARK: Open

        /// The exact on-chain name of the method as defined in the Jetton minter ABI.
        open class var name: String { "get_wallet_address" }

        /// Encodes the user’s TON address into a `Tuple` for the ABI call.
        ///
        /// - Returns: A `Tuple` containing a single slice element encoding the `InternalAddress`.
        /// - Throws: Propagates any encoding errors from `Tuple.init(rawValue:)`.
        open func encode() throws -> Tuple {
            return try .init(rawValue: [.slice(rawValue)])
        }

        /// Decodes the returned `Tuple` from the blockchain call and extracts the
        /// Jetton wallet address as an `InternalAddress`.
        ///
        /// - Parameter tuple: The raw `Tuple` returned by the network provider.
        /// - Returns: An `InternalAddress` representing the user’s Jetton wallet.
        /// - Throws:
        ///   - `Jetton.Error.invalidResponse` if the tuple is empty or its first element
        ///     cannot be decoded to an `InternalAddress`.
        open func decode(_ tuple: Tuple) throws -> Response {
            guard let first = tuple.rawValue.first
            else { throw Jetton.Error.invalidResponse("Response did not contain a valid address") }

            let address: InternalAddress? = switch first {
            case let .cell(cell):
                try? cell.decode({ try $0.decode(InternalAddress.self) })
            case let .slice(cell):
                try? cell.decode({ try $0.decode(InternalAddress.self) })
            default:
                nil
            }

            guard let address
            else {
                throw Jetton.Error.invalidResponse(
                    "First element of response did not contain a valid address"
                )
            }

            return address
        }

        // MARK: Public

        public typealias Response = InternalAddress
        public typealias RawValue = InternalAddress

        public let rawValue: RawValue
    }
}
