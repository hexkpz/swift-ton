//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - DNSContract.Error

public extension DNSContract {
    /// Errors that can occur when working with DNSContract domain resolution.
    enum Error: Swift.Error {
        /// Indicates the domain string contains invalid characters.
        case invalidDomainString(String)

        /// Indicates the contract returned an unexpected or malformed response.
        case invalidResponse(String)
    }
}

// MARK: - DNSContract.Error + LocalizedError

extension DNSContract.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidDomainString(domain):
            "Invalid domain \(domain); allowed ASCII characters are a-z, 0-9, '-'"
        case let .invalidResponse(description):
            "Invalid response: \(description)"
        }
    }
}
