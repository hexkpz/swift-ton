//
//  Created by Anton Spivak
//

import Foundation
import BigInt

// MARK: - Contract

/// Represents a TON smart contract reference and its local state, including balance, code, and data.
///
/// The `Contract` struct can be constructed in two primary ways:
///
/// 1. **From an existing on-chain contract** using just the `InternalAddress`:
/// ```swift
/// let address = InternalAddress(workchain: .basic, hash: some32ByteHash)
/// let contract = Contract(address: address)
/// ```
/// In this case, `Contract` can query updates from a `NetworkProvider` to retrieve the latest state.
///
/// 2. **From an initial `StateInit`** (code + data) for a not-yet-deployed (or locally known) contract:
/// ```swift
/// let stateInit = StateInit(...) // define code, data, libraries
/// let contract = try Contract(workchain: .basic, state: stateInit)
/// ```
/// This includes a `StateInit` reference so that `code` or `data` can still be retrieved
/// even if the contract is uninitialized or not yet on-chain.
///
/// - Note: To actually synchronize or send messages, you must supply a `NetworkProvider`
///   that can load the on-chain state or broadcast BOC messages.
///
/// ### Usage
/// ```swift
/// let contract = Contract(address: someInternalAddress)
/// try await contract.update(using: someNetworkProvider)
/// print(contract.balance)
///
/// try await contract.accept(
///    anyCellEncodableBody,
///    using: someNetworkProvider
/// )
/// ```
///
/// For more details, see:
/// [TON Documentation on Smart Contracts](https://docs.ton.org/ton.pdf)
public struct Contract {
    // MARK: Lifecycle

    /// Creates a `Contract` from an existing `InternalAddress`. Use this variant if you only
    /// know the contract address and do not have a `StateInit`. The code and data will be
    /// fetched or remain `nil` until a state update is performed.
    ///
    /// - Parameter address: The `InternalAddress` identifying the contract on a given workchain.
    @inlinable @inline(__always)
    public init(address: InternalAddress) {
        self.init(address: address, initial: nil)
    }

    /// Creates a `Contract` by providing a `workchain` and a full `StateInit` (including code, data,
    /// and optional libraries). This is typically used for locally known or newly deployed contracts,
    /// for which you have an offline reference to the code and data.
    ///
    /// - Parameters:
    ///   - workchain: The `Workchain` ID (defaults to `.basic`).
    ///   - state: A `StateInit` containing contract code, data, and optional libraries.
    /// - Throws: An error if the `InternalAddress` fails to derive from `(workchain, Cell(state))`.
    @inlinable @inline(__always)
    public init(workchain: Workchain = .basic, state: StateInit) throws {
        try self.init(address: InternalAddress(workchain: workchain, state), initial: state)
    }

    @usableFromInline
    init(address: InternalAddress, initial: StateInit?) {
        self._address = address
        self._initial = initial
    }

    // MARK: Public

    /// Returns the current balance of this contract as a `CurrencyValue`. If no state has been
    /// fetched from the network, or the contract is uninitialized, this may be zero or outdated.
    ///
    /// - Note: Updated automatically when `update(using:)` is called.
    @inlinable @inline(__always)
    public var balance: CurrencyValue { _state.withLockedValue({ $0 }).balance }

    /// The immutable `InternalAddress` of this contract.
    @inlinable @inline(__always)
    public var address: InternalAddress { _address }

    /// The initial `StateInit` used to construct this contract, if any.
    ///
    /// - Note: Non-`nil` only when you created the `Contract` via
    ///   `init(workchain:state:)`. Use this to access the code or data
    ///   cells before the contract is deployed on-chain or when you
    ///   need the original `StateInit` regardless of on-chain updates.
    @inlinable @inline(__always)
    public var stateInitial: StateInit? { _initial }

    /// Retrieves the current code cell if known. If the contract is `.active` on the local state, that
    /// active code is returned. Otherwise, if a `StateInit` was provided during initialization and
    /// there have been no updates to override it, that code is returned. If not found, returns `nil`.
    ///
    /// - Note: Code is not guaranteed to remain the same. Ensure you call `update(using:)` if you suspect changes.
    public var code: Cell? {
        switch _state.withLockedValue({ $0 }).status {
        case let .active(code, _): return code
        default: break
        }

        guard let code = _initial?.code
        else {
            return nil
        }

        return code
    }

    /// Retrieves the current data cell if known. If the contract is `.active` on the local state, that
    /// active data is returned. Otherwise, if a `StateInit` was provided during initialization and
    /// there have been no updates to override it, that data is returned. If not found, returns `nil`.
    ///
    /// - Note: Data can change as the contract executes transactions. Use `update(using:)` to refresh.
    public var data: Cell? {
        switch _state.withLockedValue({ $0 }).status {
        case let .active(_, data): return data
        default: break
        }

        guard let data = _initial?.data
        else {
            return nil
        }

        return data
    }

    // MARK: Internal

    @usableFromInline
    let _address: InternalAddress

    @usableFromInline
    let _state: Lock<State> = .init(.unknown())

    @usableFromInline
    let _initial: StateInit?
}

// MARK: Equatable

extension Contract: Equatable {
    /// Equality is based on the underlying `InternalAddress`. Two contracts
    /// referencing the same `InternalAddress` are considered equal.
    @inlinable
    public static func == (lhs: Contract, rhs: Contract) -> Bool {
        lhs.address == rhs.address
    }
}

// MARK: Hashable

extension Contract: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}

// MARK: Sendable

extension Contract: Sendable {}

public extension Contract {
    /// Fetches and applies the latest on-chain state for this contract.
    ///
    /// This will refresh balance, code, data, and status based on what the network reports.
    ///
    /// - Parameters:
    ///   - networkProvider: The provider used to query the blockchain.
    ///   - network:        The network kind (e.g. `.mainnet` or `.testnet`). Defaults to `.mainnet`.
    /// - Throws:
    ///   - `NetworkProviderError.noSuchContract` if the contract is uninitialized
    ///     and no `StateInit` was provided.
    ///   - Any error from message construction or network send.
    func update(
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws {
        let state = try await networkProvider.state(for: address, in: network)
        _state.withLockedValue({ $0 = state })
    }
}

public extension Contract {
    /// Prepares an external message by encoding the provided value into a `Cell`
    /// and wrapping it in a BOC, without sending it.
    ///
    /// - Parameters:
    ///   - body:            A `CellEncodable` value to include in the message.
    ///   - networkProvider: The provider used for any necessary pre-flight checks.
    ///   - network:         The network kind to use. Defaults to `.mainnet`.
    /// - Returns: A `BOC` representing the fully-formed external message.
    ///   - `NetworkProviderError.noSuchContract` if the contract is uninitialized
    ///     and no `StateInit` was provided.
    ///   - Any error from message construction or network send.
    @inlinable @inline(__always)
    func receive<T>(_ body: T) throws -> ExecutableAction where T: CellEncodable {
        try receive(Cell(body))
    }

    /// Prepares an external message from a raw `Cell`, performing a state-existence
    /// check first.
    ///
    /// - Parameters:
    ///   - body:            A raw `Cell` payload.
    /// - Returns: A `BOC` ready for broadcast.
    /// - Throws:
    ///   - `NetworkProviderError.noSuchContract` if the contract is uninitialized
    ///     and no `StateInit` was provided.
    ///   - Any error from message construction or network send.
    func receive(_ body: Cell) throws -> ExecutableAction {
        var stateInitial: StateInit? = nil
        switch _state.withLockedValue({ $0 }).status {
        case .nonexistent where _initial == nil:
            throw NetworkProviderError.noSuchContract(address)
        case .uninitialized where _initial == nil:
            throw NetworkProviderError.noSuchContract(address)
        case .uninitialized, .nonexistent:
            stateInitial = _initial
        default:
            break
        }

        let message = Message.external(to: address, with: stateInitial, body: body)
        return try .init(.init(Cell(message)))
    }
}

public extension Contract {
    /// Executes a contract method that takes no arguments and decodes its result.
    ///
    /// This convenience function builds a `Method` instance with an empty
    /// argument tuple, submits it to the network provider, then decodes the
    /// returned `Tuple` into the method's associated `Result` type.
    ///
    /// - Parameters:
    ///   - method: The `Method` type to execute. Must have `Arguments == Void`.
    ///   - networkProvider: The provider responsible for submitting the call.
    ///   - network: The blockchain network in which to execute (defaults to `.mainnet`).
    /// - Returns: The decoded result of the contract call.
    /// - Throws: Any error from encoding, network submission, or decoding.
    @inlinable @inline(__always)
    func run<T>(
        _ method: T.Type,
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws -> T.Result where T: Method, T.Arguments == Void {
        let method = T(rawValue: ())
        return try await method.decode(networkProvider.run(
            T.name,
            arguments: .init(rawValue: []),
            on: address,
            in: network
        ))
    }

    /// Executes a contract method with custom arguments and decodes its result.
    ///
    /// This function builds a `Method` instance from the provided arguments,
    /// submits it to the network provider, then decodes the returned `Tuple`
    /// into the method's associated `Result` type.
    ///
    /// - Parameters:
    ///   - method: The `Method` type to execute.
    ///   - arguments: The method-specific arguments to encode and send.
    ///   - networkProvider: The provider responsible for submitting the call.
    ///   - network: The blockchain network in which to execute (defaults to `.mainnet`).
    /// - Returns: The decoded result of the contract call.
    /// - Throws: Any error from encoding, network submission, or decoding.
    @inlinable @inline(__always)
    func run<T>(
        _ method: T.Type,
        arguments: T.Arguments,
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws -> T.Result where T: Method {
        let method = T(rawValue: arguments)
        return try await method.decode(networkProvider.run(
            T.name,
            arguments: method.encode(),
            on: address,
            in: network
        ))
    }

    /// Executes a contract method by its name and raw `Tuple` arguments,
    /// returning the raw `Tuple` result.
    ///
    /// Use this overload when you do not have a `Method` type available.
    ///
    /// - Parameters:
    ///   - method: The string name of the contract method to invoke.
    ///   - arguments: A raw `Tuple` of elements matching the method signature.
    ///   - networkProvider: The provider responsible for submitting the call.
    ///   - network: The blockchain network in which to execute (defaults to `.mainnet`).
    /// - Returns: The raw `Tuple` returned by the contract call.
    /// - Throws: Any error from network submission.
    @inlinable @inline(__always)
    func run(
        _ method: String,
        withArguments arguments: Tuple,
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws -> Tuple {
        try await networkProvider.run(method, arguments: arguments, on: address, in: network)
    }
}

// MARK: LosslessStringConvertible

extension Contract: LosslessStringConvertible {
    /// A textual form of the contract’s `address`.
    @inlinable @inline(__always)
    public var description: String { address.description }

    /// Initializes a `Contract` from a string by parsing it as an `InternalAddress`.
    /// Returns `nil` if the string is invalid.
    public init?(_ description: String) {
        guard let address = InternalAddress(description)
        else {
            return nil
        }
        self.init(address: address)
    }
}

// MARK: ExpressibleByStringLiteral

extension Contract: ExpressibleByStringLiteral {
    /// Initializes a `Contract` from a string literal, parsing it as an `InternalAddress`.
    /// If parsing fails, triggers `fatalError`.
    public init(stringLiteral value: StringLiteralType) {
        self.init(address: .init(stringLiteral: value))
    }
}

public extension InternalAddress {
    /// Creates an `InternalAddress` by deriving a 32-byte hash from
    /// the `StateInit` cell's representation hash, combined with a `Workchain`.
    /// This is commonly used when you have new contract code/data and want
    /// to produce a local address.
    ///
    /// - Parameters:
    ///   - workchain: The `Workchain` ID (usually `.basic`).
    ///   - stateInit: A `StateInit` struct that can be encoded into a cell.
    /// - Throws: Errors if encoding the `StateInit` fails (not expected in normal usage).
    @inlinable @inline(__always)
    init(workchain: Workchain = .basic, _ stateInit: StateInit) throws {
        try self.init(workchain, Cell(stateInit).representationHash)
    }
}
