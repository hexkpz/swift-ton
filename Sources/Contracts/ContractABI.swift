//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - ContractABI

/// A namespace grouping various interfaces for describing how a contract
/// handles data, external messages, and internal messages. Typically, you
/// conform your contract type (that also adopts `ContractProtocol`) to
/// one or more of these sub-protocols to define how data is encoded or
/// how messages are structured.
public enum ContractABI {}

// MARK: ContractABI.Data

public extension ContractABI {
    /// A protocol indicating that a contract has a cell-based `Data` structure
    /// that can be decoded from the contract’s data cell. Conforming types must
    /// also adopt `ContractProtocol` to access the raw on-chain cell.
    ///
    /// Typically, you define:
    /// ```swift
    /// associatedtype Data: CellDecodable
    /// ```
    /// to provide a custom cell layout for storing contract-specific fields.
    protocol Data: ContractProtocol {
        /// The concrete `CellDecodable` type representing this contract’s on-chain data.
        associatedtype Data: CellDecodable
    }
}

public extension ContractProtocol where Self: ContractABI.Data {
    /// Decodes the contract's data cell into the typed `Data` instance, if present.
    /// Returns `nil` if no data cell is available or decoding fails.
    var data: Data? {
        get throws {
            guard let data = rawValue.data
            else { return nil }
            return try data.decode(Data.self)
        }
    }
}

public extension ContractProtocol where Self: ContractABI.Data, Self.Data: CellEncodable {
    /// Initializes a contract with the given workchain ID, compiled code cell,
    /// and typed `Data` payload. Wraps these into a `StateInit` automatically.
    ///
    /// - Parameters:
    ///   - worckhain: The `Workchain` ID (default is `.basic` = 0).
    ///   - code: The compiled smart contract code cell.
    ///   - data: An instance of `Data` (`CellEncodable`) representing on-chain storage.
    /// - Throws: If constructing the initial `StateInit` fails.
    init(worckhain: Workchain = .basic, code: Cell, data: Data) throws {
        try self.init(rawValue: .init(workchain: worckhain, state: .init(
            splitDepth: nil,
            tickTock: nil,
            code: code,
            data: Cell(data),
            libraries: [:]
        )))
    }
}

// MARK: - ContractABI.ExternalMessages

public extension ContractABI {
    /// A protocol indicating that a contract supports receiving external
    /// messages (e.g., transactions) from outside the chain. Conforming types
    /// must also adopt `ContractProtocol` so the implementation can wrap or
    /// send `ExternalMessage` cells.
    protocol ExternalMessages: ContractProtocol {
        /// The cell‐encodable type representing incoming external message data.
        associatedtype ExternalMessage: CellEncodable
    }
}

public extension ContractABI.ExternalMessages {
    /// Builds an executable action (BOC) for sending an external message body
    /// to this contract. Does not transmit over the network; it only constructs
    /// the BOC for inspection or manual dispatch.
    ///
    /// - Parameter message: A value conforming to `ExternalMessage`.
    /// - Returns: A `Contract.ExecutableAction` (BOC) ready for broadcasting.
    /// - Throws:
    ///   - `NetworkProviderError.noSuchContract` if the contract has not been initialized.
    ///   - Any encoding or cell‐construction error.
    @inlinable @inline(__always)
    func receive(_ message: ExternalMessage) throws -> Contract.ExecutableAction {
        try rawValue.receive(message)
    }
}

// MARK: - ContractABI.InternalMessages

public extension ContractABI {
    /// A protocol indicating that a contract can process or dispatch internal
    /// messages from other on-chain contracts. Conforming types must also adopt
    /// `ContractProtocol` so they can encode/decode `InternalMessage`.
    protocol InternalMessages: ContractProtocol {
        /// The cell‐encodable type for messages exchanged between contracts.
        associatedtype InternalMessage: CellEncodable
    }
}

// MARK: - ContractABI.Methods

public extension ContractABI {
    /// A marker protocol indicating that the contract exposes a set of
    /// typed ABI methods. Conforming types must also adopt `ContractProtocol`.
    protocol Methods: ContractProtocol {
        /// A type grouping the available `Contract.Method` types for this contract.
        associatedtype MethodCollection
    }
}

public extension ContractABI.Methods {
    /// Executes a no‐argument method from the `MethodCollection`, decoding
    /// its strongly‐typed result.
    ///
    /// - Parameters:
    ///   - method:         A key path to the method type in `MethodCollection`.
    ///   - networkProvider:The provider used to perform the on‐chain call.
    ///   - network:        The network kind to target (default: `.mainnet`).
    /// - Returns: The decoded `Result` of the method.
    /// - Throws: Any encoding, network, or decoding error.
    @inlinable @inline(__always)
    func execute<R>(
        _ method: KeyPath<MethodCollection, R.Type>,
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws -> R.Result where R: Contract.Method, R.Arguments == Void {
        try await rawValue.run(R.self, using: networkProvider, in: network)
    }

    /// Executes a method with arguments from the `MethodCollection`, decoding
    /// its strongly‐typed result.
    ///
    /// - Parameters:
    ///   - method:         A key path to the method type in `MethodCollection`.
    ///   - arguments:      The method’s raw arguments to encode.
    ///   - networkProvider:The provider used to perform the on‐chain call.
    ///   - network:        The network kind to target (default: `.mainnet`).
    /// - Returns: The decoded `Result` of the method.
    /// - Throws: Any encoding, network, or decoding error.
    @inlinable @inline(__always)
    func execute<R>(
        _ method: KeyPath<MethodCollection, R.Type>,
        arguments: R.Arguments,
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws -> R.Result where R: Contract.Method {
        try await rawValue.run(R.self, arguments: arguments, using: networkProvider, in: network)
    }
}
