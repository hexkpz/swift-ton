//
//  Created by Anton Spivak
//

import Foundation

// MARK: - ConnectErrorConvertible

public protocol ConnectErrorConvertible: Error {
    var code: ConnectError.Code { get }
    var message: String? { get }
}

// MARK: - ConnectError

public struct ConnectError {
    // MARK: Lifecycle

    init<T>(_ errorConvertible: T) where T: ConnectErrorConvertible {
        self.init(errorConvertible.code, message: errorConvertible.message)
    }

    public init(_ code: Code, message: String? = nil) {
        self.code = code
        self.message = message ?? code.description
    }

    // MARK: Public

    public let code: Code
    public let message: String
}

// MARK: LocalizedError

extension ConnectError: LocalizedError {}

// MARK: Codable

extension ConnectError: Codable {
    private enum CodingKeys: String, CodingKey {
        case code
        case message
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let code = try container.decode(Int.self, forKey: .code)
        if let code = ConnectError.Code(rawValue: code) {
            self.code = code
        } else {
            self.code = .unknown
        }

        self.message = try container.decode(String.self, forKey: .message)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(code.rawValue, forKey: .code)
        try container.encode(message, forKey: .message)
    }
}

// MARK: ConnectError.Code

public extension ConnectError {
    enum Code: Int {
        case unknown = 0
        case badRequest = 1
        case webApplicationManifestNotFound = 2
        case invalidWebApplicationManifest = 3
        case unknownWebApplication = 100
        case userDeclined = 300
        case unsupportedMethod = 400
    }
}

// MARK: - ConnectError.Code + Sendable

extension ConnectError.Code: Sendable {}

// MARK: - ConnectError.Code + CustomStringConvertible

extension ConnectError.Code: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "Unknown error"
        case .badRequest: return "Bad request"
        case .webApplicationManifestNotFound: return "Web application manifest not found"
        case .invalidWebApplicationManifest: return "Invalid web application manifest"
        case .unknownWebApplication: return "Unknown web application"
        case .userDeclined: return "User declined request"
        case .unsupportedMethod: return "Unsupported method"
        }
    }
}
