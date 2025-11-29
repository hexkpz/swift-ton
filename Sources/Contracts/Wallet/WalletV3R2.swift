//
//  Created by Anton Spivak
//

import Fundamentals
import Credentials

// MARK: - WalletV3R2

public struct WalletV3R2: ContractProtocol {
    // MARK: Lifecycle

    @inlinable @inline(__always)
    public init(workchain: Workchain = .basic, credentials: Credentials) throws {
        try self.init(
            worckhain: workchain,
            code: Self.code.cells[0],
            data: .init(
                workchain: workchain,
                publicKey: credentials.rawValue.publicKey.rawRepresentation
            )
        )
    }

    @inlinable @inline(__always)
    public init(workchain: Workchain = .basic, publicKey: Foundation.Data) throws {
        try self.init(
            worckhain: workchain,
            code: Self.code.cells[0],
            data: .init(workchain: workchain, publicKey: publicKey)
        )
    }

    public init(rawValue: Contract) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public let rawValue: Contract

    // MARK: Internal

    @usableFromInline
    static var code: BOC {
        """
        b5ee9c724101010100710000deff0020dd2082014c97ba218201339cbab19f71b0ed44d0d31fd31f31d70bffe30
        4e0a4f2608308d71820d31fd31fd31ff82313bbf263ed44d0d31fd31fd3ffd15132baf2a15144baf2a204f90154
        1055f910f2a3f8009320d74a96d307d402fb00e8d101a4c8cb1fcb1fcbffc9ed5410bd6dad
        """
    }
}

// MARK: WalletContract

extension WalletV3R2: WalletContract {
    @inlinable @inline(__always)
    public func send(
        _ internalMessages: [(InternalMessageParameters, MessageRelaxed)],
        expires: Date?,
        signedBy credentials: Credentials
    ) throws -> Contract.ExecutableAction {
        guard let data = try data
        else {
            // No StateInit & no deployed contract
            throw NetworkProviderError.noSuchContract(address)
        }

        return try rawValue.receive(ExternalMessage(
            expires: expires,
            seqno: data.seqno,
            subwallet: data.subwallet,
            messages: internalMessages.map({ .init(parameters: $0.0, data: $0.1) }),
            credentials: credentials
        ))
    }
}

// MARK: ContractABI.Data

extension WalletV3R2: ContractABI.Data {
    public struct Data: Hashable, Sendable, CellCodable, WalletContractData {
        // MARK: Lifecycle

        @usableFromInline
        init(
            workchain: Workchain = .basic,
            subwallet: UInt32? = nil,
            publicKey: Foundation.Data
        ) {
            self.seqno = 0
            if let subwallet {
                self.subwallet = subwallet
            } else {
                self.subwallet = WalletSubwallet(for: workchain)
            }
            self.publicKey = publicKey
        }

        public init(from container: inout CellDecodingContainer) throws {
            self.seqno = try container.decode(UInt32.self)
            self.subwallet = try container.decode(UInt32.self)
            self.publicKey = try container.decode(byteWidth: 32)
        }

        // MARK: Public

        public let seqno: UInt32
        public let subwallet: UInt32
        public let publicKey: Foundation.Data

        public func encode(to container: inout CellEncodingContainer) throws {
            try container.encode(seqno)
            try container.encode(subwallet)
            try container.encode(publicKey)
        }
    }
}

// MARK: ContractABI.ExternalMessages

extension WalletV3R2: ContractABI.ExternalMessages {
    public struct ExternalMessage: CellEncodable {
        // MARK: Lifecycle

        @usableFromInline
        init(
            expires: Date?,
            seqno: UInt32,
            subwallet: UInt32,
            messages: [WalletOutboundMessage],
            credentials: Credentials
        ) throws {
            try ExternalMessage.checkMaximumMessages(messages)

            self.expires = expires
            self.seqno = seqno
            self.subwallet = subwallet
            self.messages = messages
            self.credentials = credentials
        }

        // MARK: Public

        public func encode(to container: inout CellEncodingContainer) throws {
            let body = try Cell {
                subwallet // wallet_id
                if seqno > 0 {
                    expires.effectiveEprirationDate() // valid_until
                } else {
                    UInt32.max // valid_until
                }
                seqno // seqno
                for message in messages {
                    message.parameters // send_mode
                    message.data // internal message
                }
            }

            try WalletSignedMessage(
                signature: credentials.rawValue.signature(for: body.representationHash),
                body: body
            ).encode(to: &container)
        }

        // MARK: Fileprivate

        fileprivate let expires: Date?
        fileprivate let seqno: UInt32
        fileprivate let subwallet: UInt32
        fileprivate let messages: [WalletOutboundMessage]
        fileprivate let credentials: Credentials
    }
}

// MARK: - WalletV3R2.ExternalMessage + WalletContractExternalMessage

extension WalletV3R2.ExternalMessage: WalletContractExternalMessage {
    public static let maximumMessages: UInt = 4
}

// MARK: - WalletV3R2 + ContractABI.Methods

extension WalletV3R2: ContractABI.Methods {
    public struct MethodCollection: WalletContractMethodCollection {}
}
