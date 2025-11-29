//
//  Created by Anton Spivak
//

import Credentials
import Fundamentals

// MARK: - WalletContract

/// A protocol for a standard wallet contract that supports composing and sending
/// external messages (e.g., sending transactions), bridging `ContractProtocol`,
/// `ContractABI.Data`, `ContractABI.ExternalMessages`, and `ContractABI.Methods`.
///
/// You typically implement this protocol if your contract is a wallet that needs
/// to assemble and dispatch one or more internal calls in a single external
/// transaction. For example, after implementing this protocol you can call
/// `.send(...)` to build the TON message and `.execute(...)` to submit it
/// over a network provider.
///
/// **Example**:
/// ```swift
/// struct MyWallet: WalletContract {
///     // Conformance to ContractProtocol, Data, ExternalMessages, and Methods...
/// }
///
/// // Build and send a simple transfer:
/// let action = try myWallet.transfer(
///     to: someFriendlyAddress,
///     10,
///     signedBy: myCredentials
/// )
///
/// try await action.execute(using: myNetworkProvider)
/// ```
///
/// - Note: `Data`, `ExternalMessage`, and `MethodCollection` are associated types
///   that specialize the contract’s serialization and message-building logic.
public protocol WalletContract:
    ContractProtocol,
    ContractABI.Data,
    ContractABI.ExternalMessages,
    ContractABI.Methods
    where
    Data: WalletContractData,
    ExternalMessage: WalletContractExternalMessage,
    MethodCollection: WalletContractMethodCollection
{
    /// Composes a composite external message containing one or more internal calls,
    /// signed by the given credentials.
    ///
    /// - Parameters:
    ///   - internalMessages: An array of tuples, each containing:
    ///       1. `InternalMessageParameters` – parameters for the internal message
    ///          header (e.g., default state, forward fees).
    ///       2. `MessageRelaxed` – a relaxed message payload (body, value, bounce flag, etc.).
    ///   - expires: The optional UTC expiration `Date` after which the message becomes invalid.
    ///              If `nil`, a default expiration time (e.g., now + some interval) is used.
    ///   - credentials: Signing credentials that hold the Ed25519 private key to sign the payload.
    /// - Returns: A `Contract.ExecutableAction` representing the fully formed external
    ///            message ready for dispatch via `execute(using:)`.
    /// - Throws:
    ///   - `WalletContractExternalMessageMaximumMessagesError` if the number
    ///      of sub-messages exceeds the protocol’s `maximumMessages` limit.
    ///   - Any error in building or signing the message (e.g., serialization failures).
    func send(
        _ internalMessages: [(InternalMessageParameters, MessageRelaxed)],
        expires: Date?,
        signedBy credentials: Credentials
    ) throws -> Contract.ExecutableAction
}

public extension WalletContract {
    /// Builds a single-internal-message external transaction targeting another contract,
    /// using default internal message parameters and encoding the provided internal call.
    ///
    /// - Parameters:
    ///   - contract: A target contract conforming to `ContractProtocol` and `ContractABI.InternalMessages`.
    ///               Its `InternalMessage` type defines how to serialize the method call.
    ///   - internalMessage: A typed internal message payload (e.g., a method call) defined by `T.InternalMessage`.
    ///   - amount: The amount of tokens (in `CurrencyValue`) to attach to the internal call.
    ///             Defaults to `0.15` (units depend on the chain’s denomination).
    ///   - bouncing: A Boolean flag indicating whether the destination contract’s
    ///               bounce behavior is allowed. If `true`, the destination may
    ///               bounce the transfer on failure. Defaults to `true`.
    ///   - expires: The UTC expiration `Date` for the overall external transaction.
    ///              Defaults to `.defaultEprirationDateSinceNow`.
    ///   - credentials: Signing credentials that provide the Ed25519 private key.
    ///
    /// - Returns: A `Contract.ExecutableAction` representing a wallet message
    ///            with exactly one internal call. Use `execute(using:)` to send.
    /// - Throws:
    ///   - If constructing the external message or signing fails.
    ///
    /// **Example**:
    /// ```swift
    /// let transferAction = try myWallet.send(
    ///     to: someOtherContract,
    ///     .myMessage(param1, param2),
    ///     attachedTransferAmount: 1.0,
    ///     bouncing: false,
    ///     expires: Date().addingTimeInterval(120),
    ///     signedBy: myCredentials
    /// )
    ///
    /// try await transferAction.execute(using: myNetworkProvider)
    /// ```
    @inlinable @inline(__always)
    func send<T>(
        to contract: T,
        _ internalMessage: T.InternalMessage,
        attachedTransferAmount amount: CurrencyValue = 0.15,
        bouncing: Bool = true,
        expires: Date = .defaultEprirationDateSinceNow,
        signedBy credentials: Credentials
    ) throws -> Contract.ExecutableAction
        where
        T: ContractProtocol,
        T: ContractABI.InternalMessages
    {
        try send(
            [(.default, .internal(
                to: contract.address,
                value: amount,
                bounce: bouncing,
                stateInit: nil,
                body: Cell(internalMessage)
            ))],
            expires: expires,
            signedBy: credentials
        )
    }
}

public extension WalletContract {
    /// Builds a simple "transfer only" external message sending `Toncoins` to a friendly address
    /// without any custom payload.
    ///
    /// - Parameters:
    ///   - destination: A `FriendlyAddress` representing the target TON address.
    ///   - value: The `CurrencyValue` amount to transfer, `Toncoins`
    ///   - expires: The UTC expiration `Date` for the external message. Defaults to `.defaultEprirationDateSinceNow`.
    ///   - credentials: Signing credentials containing the Ed25519 key pair.
    ///
    /// - Returns: A `Contract.ExecutableAction` that sends exactly `value` tokens
    ///            to `destination` with no additional payload.
    /// - Throws: If message serialization or signing fails.
    @inlinable @inline(__always)
    func transfer(
        to destination: FriendlyAddress,
        _ value: CurrencyValue,
        expires: Date = .defaultEprirationDateSinceNow,
        signedBy credentials: Credentials
    ) throws -> Contract.ExecutableAction {
        try send(
            [(.default, .internal(
                to: .init(destination),
                value: value,
                bounce: destination.options.contains(.bounceable),
                stateInit: nil,
                body: Cell()
            ))],
            expires: expires,
            signedBy: credentials
        )
    }

    /// Builds a "transfer with custom binary payload" external message sending `Toncoins`
    /// to a friendly address with user-defined additional data.
    ///
    /// - Parameters:
    ///   - destination: A `FriendlyAddress` representing the target TON address.
    ///   - value: The `CurrencyValue` amount to transfer, `Toncoins`
    ///   - body: A preconstructed `Cell` containing arbitrary TL-B or BOC-encoded data.
    ///   - expires: The UTC expiration `Date` for the external message. Defaults to `.defaultEprirationDateSinceNow`.
    ///   - credentials: Signing credentials containing the Ed25519 key pair.
    ///
    /// - Returns: A `Contract.ExecutableAction` that sends exactly `value` tokens
    ///            plus the provided `body` payload.
    /// - Throws: If message serialization or signing fails.
    @inlinable @inline(__always)
    func transfer(
        to destination: FriendlyAddress,
        _ value: CurrencyValue,
        body: Cell,
        expires: Date = .defaultEprirationDateSinceNow,
        signedBy credentials: Credentials
    ) async throws -> Contract.ExecutableAction {
        try send(
            [(.default, .internal(
                to: .init(destination),
                value: value,
                bounce: destination.options.contains(.bounceable),
                stateInit: nil,
                body: body
            ))],
            expires: expires,
            signedBy: credentials
        )
    }

    /// Builds a "transfer with text comment" external message sending `Toncoins`
    /// to a friendly address with a UTF-8-encoded snake string comment.
    ///
    /// - Parameters:
    ///   - destination: A `FriendlyAddress` representing the target TON address.
    ///   - value: The `CurrencyValue` amount to transfer, `Toncoins`
    ///   - comment: A `String` to be encoded as a `SnakeEncodedString` and attached
    ///              as the message body. Useful for human-readable notes or memos.
    ///   - expires: The UTC expiration `Date` for the external message. Defaults to `.defaultEprirationDateSinceNow`.
    ///   - credentials: Signing credentials containing the Ed25519 key pair.
    ///
    /// - Returns: A `Contract.ExecutableAction` that sends exactly `value` tokens
    ///            plus a serialized comment payload.
    /// - Throws: If comment encoding, message serialization, or signing fails.
    @inlinable @inline(__always)
    func transfer(
        to destination: FriendlyAddress,
        _ value: CurrencyValue,
        comment: String,
        expires: Date = .defaultEprirationDateSinceNow,
        signedBy credentials: Credentials
    ) async throws -> Contract.ExecutableAction {
        try send(
            [(.default, .internal(
                to: .init(destination),
                value: value,
                bounce: destination.options.contains(.bounceable),
                stateInit: nil,
                body: Cell(SnakeEncodedString(comment))
            ))],
            expires: expires,
            signedBy: credentials
        )
    }
}
