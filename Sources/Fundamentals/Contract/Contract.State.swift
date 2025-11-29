//
//  Created by Anton Spivak
//

import Foundation
import BigInt

// MARK: - Contract.State

public extension Contract {
    /// Represents the in-memory state of a contract, including its balance,
    /// activity status, and optional metadata (like lastHash or lastLogicalTime).
    ///
    /// Typically retrieved or updated via a `NetworkProvider`. Once fetched,
    /// the `status` field indicates if the contract is `.uninitialized`, `.active` (with code/data),
    /// or `.frozen` (with a frozen state hash).
    ///
    /// **Example**:
    /// ```swift
    /// let state = Contract.State(
    ///     balance: 1000,
    ///     status: .active(code: someCodeCell, data: someDataCell)
    /// )
    /// print(state.balance)        // 1000
    /// print(state.status)         // .active(...)
    /// print(state.lastHash)       // nil (not set here)
    /// print(state.lastLogicalTime)// nil (not set here)
    /// ```
    struct State: Sendable, Hashable {
        // MARK: Lifecycle

        /// Initializes a `Contract.State` with a balance, status, and optional last-hash/logical-time metadata.
        ///
        /// - Parameters:
        ///   - balance: The contract's balance, typically updated after a network fetch.
        ///   - status: The contract’s current `Status` (uninitialized, active, or frozen).
        ///   - lastHash: An optional record of the last known block or transaction hash.
        ///   - lastLogicalTime: An optional record of the last logical time (LT) known on-chain.
        public init(
            balance: CurrencyValue,
            status: Status,
            lastHash: Data? = nil,
            lastLogicalTime: UInt64? = nil
        ) {
            self.balance = balance
            self.status = status
            self.lastHash = lastHash
            self.lastLogicalTime = lastLogicalTime
        }

        // MARK: Public

        /// The current balance known for this contract’s state.
        public let balance: CurrencyValue

        /// The activity status, indicating whether the contract is uninitialized,
        /// active (with code/data), or frozen.
        public let status: Status

        /// The last known block or transaction hash relevant to this state, if any.
        public let lastHash: Data?

        /// The last known logical time (LT) from on-chain data, if any.
        public let lastLogicalTime: UInt64?
    }
}

public extension Contract.State {
    @inlinable @inline(__always)
    static func unknown() -> Self {
        .init(balance: 0, status: .uninitialized, lastHash: nil, lastLogicalTime: nil)
    }
}

// MARK: - Contract.State.Status

public extension Contract.State {
    /// Represents the current lifecycle status of a contract account.
    ///
    /// - nonexistent: The contract code/data is not deployed or known on-chain.
    /// - uninitialized: The account exists with some metadata (balance, config),
    ///   but no deployed code or persistent data.
    /// - active: The account has deployed smart contract code and associated
    ///   persistent data, and can process transactions.
    /// - frozen: The account has been deactivated due to insufficient balance
    ///   for storage costs; only the frozen state hash is retained.
    enum Status: Sendable, Hashable {
        /// No account exists at this address; no transactions have been processed.
        case nonexistent

        /// The account has received funds or meta-transactions but has not yet
        /// been initialized with contract code and data.
        case uninitialized

        /// The account has deployed smart contract code and persistent data.
        ///
        /// - Parameters:
        ///   - code: A `Cell` containing the contract’s executable code.
        ///   - data: A `Cell` containing the contract’s persistent storage.
        case active(code: Cell, data: Cell)

        /// The account has been frozen, typically because its storage costs
        /// exceeded its balance. It cannot process transactions but retains
        /// a reference to its final state.
        ///
        /// - Parameter hash: A `Data` identifier for the frozen state.
        case frozen(hash: Data)
    }
}
