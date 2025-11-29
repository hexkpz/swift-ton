//
//  Created by Anton Spivak
//

// MARK: - Jetton

public enum Jetton {}

// MARK: Jetton.Error

/// A namespace for Jetton-related contract types and utilities. Jettons are
/// fungible token standards on The Open Network (TON) blockchain, similar to
/// ERC-20/ERC-721 on Ethereum. This enum acts as a container for Jetton-specific
/// contract interfaces and error types.
extension Jetton {
    /// Errors that can occur when working with Jetton contracts, such as when
    /// decoding on-chain responses fails or returns unexpected data.
    enum Error: Swift.Error {
        /// Indicates the contract returned an unexpected or malformed response.
        /// - Parameter description: A descriptive message about the invalid response.
        case invalidResponse(String)
    }
}

// MARK: - Jetton.Error + LocalizedError

extension Jetton.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidResponse(description):
            "Invalid response: \(description)"
        }
    }
}
