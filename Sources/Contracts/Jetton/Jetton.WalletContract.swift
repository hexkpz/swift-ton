//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - Jetton.WalletContract

public extension Jetton {
    /// A high-level wrapper for a Jetton wallet contract. This type is obtained
    /// by calling `MinterContract.wallet(for:using:in:)` or by directly
    /// initializing with a raw `Contract` instance.
    struct WalletContract: ContractProtocol {
        // MARK: Lifecycle

        /// Initializes a Jetton wallet by querying the minter contract. This returns
        /// a fully initialized `WalletContract` pointing to the on-chain wallet address.
        ///
        /// - Parameters:
        ///   - minter: The parent `MinterContract` that spawned this wallet.
        ///   - address: The user’s `InternalAddress` to derive the Jetton wallet.
        ///   - networkProvider: Provider used to query the blockchain.
        ///   - network: The target network (e.g., `.mainnet`). Defaults to `.mainnet`.
        /// - Returns: A `WalletContract` instance representing the on-chain wallet.
        /// - Throws: Any error from `minter.wallet(...)`.
        public init(
            minter: MinterContract,
            for address: InternalAddress,
            using networkProvider: any NetworkProvider,
            in network: NetworkKind = .mainnet
        ) async throws {
            self = try await minter.wallet(for: address, using: networkProvider, in: network)
        }

        public init(rawValue: Contract) {
            self.rawValue = rawValue
        }

        // MARK: Public

        public let rawValue: Contract

        public func data(
            using networkProvider: any NetworkProvider,
            in network: NetworkKind = .mainnet
        ) async throws -> GetWalletData.Response {
            try await execute(
                \.getWalletData,
                arguments: (),
                using: networkProvider,
                in: network
            )
        }
    }
}

// MARK: - Jetton.WalletContract + ContractABI.InternalMessages

extension Jetton.WalletContract: ContractABI.InternalMessages {
    /// Defines the set of internal messages (calls) that can be sent to a Jetton wallet.
    /// Examples include transferring tokens or burning (destroying) them.
    public enum InternalMessage: CellEncodable {
        /// Represents a `transfer` message, which moves Jetton tokens from this wallet
        /// to another user’s wallet or address.
        case transfer(Transfer)

        /// Represents a `burn` message, which destroys Jetton tokens and typically
        /// sends the resulting coins back to the minter or another designated address.
        case burn(Burn)

        // MARK: Public

        /// Creates a `transfer` internal message with the minimum required fields:
        ///
        /// - Parameters:
        ///   - userWalletAddress: The address of the recipient’s Jetton wallet.
        ///   - amount`: The number of Jetton tokens to transfer.
        ///   - excessesResponseAddress`: The `InternalAddress` to which any excess funds
        ///     should be returned if the operation fails or leftover funds exist.
        ///
        /// The other fields (e.g., query_id, forward amounts) use default values.
        public static func transfer(
            to userWalletAddress: InternalAddress,
            amount: CurrencyValue,
            excessesResponseAddress: InternalAddress
        ) -> Self {
            .transfer(.init(
                query: nil,
                amount: amount,
                userWalletAddress: userWalletAddress,
                userWalletAddressForwardAmount: .init(rawValue: 1),
                userWalletAddressForwardPayload: nil,
                excessesResponseAddress: excessesResponseAddress,
                additionalPayload: nil
            ))
        }

        /// Creates a `transfer` message with a custom payload `Cell` appended.
        ///
        /// - Parameters:
        ///   - userWalletAddress: The Jetton wallet address of the recipient.
        ///   - amount: The number of Jetton tokens to transfer.
        ///   - payload: A `Cell` containing arbitrary TL-B or BOC-encoded data to send.
        ///   - excessesResponseAddress: The `InternalAddress` to which any excess funds
        ///     should be returned if the operation fails or leftover funds exist.
        public static func transfer(
            to userWalletAddress: InternalAddress,
            amount: CurrencyValue,
            payload: Cell?,
            excessesResponseAddress: InternalAddress
        ) -> Self {
            .transfer(.init(
                query: nil,
                amount: amount,
                userWalletAddress: userWalletAddress,
                userWalletAddressForwardAmount: .init(rawValue: 1),
                userWalletAddressForwardPayload: payload,
                excessesResponseAddress: excessesResponseAddress,
                additionalPayload: nil
            ))
        }

        /// Creates a `transfer` message with an optional text comment, encoded as a
        /// `SnakeEncodedString` in the TL-B cell.
        ///
        /// - Parameters:
        ///   - userWalletAddress: The Jetton wallet address of the recipient.
        ///   - amount: The number of Jetton tokens to transfer.
        ///   - comment: A human-readable `String` memo or note for the transfer.
        ///   - excessesResponseAddress: The `InternalAddress` to which any excess funds
        ///     should be returned if the operation fails or leftover funds exist.
        /// - Throws: Any error from `Cell(SnakeEncodedString(comment))` if encoding fails.
        public static func transfer(
            to userWalletAddress: InternalAddress,
            amount: CurrencyValue,
            comment: String?,
            excessesResponseAddress: InternalAddress
        ) throws -> Self {
            try .transfer(.init(
                query: nil,
                amount: amount,
                userWalletAddress: userWalletAddress,
                userWalletAddressForwardAmount: .init(rawValue: 1),
                userWalletAddressForwardPayload: {
                    if let comment {
                        try Cell(SnakeEncodedString(comment))
                    } else {
                        nil
                    }
                }(),
                excessesResponseAddress: excessesResponseAddress,
                additionalPayload: nil
            ))
        }

        public func encode(to container: inout CellEncodingContainer) throws {
            switch self {
            case let .transfer(value):
                try value.encode(to: &container)
            case let .burn(value):
                try value.encode(to: &container)
            }
        }
    }
}

// MARK: - Jetton.WalletContract.InternalMessage.Transfer

public extension Jetton.WalletContract.InternalMessage {
    /// ```
    /// transfer#0f8a7ea5
    ///     query_id:uint64 amount:(VarUInteger 16)
    ///     destination:MsgAddress
    ///     response_destination:MsgAddress
    ///     custom_payload:(Maybe ^Cell)
    ///     forward_ton_amount:(VarUInteger 16)
    ///     forward_payload:(Either Cell ^Cell)
    ///   = InternalMsgBody;
    /// ```
    ///
    /// Jetton transfer operation as defined in the Jetton standard (TEP-0074).
    /// This message moves `amount` Jetton tokens from the sender’s wallet to the
    /// `userWalletAddress`, optionally forwarding a payload or comment.
    ///
    /// https://github.com/ton-blockchain/TEPs/blob/master/text/0074-jettons-standard.md#1-transfer
    struct Transfer: CellEncodable {
        // MARK: Lifecycle

        /// Initializes a Jetton `Transfer` message with all necessary data.
        ///
        /// - Parameters:
        ///   - query: Optional 64-bit query ID (default is current Unix timestamp).
        ///   - amount: The `CurrencyValue` number of Jetton tokens to transfer.
        ///   - userWalletAddress: The `InternalAddress` of the recipient’s Jetton wallet.
        ///   - userWalletAddressForwardAmount: The `CurrencyValue` to forward to the
        ///     recipient’s wallet for covering forwarding fees (commonly 1 ton).
        ///   - userWalletAddressForwardPayload: Optional `Cell` payload to forward to the
        ///     recipient (e.g., a comment encoded in Snake format).
        ///   - excessesResponseAddress: The `InternalAddress` to which any excess funds
        ///     should be returned if the operation fails or leftover funds exist.
        ///   - additionalPayload: Optional additional `Cell` containing arbitrary data (jetton internal logic puproses).
        public init(
            query: UInt64? = nil,
            amount: CurrencyValue,
            userWalletAddress: InternalAddress,
            userWalletAddressForwardAmount: CurrencyValue,
            userWalletAddressForwardPayload: Cell?,
            excessesResponseAddress: InternalAddress,
            additionalPayload: Cell?
        ) {
            self.query = query ?? UInt64(Date().timeIntervalSince1970)
            self.amount = amount
            self.userWalletAddress = userWalletAddress
            self.userWalletAddressForwardAmount = userWalletAddressForwardAmount
            self.userWalletAddressForwardPayload = userWalletAddressForwardPayload
            self.excessesResponseAddress = excessesResponseAddress
            self.additionalPayload = additionalPayload
        }

        // MARK: Public

        /// The TL-B opcode for the Jetton `transfer` message (0x0F8A_7EA5).
        public static let opcode: UInt32 = 0x0F8A_7EA5

        /// A unique 64-bit identifier for this message. Defaults to the current Unix timestamp.
        public let query: UInt64

        /// Number of Jetton tokens to transfer.
        public let amount: CurrencyValue

        /// The recipient’s (jetton owner) wallet address (TL-B `MsgAddress`).
        public let userWalletAddress: InternalAddress

        /// Amount of TON (in varuint16) forwarded to the recipient to cover transaction fees.
        public let userWalletAddressForwardAmount: CurrencyValue

        /// Optional payload to send along with the forwarded TON amount.
        public let userWalletAddressForwardPayload: Cell?

        public let excessesResponseAddress: InternalAddress

        /// Optional additional data appended to the transfer (jetton internal logic puproses).
        public let additionalPayload: Cell?

        public func encode(to container: inout CellEncodingContainer) throws {
            try container.encode(Self.opcode)
            try container.encode(query)
            try container.encode(amount)
            try container.encode(userWalletAddress)
            try container.encode(excessesResponseAddress)
            try container.encodeIfPresent(additionalPayload)
            try container.encode(userWalletAddressForwardAmount)
            try container.encodeIfPresent(userWalletAddressForwardPayload)
        }
    }
}

// MARK: - Jetton.WalletContract.InternalMessage.Burn

public extension Jetton.WalletContract.InternalMessage {
    /// ```
    /// burn#595f07bc
    ///     query_id:uint64
    ///     amount:(VarUInteger 16)
    ///     response_destination:MsgAddress
    ///     custom_payload:(Maybe ^Cell)
    ///   = InternalMsgBody;
    /// ```
    /// Jetton burn operation as defined in the Jetton standard (TEP-0074).
    /// This message destroys `amount` Jetton tokens from the sender’s wallet
    /// and refunds the underlying TON to the `excessesResponseAddress`.
    ///
    /// https://github.com/ton-blockchain/TEPs/blob/master/text/0074-jettons-standard.md#2-burn
    struct Burn: CellEncodable {
        // MARK: Lifecycle

        /// Initializes a Jetton `Burn` message with all necessary data.
        ///
        /// - Parameters:
        ///   - query: Optional 64-bit query ID (default is current Unix timestamp).
        ///   - amount: The `CurrencyValue` number of Jetton tokens to burn.
        ///   - excessesResponseAddress: The `InternalAddress` to which the refunded
        ///     TON should be sent after burning.
        ///   - additionalPayload: Optional `Cell` containing arbitrary data (jetton internal logic puproses).
        public init(
            query: UInt64? = nil,
            amount: CurrencyValue,
            excessesResponseAddress: InternalAddress,
            additionalPayload: Cell?
        ) {
            self.query = query ?? UInt64(Date().timeIntervalSince1970)
            self.amount = amount
            self.excessesResponseAddress = excessesResponseAddress
            self.additionalPayload = additionalPayload
        }

        // MARK: Public

        /// The TL-B opcode for the Jetton `burn` message (0x595F_07BC).
        public static let opcode: UInt32 = 0x595F_07BC

        /// A unique 64-bit identifier for this message. Defaults to the current Unix timestamp.
        public let query: UInt64

        /// Number of Jetton tokens to burn.
        public let amount: CurrencyValue

        /// The address to which any refunded TON should be returned after burning.
        public let excessesResponseAddress: InternalAddress

        /// Optional additional data appended to the burn message (jetton internal logic puproses).
        public let additionalPayload: Cell?

        public func encode(to container: inout CellEncodingContainer) throws {
            try container.encode(Self.opcode)
            try container.encode(query)
            try container.encode(amount)
            try container.encode(excessesResponseAddress)
            try container.encodeIfPresent(additionalPayload)
        }
    }
}

// MARK: - Jetton.WalletContract + ContractABI.Methods

extension Jetton.WalletContract: ContractABI.Methods {
    /// A collection of on-chain methods available for the Jetton wallet contract.
    public struct MethodCollection {
        /// The `get_wallet_address` method type, used to retrieve a user’s Jetton wallet address.
        public var getWalletData: GetWalletData.Type { GetWalletData.self }
    }
}

// MARK: - Jetton.WalletContract.GetWalletData

extension Jetton.WalletContract {
    /// A `Contract.Method` implementation for the `get_wallet_data` call.
    open class GetWalletData: Contract.Method {
        // MARK: Lifecycle

        public init() {
            self.rawValue = ()
        }

        public required init(rawValue: RawValue) {
            self.rawValue = rawValue
        }

        // MARK: Open

        open class var name: String { "get_wallet_data" }

        /// Decodes the returned `Tuple` from the blockchain call and extracts the
        /// Jetton wallet address as an `Response`.
        ///
        /// - Parameter tuple: The raw `Tuple` returned by the network provider.
        /// - Returns: An `(balance, owner, minter, code)` representing Jetton walle data.
        /// - Throws:
        ///   - `Jetton.Error.invalidResponse` if the tuple is empty or its first element
        ///     cannot be decoded to a `Response`.
        open func decode(_ tuple: Tuple) throws -> Response {
            guard tuple.rawValue.count == 4,
                  case let Tuple.Element.number(balance) = tuple.rawValue[0],
                  case let Tuple.Element.cell(owner) = tuple.rawValue[1],
                  case let Tuple.Element.cell(minter) = tuple.rawValue[2],
                  case let Tuple.Element.cell(code) = tuple.rawValue[3]
            else { throw Jetton.Error.invalidResponse("Invalid response") }
            return try (
                CurrencyValue(rawValue: BigUInt(balance)),
                owner.decode({ try $0.decode(InternalAddress.self) }),
                minter.decode({ try $0.decode(InternalAddress.self) }),
                code,
            )
        }

        // MARK: Public

        public typealias RawValue = Void
        public typealias Response = (
            balance: CurrencyValue,
            owner: InternalAddress,
            minter: InternalAddress,
            code: Cell
        )

        public let rawValue: RawValue
    }
}
