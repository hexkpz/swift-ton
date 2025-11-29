//
//  Created by Anton Spivak
//

import Foundation

// MARK: - WebApplication.Domain

public extension WebApplication {
    struct Domain {
        // MARK: Lifecycle

        public init(_ rawValue: String) {
            self.length = UInt32(rawValue.utf8.count)
            self.value = rawValue
        }

        // MARK: Public

        public let length: UInt32
        public let value: String
    }
}

extension WebApplication.Domain {
    init(_ webApplication: WebApplication) {
        self.init(webApplication.authority)
    }
}

// MARK: - WebApplication.Domain + Codable

extension WebApplication.Domain: Codable {
    private enum CodingKeys: String, CodingKey {
        case length = "lengthBytes"
        case value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.length = try container.decode(UInt32.self, forKey: .length)
        self.value = try container.decode(String.self, forKey: .value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(length, forKey: .length)
        try container.encode(value, forKey: .value)
    }
}

// MARK: - WebApplication.Domain + Hashable

extension WebApplication.Domain: Hashable {}

// MARK: - WebApplication.Domain + Sendable

extension WebApplication.Domain: Sendable {}
