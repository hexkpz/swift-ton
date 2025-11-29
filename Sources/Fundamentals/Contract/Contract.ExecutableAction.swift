//
//  Created by Anton Spivak
//

// MARK: - Contract.ExecutableAction

public extension Contract {
    /// A wrapper around a serialized BOC (bag of cells) payload that represents
    /// a ready-to-send transaction or contract call. Use `execute(using:in:)` to dispatch
    /// this payload to the network.
    struct ExecutableAction: RawRepresentable, Hashable, Sendable {
        // MARK: Lifecycle

        /// Creates an `ExecutableAction` from a raw BOC payload.
        ///
        /// - Parameter rawValue: A `BOC` containing the serialized contract message.
        public init(_ rawValue: BOC) {
            self.rawValue = rawValue
        }

        /// Initializes an `ExecutableAction` from a raw BOC value.
        ///
        /// - Parameter rawValue: A `BOC` containing the serialized contract message.
        public init(rawValue: BOC) {
            self.rawValue = rawValue
        }

        // MARK: Public

        /// The underlying BOC payload for this executable action.
        public let rawValue: BOC
    }
}

public extension Contract.ExecutableAction {
    /// Sends the encapsulated BOC payload to the specified network using the provided
    /// `NetworkProvider`. This will broadcast the transaction or contract call.
    ///
    /// - Parameters:
    ///   - networkProvider: The provider responsible for transmitting the BOC to a TON node.
    ///   - network: The target network (e.g., `.mainnet`, `.testnet`).
    /// - Throws: An error if the send operation fails (network issues, invalid response, etc.).
    func execute(
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws {
        try await networkProvider.execute(self, in: network)
    }
}

public extension NetworkProvider {
    /// Transmits an `ExecutableAction`’s BOC payload to the blockchain. Internally calls
    /// `send(boc:in:)` with the raw BOC bytes from the `ExecutableAction`.
    ///
    /// - Parameters:
    ///   - executableAction: The `ExecutableAction` containing the serialized BOC payload.
    ///   - network: The target TON network (e.g., `.mainnet`, `.testnet`).
    /// - Throws: An error if the underlying send operation fails (e.g., network failure,
    ///           invalid node response, etc.).
    func execute(
        _ executableAction: Contract.ExecutableAction,
        in network: NetworkKind = .mainnet
    ) async throws {
        try await send(boc: executableAction.rawValue, in: network)
    }
}
