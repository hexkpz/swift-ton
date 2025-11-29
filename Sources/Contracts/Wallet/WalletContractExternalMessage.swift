//
//  Created by Anton Spivak
//

import Credentials
import Fundamentals

// MARK: - WalletContractExternalMessage

/// A protocol defining the minimal requirements for an external wallet message
/// in a TON wallet contract. Conforming types must specify a limit on how many
/// internal messages can be bundled together and implement static methods to
/// construct and sign such messages (e.g., transfer or custom payload).
///
/// Wallet contracts use this interface to serialize and sign outgoing messages
/// that carry one or more internal calls (transfers, method invocations, etc.).
public protocol WalletContractExternalMessage {
    /// The maximum number of internal messages that can be embedded
    /// within a single external wallet message. This limit is imposed by
    /// the smart contract’s logic to prevent oversized or overly complex
    /// transactions.
    static var maximumMessages: UInt { get }
}

// MARK: - WalletContractExternalMessageMaximumMessagesError

public struct WalletContractExternalMessageMaximumMessagesError {
    // MARK: Lifecycle

    init(maximumMessages: UInt) {
        self.maximumMessages = maximumMessages
    }

    // MARK: Public

    /// The allowed maximum number of internal messages.
    public let maximumMessages: UInt
}

// MARK: LocalizedError

extension WalletContractExternalMessageMaximumMessagesError: LocalizedError {
    public var errorDescription: String? {
        "Contract doesn't support more than \(maximumMessages) internal messages in external message."
    }
}

public extension WalletContractExternalMessage {
    /// Validates that the number of internal messages does not exceed the
    /// wallet contract’s `maximumMessages` limit. Throws an error if the
    /// count is too high.
    ///
    /// - Parameter messages: An array representing each internal message
    ///   descriptor (e.g., `(InternalMessageParameters, MessageRelaxed)`).
    /// - Throws: `WalletContractExternalMessageMaximumMessagesError`
    ///   if `messages.count > Self.maximumMessages`.
    static func checkMaximumMessages(_ messages: [Any]) throws {
        guard messages.count <= maximumMessages
        else {
            throw WalletContractExternalMessageMaximumMessagesError(
                maximumMessages: maximumMessages
            )
        }
    }
}

public extension Date {
    /// A default expiration time set to one minute (60 seconds) from now.
    /// Useful as a fallback when constructing messages without a user-provided
    /// expiration date.
    static var defaultEprirationDateSinceNow: Date {
        Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 60)
    }
}

public extension Optional where Wrapped == Date {
    /// Computes the effective expiration timestamp for an external message,
    /// clamping the result to the maximum representable `UInt32` value if necessary.
    ///
    /// - Parameter customDate: An optional custom expiration `Date`. If `nil`,
    ///   a default expiration time (one minute from now) is used.
    /// - Returns: A `UInt32` representing the Unix timestamp (seconds since 1970)
    ///            at which the message expires. Values exceeding `UInt32.max`
    ///            are clamped to `UInt32.max`.
    func effectiveEprirationDate() -> UInt32 {
        let date = self ?? .defaultEprirationDateSinceNow
        return UInt32(min(TimeInterval(UInt32.max), date.timeIntervalSince1970))
    }
}
