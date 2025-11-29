//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - WalletContractMethodCollection

/// A collection of method types available for a wallet contract. Conforming types
/// provide factory access to on-chain methods specific to wallet operations
/// (for example, retrieving the wallet’s public key).
///
/// Wallet contracts expose their available methods through this protocol,
/// allowing callers to invoke read-only or state-changing methods on-chain.
public protocol WalletContractMethodCollection {
    /// The type representing the `get_public_key` on-chain method for wallet contracts.
    /// Conforming implementations return the concrete `WalletGetPublicKeyMethod` type.
    var getPublicKey: WalletGetPublicKeyMethod.Type { get }
}

public extension WalletContractMethodCollection {
    /// Default implementation that returns the standard `WalletGetPublicKeyMethod` type.
    var getPublicKey: WalletGetPublicKeyMethod.Type { WalletGetPublicKeyMethod.self }
}

public extension WalletContract {
    /// Retrieves the wallet’s public key from on-chain state by invoking the
    /// `get_public_key` method defined in the contract’s method collection.
    ///
    /// This function uses the provided `networkProvider` to send a read-only call
    /// to the blockchain node, then decodes the result as a `Data`.
    ///
    /// - Parameters:
    ///   - networkProvider: An implementation of `NetworkProvider` used to dispatch
    ///     the call to the blockchain. It handles HTTP/HTTPS or GRPC communication.
    ///   - network: An enumeration specifying the target network (e.g., `.mainnet`,
    ///     `.testnet`). Defaults to `.mainnet`.
    /// - Returns: A `Data` containing the raw bytes of the wallet’s Ed25519 public key.
    /// - Throws:
    ///   - Errors related to ABI encoding of the call arguments.
    ///   - Errors returned by the network provider (e.g., connectivity issues, invalid response).
    ///   - Decoding errors if the returned value does not match the expected format.
    ///
    /// **Usage Example**:
    /// ```swift
    /// let publicKeyBytes = try await myWallet.getPublicKey(
    ///     using: myNetworkProvider,
    ///     in: .testnet
    /// )
    /// ```
    @inlinable @inline(__always)
    func getPublicKey(
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws -> Foundation.Data {
        try await execute(\.getPublicKey, using: networkProvider, in: network)
    }
}

// MARK: - WalletGetPublicKeyMethod

/// A `Contract.Method` implementation representing the `get_public_key` on-chain
/// call for a wallet contract. This method takes no arguments and returns the
/// wallet’s public key as a single numeric tuple element.
///
/// Conforming to `Contract.Method` allows this class to participate in the
/// generic `execute` machinery, which handles encoding, sending, and decoding
/// of ABI-based method calls.
open class WalletGetPublicKeyMethod: Contract.Method {
    // MARK: Lifecycle

    /// Convenience initializer for creating a `get_public_key` method with no arguments.
    ///
    /// Internally, this calls `init(rawValue: ())` since the method signature
    /// does not require any parameters.
    convenience init() {
        self.init(rawValue: ())
    }

    /// Designated initializer for the `get_public_key` method.
    ///
    /// - Parameter rawValue: A `Void` tuple representing empty argument list.
    public required init(rawValue: Void) {
        self.rawValue = rawValue
    }

    // MARK: Open

    /// The exact on-chain name of this method as specified in the contract ABI.
    open class var name: String { "get_public_key" }

    /// Decodes the returned `Tuple` from the blockchain call, extracting the
    /// first numeric element as the public key bytes.
    ///
    /// - Parameter tuple: The raw `Tuple` returned by the network provider,
    ///   where `tuple.rawValue` is an array of `Tuple.Element`.
    /// - Returns: A `Data` containing the 32-byte Ed25519 public key.
    /// - Throws: `Error.invalidResponse` if the tuple’s first element is missing
    ///           or not a `number`.
    open func decode(_ tuple: Tuple) throws -> Data {
        guard let first = tuple.rawValue.first,
              case let Tuple.Element.number(value) = first
        else { throw Error.invalidResponse }
        return value
    }

    // MARK: Public

    /// The expected result type of the `get_public_key` call.
    public typealias Result = Data

    /// Errors that can occur when decoding the public key response.
    public enum Error: Swift.Error {
        /// Indicates that the returned tuple did not contain a valid numeric element.
        case invalidResponse
    }

    /// The raw argument value (`Void`) for this method. Required by `Contract.Method`.
    public let rawValue: Void
}
