//
//  Created by Anton Spivak
//

import Foundation
import FundamentalsExtensions

// MARK: - HostApplication

public struct HostApplication {
    // MARK: Lifecycle

    public init(
        name: String,
        version: String,
        iconURL: URL,
        aboutURL: URL,
        tonDNSURL: URL?,
        platform: Platform,
        features: [Feature]
    ) {
        self.name = name
        self.version = version
        self.iconURL = iconURL
        self.aboutURL = aboutURL
        self.tonDNSURL = tonDNSURL
        self.platform = platform
        self.features = features
    }

    // MARK: Public

    public let name: String
    public let version: String

    public let iconURL: URL
    public let aboutURL: URL

    public let tonDNSURL: URL?

    public let platform: Platform
    public let features: [Feature]
}

public extension HostApplication {
    var walletInformation: WalletInformation { .init(from: self) }
    var deviceInformation: DeviceInformation { .init(from: self) }
}

// MARK: Sendable

extension HostApplication: Sendable {}

// MARK: HostApplication.Platform

public extension HostApplication {
    enum Platform: String {
        case iphone
        case ipad
        case android
        case windows
        case mac
        case linux
    }
}

// MARK: - HostApplication.Platform + Codable

extension HostApplication.Platform: Codable {}

// MARK: - HostApplication.Platform + Sendable

extension HostApplication.Platform: Sendable {}

// MARK: - HostApplication.Feature

public extension HostApplication {
    enum Feature {
        case sendTransaction(maximumMessages: Int, isExtraCurrencySupported: Bool)
        case signData(supportedTypes: Set<SingDataType>)
    }
}

// MARK: - HostApplication.Feature + Sendable

extension HostApplication.Feature: Sendable {}

// MARK: - HostApplication.Feature + Codable

extension HostApplication.Feature: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case maximumMessages = "maxMessages"
        case isExtraCurrencySupported = "extraCurrencySupported"
        case supportedTypes = "types"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        switch name {
        case "SendTransaction":
            let iecs = try container.decodeIfPresent(Bool.self, forKey: .isExtraCurrencySupported)
            self = try .sendTransaction(
                maximumMessages: container.decode(Int.self, forKey: .maximumMessages),
                isExtraCurrencySupported: iecs ?? false
            )
        case "SignData":
            let types = try container.decode([SingDataType].self, forKey: .supportedTypes)
            self = .signData(supportedTypes: Set(types))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.name,
                in: container,
                debugDescription: "Unsupported feature named \(name)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .sendTransaction(maximumMessages, isExtraCurrencySupported):
            try container.encode("SendTransaction", forKey: .name)
            try container.encode(maximumMessages, forKey: .maximumMessages)
            try container.encode(isExtraCurrencySupported, forKey: .isExtraCurrencySupported)
        case let .signData(supportedTypes):
            try container.encode("SignData", forKey: .name)
            try container.encode(Array(supportedTypes), forKey: .supportedTypes)
        }
    }
}

// MARK: - HostApplication.Feature.SingDataType

public extension HostApplication.Feature {
    enum SingDataType: String {
        case text
        case binary
        case cell
    }
}

// MARK: - HostApplication.Feature.SingDataType + Hashable

extension HostApplication.Feature.SingDataType: Hashable {}

// MARK: - HostApplication.Feature.SingDataType + Sendable

extension HostApplication.Feature.SingDataType: Sendable {}

// MARK: - HostApplication.Feature.SingDataType + Codable

extension HostApplication.Feature.SingDataType: Codable {}
