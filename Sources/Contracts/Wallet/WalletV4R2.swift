//
//  Created by Anton Spivak
//

import Fundamentals
import Credentials

// MARK: - WalletV4R2

public struct WalletV4R2: ContractProtocol {
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
        b5ee9c72010214010002d4000114ff00f4a413f4bcf2c80b010201200203020148040504f8f28308d71820d31fd
        31fd31f02f823bbf264ed44d0d31fd31fd3fff404d15143baf2a15151baf2a205f901541064f910f2a3f80024a4
        c8cb1f5240cb1f5230cbff5210f400c9ed54f80f01d30721c0009f6c519320d74a96d307d402fb00e830e021c00
        1e30021c002e30001c0039130e30d03a4c8cb1f12cb1fcbff1011121302e6d001d0d3032171b0925f04e022d749
        c120925f04e002d31f218210706c7567bd22821064737472bdb0925f05e003fa403020fa4401c8ca07cbffc9d0e
        d44d0810140d721f404305c810108f40a6fa131b3925f07e005d33fc8258210706c7567ba923830e30d03821064
        737472ba925f06e30d06070201200809007801fa00f40430f8276f2230500aa121bef2e0508210706c7567831eb
        17080185004cb0526cf1658fa0219f400cb6917cb1f5260cb3f20c98040fb0006008a5004810108f45930ed44d0
        810140d720c801cf16f400c9ed540172b08e23821064737472831eb17080185005cb055003cf1623fa0213cb6ac
        b1fcb3fc98040fb00925f03e20201200a0b0059bd242b6f6a2684080a06b90fa0218470d4080847a4937d29910c
        e6903e9ff9837812801b7810148987159f31840201580c0d0011b8c97ed44d0d70b1f8003db29dfb51342040503
        5c87d010c00b23281f2fff274006040423d029be84c600201200e0f0019adce76a26840206b90eb85ffc00019af
        1df6a26840106b90eb858fc0006ed207fa00d4d422f90005c8ca0715cbffc9d077748018c8cb05cb0222cf16500
        5fa0214cb6b12ccccc973fb00c84014810108f451f2a7020070810108d718fa00d33fc8542047810108f451f2a7
        82106e6f746570748018c8cb05cb025006cf165004fa0214cb6a12cb1fcb3fc973fb0002006c810108d718fa00d
        33f305224810108f459f2a782106473747270748018c8cb05cb025005cf165003fa0213cb6acb1f12cb3fc973fb
        00000af400c9ed54
        """
    }
}

// MARK: WalletContract

extension WalletV4R2: WalletContract {
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

extension WalletV4R2: ContractABI.Data {
    public struct Data: Hashable, Sendable, CellCodable, WalletContractData {
        // MARK: Lifecycle

        @usableFromInline
        init(
            workchain: Workchain = .basic,
            publicKey: Foundation.Data,
            subwallet: UInt32? = nil,
            extensions: Set<InternalAddress> = []
        ) {
            self.seqno = 0
            if let subwallet {
                self.subwallet = subwallet
            } else {
                self.subwallet = WalletSubwallet(for: workchain)
            }
            self.publicKey = publicKey
            self.extensions = extensions
        }

        public init(from container: inout CellDecodingContainer) throws {
            self.seqno = try container.decode(UInt32.self)
            self.subwallet = try container.decode(UInt32.self)
            self.publicKey = try container.decode(byteWidth: 32)
            self.extensions = try container.decode(contentsOf: Set<InternalAddress>.self)
        }

        // MARK: Public

        public let seqno: UInt32
        public let subwallet: UInt32
        public let publicKey: Foundation.Data
        public let extensions: Set<InternalAddress>

        public func encode(to container: inout CellEncodingContainer) throws {
            try container.encode(seqno)
            try container.encode(subwallet)
            try container.encode(publicKey)
            try container.encode(contentsOf: extensions)
        }
    }
}

// MARK: ContractABI.ExternalMessages

extension WalletV4R2: ContractABI.ExternalMessages {
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
                UInt8(0) // op_code; simple_order
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

// MARK: - WalletV4R2.ExternalMessage + WalletContractExternalMessage

extension WalletV4R2.ExternalMessage: WalletContractExternalMessage {
    public static let maximumMessages: UInt = 4
}

// MARK: - WalletV4R2 + ContractABI.Methods

extension WalletV4R2: ContractABI.Methods {
    public struct MethodCollection: WalletContractMethodCollection {}
}
