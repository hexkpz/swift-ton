//
//  Created by Anton Spivak
//

import Foundation

// MARK: - NetworkProviderError

public enum NetworkProviderError: Error {
    case noSuchContract(InternalAddress)
    case customProviderError(description: String)
}

// MARK: CustomStringConvertible

extension NetworkProviderError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .noSuchContract(address):
            "Couldn't communicate with contract \(address), bacuase it doesn't deployed or it's doesnt have local StateInit."
        case let .customProviderError(description): description
        }
    }
}

// MARK: LocalizedError

extension NetworkProviderError: LocalizedError {
    @inlinable @inline(__always)
    public var errorDescription: String? { description }
}

// MARK: - NetworkProvider

/// A network abstraction for retrieving contract state and sending BOC
/// messages. Different backends (e.g. HTTP, gRPC) might implement this
/// protocol to interface with a TON blockchain or test environment.
public protocol NetworkProvider: Sendable {
    /// Fetches the current on-chain state for the given address, returning
    /// a `Contract.State` containing balance, code, etc.
    ///
    /// - Parameter address: The `InternalAddress` whose state to load.
    /// - Returns: A `Contract.State` describing the contract’s current data.
    /// - Throws: If the address is invalid or network communication fails.
    func state(
        for address: InternalAddress,
        in network: NetworkKind
    ) async throws -> Contract.State

    /// Submits a serialized Bag-of-Cells (BOC) message (such as an external
    /// message or a transaction) to the network for processing.
    ///
    /// - Parameter boc: A `BOC` typically built from a root `Cell`.
    /// - Throws: If network communication fails or the message is invalid.
    func send(
        boc: BOC,
        in network: NetworkKind
    ) async throws

    /// Executes an on-chain method call by name, encoding arguments and
    /// decoding the raw result tuple.
    ///
    /// - Parameters:
    ///   - method: The on-chain method name to invoke (ABI entrypoint).
    ///   - arguments: A `Tuple` containing pre-encoded ABI-arguments.
    ///   - address: The `InternalAddress` of the contract to call.
    ///   - network: The network kind to execute the call on.
    /// - Returns: A `Tuple` representing the raw ABI-encoded result.
    /// - Throws: If network communication fails or decoding errors occur.
    func run(
        _ method: String,
        arguments: Tuple,
        on: InternalAddress,
        in network: NetworkKind
    ) async throws -> Tuple
}

// MARK: - NetworkKind

public enum NetworkKind: Int32 {
    case mainnet = -239
    case testnet = -3
}

// MARK: Sendable

extension NetworkKind: Sendable {}

// MARK: Hashable

extension NetworkKind: Hashable {}
