//
//  Created by Anton Spivak
//

import Foundation
import FundamentalsExtensions

// MARK: - VerificationChallenge

public struct VerificationChallenge: Sendable, Hashable {
    // MARK: Lifecycle

    public init(
        timestamp: UInt64,
        domain: WebApplication.Domain,
        signature: Data,
        payload: String
    ) {
        self.timestamp = timestamp
        self.domain = domain
        self.signature = signature
        self.payload = payload
    }

    // MARK: Public

    public let timestamp: UInt64
    public let domain: WebApplication.Domain
    public let signature: Data
    public let payload: String
}

// MARK: Codable

extension VerificationChallenge: Codable {
    private enum CodginKeys: CodingKey {
        case timestamp
        case domain
        case signature
        case payload
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodginKeys.self)

        self.timestamp = try container.decode(UInt64.self, forKey: .timestamp)
        self.domain = try container.decode(WebApplication.Domain.self, forKey: .domain)
        self.signature = try container.decode(Data.self, forKey: .signature)
        self.payload = try container.decode(String.self, forKey: .payload)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodginKeys.self)

        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(domain, forKey: .domain)
        try container.encode(signature, forKey: .signature)
        try container.encode(payload, forKey: .payload)
    }
}
