//
//  Created by Anton Spivak
//

import Fundamentals
import Credentials

// MARK: - WalletV5R1

public struct WalletV5R1: ContractProtocol {
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

    /// https://github.com/ton-blockchain/wallet-contract-v5/blob/88557ebc33047a95207f6e47ac8aadb102dff744/build/wallet_v5.compiled.json
    @usableFromInline
    static var code: BOC {
        """
        b5ee9c7241021401000281000114ff00f4a413f4bcf2c80b01020120020d020148030402dcd020d749c120915b8
        f6320d70b1f2082106578746ebd21821073696e74bdb0925f03e082106578746eba8eb48020d72101d074d721fa
        4030fa44f828fa443058bd915be0ed44d0810141d721f4058307f40e6fa1319130e18040d721707fdb3ce03120d
        749810280b99130e070e2100f020120050c020120060902016e07080019adce76a2684020eb90eb85ffc00019af
        1df6a2684010eb90eb858fc00201480a0b0017b325fb51341c75c875c2c7e00011b262fb513435c280200019be5
        f0f6a2684080a0eb90fa02c0102f20e011e20d70b1f82107369676ebaf2e08a7f0f01e68ef0eda2edfb218308d7
        22028308d723208020d721d31fd31fd31fed44d0d200d31f20d31fd3ffd70a000af90140ccf9109a28945f0adb3
        1e1f2c087df02b35007b0f2d0845125baf2e0855036baf2e086f823bbf2d0882292f800de01a47fc8ca00cb1f01
        cf16c9ed542092f80fde70db3cd81003f6eda2edfb02f404216e926c218e4c0221d73930709421c700b38e2d01d
        72820761e436c20d749c008f2e09320d74ac002f2e09320d71d06c712c2005230b0f2d089d74cd7393001a4e86c
        128407bbf2e093d74ac000f2e093ed55e2d20001c000915be0ebd72c08142091709601d72c081c12e25210b1e30
        f20d74a111213009601fa4001fa44f828fa443058baf2e091ed44d0810141d718f405049d7fc8ca0040048307f4
        53f2e08b8e14038307f45bf2e08c22d70a00216e01b3b0f2d090e2c85003cf1612f400c9ed54007230d72c08248
        e2d21f2e092d200ed44d0d2005113baf2d08f54503091319c01810140d721d70a00f2e08ee2c8ca0058cf16c9ed
        5493f2c08de20010935bdb31e1d74cd0b4d6c35e
        """
    }
}

// MARK: WalletContract

extension WalletV5R1: WalletContract {
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
            identifier: data.identifier,
            messages: internalMessages.map({ .init(parameters: $0.0, data: $0.1) }),
            credentials: credentials
        ))
    }
}

// MARK: ContractABI.Data

extension WalletV5R1: ContractABI.Data {
    public struct Data: Hashable, Sendable, CellCodable, WalletContractData {
        // MARK: Lifecycle

        @usableFromInline
        init(
            workchain: Workchain = .basic,
            isSignatureAuthenticationAllowed: Bool = true,
            publicKey: Foundation.Data,
            plugins: Set<InternalAddress> = []
        ) {
            self.isSignatureAuthenticationAllowed = isSignatureAuthenticationAllowed
            self.seqno = 0
            self.identifier = .client(
                network: .mainnet,
                workchain: workchain,
                version: .v5r1,
                subwalletID: 0
            )
            self.publicKey = publicKey
            self.extensions = plugins
        }

        public init(from container: inout CellDecodingContainer) throws {
            self.isSignatureAuthenticationAllowed = try container.decode(Bool.self)
            self.seqno = try container.decode(UInt32.self)
            self.identifier = try container.decode(WalletIdentifier.self)
            self.publicKey = try container.decode(byteWidth: 32)
            self.extensions = try container.decode(contentsOf: Set<InternalAddress>.self)
        }

        // MARK: Public

        public let isSignatureAuthenticationAllowed: Bool
        public let identifier: WalletIdentifier
        public let seqno: UInt32
        public let publicKey: Foundation.Data
        public let extensions: Set<InternalAddress>

        public func encode(to container: inout CellEncodingContainer) throws {
            try container.encode(isSignatureAuthenticationAllowed)
            try container.encode(seqno)
            try container.encode(identifier)
            try container.encode(publicKey)
            try container.encode(contentsOf: extensions)
        }
    }
}

// MARK: ContractABI.ExternalMessages

extension WalletV5R1: ContractABI.ExternalMessages {
    public struct ExternalMessage: CellEncodable {
        // MARK: Lifecycle

        @usableFromInline
        init(
            expires: Date?,
            seqno: UInt32,
            identifier: WalletIdentifier,
            messages: [WalletOutboundMessage],
            credentials: Credentials
        ) throws {
            try ExternalMessage.checkMaximumMessages(messages)

            self.expires = expires
            self.seqno = seqno
            self.identifier = identifier
            self.messages = messages
            self.credentials = credentials
        }

        // MARK: Public

        public func encode(to container: inout CellEncodingContainer) throws {
            let untilDate = effectiveEprirationDate(with: expires)
            let body = try Cell {
                UInt32(0x7369_676E) // op_code; external message
                identifier // wallet_id
                if seqno > 0 {
                    untilDate // valid_until
                } else {
                    UInt32.max // valid_until
                }
                seqno // seqno
                try CellComponent(ifPresent: encodeMessageActions())
                false
            }

            try WalletSignedMessage(
                signature: credentials.rawValue.signature(for: body.representationHash),
                body: body,
                position: .trailing
            ).encode(to: &container)
        }

        // MARK: Fileprivate

        fileprivate let expires: Date?
        fileprivate let seqno: UInt32
        fileprivate let identifier: WalletIdentifier
        fileprivate let messages: [WalletOutboundMessage]
        fileprivate let credentials: Credentials

        // MARK: Private

        private func encodeMessageActions() throws -> Cell? {
            var lastestCell = try Cell {}
            for message in messages {
                // Actions of external messages must have +2 in the SendMode
                var flags = message.parameters.flags
                flags.insert(.ignoreErrors)

                lastestCell = try Cell {
                    UInt32(0x0EC3_C86D) // op_code; out_action_send_msg_tag
                    InternalMessageParameters(
                        mode: message.parameters.mode,
                        flags: flags
                    ) // send_mode
                    lastestCell
                    message.data // internal message
                }
            }
            return lastestCell
        }
    }
}

// MARK: - WalletV5R1.ExternalMessage + WalletContractExternalMessage

extension WalletV5R1.ExternalMessage: WalletContractExternalMessage {
    public static let maximumMessages: UInt = 255
}

// MARK: - WalletV5R1 + ContractABI.Methods

extension WalletV5R1: ContractABI.Methods {
    public struct MethodCollection: WalletContractMethodCollection {}
}
