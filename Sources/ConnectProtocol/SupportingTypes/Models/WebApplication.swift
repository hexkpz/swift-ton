//
//  Created by Anton Spivak
//

import Foundation

// MARK: - WebApplication

public struct WebApplication {
    // MARK: Lifecycle

    public init(name: String, url: URL, icon: URL, terms: URL?, privacy: URL?) {
        self.name = name
        self.url = url
        self.icon = icon
        self.terms = terms
        self.privacy = privacy
    }

    // MARK: Public

    public let name: String

    public let url: URL
    public let icon: URL

    public let terms: URL?
    public let privacy: URL?
}

// MARK: Sendable

extension WebApplication: Sendable {}

public extension WebApplication {
    var domain: WebApplication.Domain { .init(self) }
    var authority: String { url.host ?? url.absoluteString }
}

// MARK: Codable

extension WebApplication: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case url
        case iconURL = "iconUrl"
        case termsOfUseURL = "termsOfUseUrl"
        case privacyPolicyURL = "privacyPolicyUrl"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL.self, forKey: .url)

        self.name = try container.decode(String.self, forKey: .name)
        self.url = url
        self.icon = try container.decode(URL.self, forKey: .iconURL)
        self.terms = try container.decodeIfPresent(URL.self, forKey: .termsOfUseURL)
        self.privacy = try container.decodeIfPresent(URL.self, forKey: .privacyPolicyURL)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(icon, forKey: .iconURL)
        try container.encodeIfPresent(terms, forKey: .termsOfUseURL)
    }
}
