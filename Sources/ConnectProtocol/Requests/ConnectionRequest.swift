//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - ConnectionRequest

public struct ConnectionRequest {
    // MARK: Lifecycle

    public init?(base64Encoded string: String) {
        guard let data = Data(base64Encoded: string),
              let request = try? JSONDecoder().decode(Self.self, from: data)
        else { return nil }
        self = request
    }

    init(webApplicationManifestURL: URL, verificationChallengePayload: String?) {
        self.webApplicationManifestURL = webApplicationManifestURL
        self.verificationChallengePayload = verificationChallengePayload
    }

    // MARK: Public

    public let webApplicationManifestURL: URL
    public let verificationChallengePayload: String?
}

// MARK: AnyWebApplicationRequest

extension ConnectionRequest: AnyWebApplicationRequest {
    public typealias Response = ConnectionEvent
    public typealias Error = ConnectionErrorEvent
}

// MARK: Codable

extension ConnectionRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case manifestURL = "manifestUrl"
        case items
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let items = try container.decode([Item].self, forKey: .items)
        guard !items.isEmpty
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Items must contain at least one item"
            ))
        }

        var verificationChallengePayload: String?
        for item in items {
            switch item {
            case .accountInformation:
                break
            case let .verifcationChallenge(payload):
                verificationChallengePayload = payload
            }
        }

        self.webApplicationManifestURL = try container.decode(URL.self, forKey: .manifestURL)
        self.verificationChallengePayload = verificationChallengePayload
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var items: [Item] = [.accountInformation]
        if let verificationChallengePayload {
            items.append(.verifcationChallenge(verificationChallengePayload))
        }

        try container.encode(webApplicationManifestURL, forKey: .manifestURL)
        try container.encode(items, forKey: .items)
    }
}

// MARK: Sendable

extension ConnectionRequest: Sendable {}

// MARK: ConnectionRequest.Item

extension ConnectionRequest {
    enum Item {
        case accountInformation
        case verifcationChallenge(String)
    }
}

// MARK: - ConnectionRequest.Item + Codable

extension ConnectionRequest.Item: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case payload
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        switch name {
        case "ton_addr":
            self = .accountInformation
        case "ton_proof":
            self = try .verifcationChallenge(container.decode(String.self, forKey: .payload))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.name,
                in: container,
                debugDescription: "Unsupported item named \(name)"
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .accountInformation:
            try container.encode("ton_addr", forKey: .name)
        case let .verifcationChallenge(payload):
            try container.encode("ton_proof", forKey: .name)
            try container.encode(payload, forKey: .payload)
        }
    }
}
