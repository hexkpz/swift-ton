//
//  Created by Anton Spivak
//

import Foundation
import FundamentalsExtensions

// MARK: - WalletInformation

public struct WalletInformation {
    // MARK: Lifecycle

    init(name: String, image: URL, aboutURL: URL, tonDNSURL: URL?) {
        self.name = name
        self.image = image
        self.aboutURL = aboutURL
        self.tonDNSURL = tonDNSURL
    }

    // MARK: Public

    public let name: String
    public let image: URL
    public let aboutURL: URL
    public let tonDNSURL: URL?
}

// MARK: Codable

extension WalletInformation: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case image
        case aboutURL = "about_url"
        case tonDNSURL = "tondns"
    }
}

// MARK: Sendable

extension WalletInformation: Sendable {}

extension WalletInformation {
    init(from hostApplication: HostApplication) {
        self.init(
            name: hostApplication.name,
            image: hostApplication.iconURL,
            aboutURL: hostApplication.aboutURL,
            tonDNSURL: hostApplication.tonDNSURL
        )
    }
}
