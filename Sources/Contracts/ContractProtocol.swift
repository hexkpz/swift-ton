//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - ContractProtocol

/// A generic protocol representing a high-level view of a TON smart contract.
/// Adopters must wrap a concrete `Contract` in `rawValue`, and also conform
/// to Swift’s `LosslessStringConvertible` and `ExpressibleByStringLiteral`
/// for convenient address-based initialization and display.
///
/// You can adopt this protocol to create strongly typed wrappers around
/// specific types of contracts (e.g., wallet contracts, NFT collections, etc.).
///
/// **Example**:
/// ```swift
/// struct MyContract: ContractProtocol {
///     public let rawValue: Contract
///
///     public init(rawValue: Contract) {
///         self.rawValue = rawValue
///     }
/// }
///
/// let address = InternalAddress("0:ABCDEF...")!
/// let myContract = MyContract(address: address)
/// print(myContract) // 0:ABCDEF...
/// ```
public protocol ContractProtocol:
    Sendable,
    LosslessStringConvertible,
    ExpressibleByStringLiteral,
    RawRepresentable where RawValue == Contract
{
    /// Required initializer to bridge between a custom type and the underlying `Contract`.
    init(rawValue: Contract)
}

public extension ContractProtocol {
    /// The `InternalAddress` of the underlying contract.
    ///
    /// **Note**: This is derived from `rawValue.address`.
    @inlinable @inline(__always)
    var address: InternalAddress { rawValue.address }

    /// The current on-chain balance of the contract as reported by `Contract.State`.
    ///
    /// **Note**: This is derived from `rawValue.balance` and is typically
    /// updated whenever you call `update(using:)`.
    @inlinable @inline(__always)
    var balance: CurrencyValue { rawValue.balance }

    /// The (optional) compiled smart contract code (`Cell`) if present.
    ///
    /// **Note**: This is derived from `rawValue.data` but only returns
    /// code if the contract is in an “active” state or was initialized with code.
    @inlinable @inline(__always)
    var code: Cell? { rawValue.data }

    /// The (optional) contract data cell, if any is present in the contract's state.
    ///
    /// **Note**: This is the same as `.code` in this context if the contract
    /// is not separated. For many contracts, the data is stored separately,
    /// and can be parsed using `CellDecodable`.
    @inlinable @inline(__always)
    var data: Cell? { rawValue.data }

    /// Initializes a `ContractProtocol`-conforming type from an `InternalAddress`,
    /// wrapping it in a basic `Contract` with unknown state. You can later update
    /// its state by calling `update(using:)`.
    ///
    /// - Parameter address: The `InternalAddress` identifying the contract on the TON network.
    @inlinable @inline(__always)
    init(address: InternalAddress) {
        self.init(rawValue: .init(address: address))
    }

    /// Fetches fresh state data from the network provider and updates the underlying
    /// `Contract`. This includes the current balance, code, and data cells.
    ///
    /// - Parameter provider: Any `NetworkProvider` capable of retrieving
    ///                       contract state from a TON-like blockchain.
    /// - Throws: If network communication fails or the contract address is invalid.
    /// - Note: On success, subsequent calls to `balance`, `code`, and `data`
    ///         may reflect the updated state.
    @inlinable @inline(__always)
    func update(
        using networkProvider: any NetworkProvider,
        in network: NetworkKind = .mainnet
    ) async throws {
        try await rawValue.update(using: networkProvider, in: network)
    }
}

// MARK: LosslessStringConvertible

public extension ContractProtocol {
    /// Converts the contract to a string representation (e.g., `"0:ABCDEF..."`),
    /// which is the underlying `InternalAddress` description.
    @inlinable @inline(__always)
    var description: String { address.description }

    /// Initializes the contract from a string that is expected to be a valid
    /// TON address (like `"0:ABCDEF..."`). If parsing fails, returns `nil`.
    ///
    /// - Parameter description: The string representation of a TON address.
    init?(_ description: String) {
        guard let address = Address(description)
        else {
            return nil
        }
        self.init(rawValue: .init(address: InternalAddress(address)))
    }
}

// MARK: ExpressibleByStringLiteral

public extension ContractProtocol {
    /// Allows creating a contract wrapper directly from a string literal
    /// containing a TON address. If the string is invalid, a runtime error
    /// will occur (`fatalError`).
    ///
    /// **Example**:
    /// ```swift
    /// let myContract: MyContract = "0:123456789ABCDEF..."
    /// ```
    /// - Parameter value: A string literal representing a TON address.
    init(stringLiteral value: Address.StringLiteralType) {
        let _address = Address(stringLiteral: value)
        self.init(rawValue: .init(address: InternalAddress(_address)))
    }
}
