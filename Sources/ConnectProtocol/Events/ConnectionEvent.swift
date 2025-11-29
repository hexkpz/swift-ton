//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - ConnectionEvent

public struct ConnectionEvent {
    // MARK: Lifecycle

    public init(
        id: Int = -1,
        deviceInformation: DeviceInformation,
        userWallet: UserWallet?,
        verificationChallenge: VerificationChallenge?
    ) {
        self.id = id
        self.deviceInformation = deviceInformation

        self.userWallet = userWallet
        self.verificationChallenge = verificationChallenge
    }

    // MARK: Public

    public let id: Int
    public let deviceInformation: DeviceInformation

    public let userWallet: UserWallet?
    public let verificationChallenge: VerificationChallenge?

    // MARK: Internal

    static let name = "connect"
}

// MARK: Sendable

extension ConnectionEvent: Sendable {}

// MARK: Codable

extension ConnectionEvent: Codable {
    private struct Payload: Codable {
        let items: [Item]
        let device: DeviceInformation
    }

    enum Item: Codable {
        case accountInformation(UserWallet)
        case verificationChallenge(VerificationChallenge)

        // MARK: Lifecycle

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decode(String.self, forKey: .name)
            switch name {
            case "ton_addr":
                self = try .accountInformation(UserWallet(from: decoder))
            case "ton_proof":
                let vc = try container.decode(VerificationChallenge.self, forKey: .proof)
                self = .verificationChallenge(vc)
            default:
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported item named `\(name)`"
                ))
            }
        }

        // MARK: Internal

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .accountInformation(userWallet):
                try container.encode("ton_addr", forKey: .name)
                try userWallet.encode(to: encoder)
            case let .verificationChallenge(verificationChallenge):
                try container.encode("ton_proof", forKey: .name)
                try container.encode(verificationChallenge, forKey: .proof)
            }
        }

        // MARK: Private

        private enum CodingKeys: String, CodingKey {
            case name
            case proof
        }
    }

    public init(from decoder: any Decoder) throws {
        let event = try HostApplicationEvent<Payload>(from: decoder)

        self.id = event.id
        self.deviceInformation = event.payload.device

        var userWallet: UserWallet?
        var verificationChallenge: VerificationChallenge?

        guard !event.payload.items.isEmpty
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Items must contain at least one item"
            ))
        }

        for item in event.payload.items {
            switch item {
            case let .accountInformation(userWallet_):
                userWallet = userWallet_
            case let .verificationChallenge(verificationChallenge_):
                verificationChallenge = verificationChallenge_
            }
        }

        self.userWallet = userWallet
        self.verificationChallenge = verificationChallenge
    }

    public func encode(to encoder: any Encoder) throws {
        var items: [Item] = []

        if let userWallet { items.append(.accountInformation(userWallet)) }
        if let verificationChallenge { items.append(.verificationChallenge(verificationChallenge)) }

        try HostApplicationEvent(
            id: id,
            name: Self.name,
            payload: Payload(items: items, device: deviceInformation)
        ).encode(to: encoder)
    }
}
