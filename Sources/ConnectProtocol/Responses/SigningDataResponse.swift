//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - SigningDataResponse

public struct SigningDataResponse: HostApplicationResponse {
    // MARK: Lifecycle

    public init(id: String, result: Result<Success, ConnectError>) {
        self.id = id
        self.result = result
    }

    // MARK: Public

    public var id: String
    public let result: Result<Success, ConnectError>
}

// MARK: Sendable

extension SigningDataResponse: Sendable {}

// MARK: SigningDataResponse.Success

public extension SigningDataResponse {
    struct Success {
        // MARK: Lifecycle

        public init(
            timestamp: UInt64,
            address: InternalAddress,
            domain: String,
            signature: Data,
            payload: SignDataPayload
        ) {
            self.timestamp = timestamp
            self.address = address
            self.domain = domain
            self.signature = signature
            self.payload = payload
        }

        // MARK: Public

        public let timestamp: UInt64
        public let address: InternalAddress
        public let domain: String
        public let signature: Data
        public let payload: SignDataPayload
    }
}

// MARK: - SigningDataResponse.Success + Sendable

extension SigningDataResponse.Success: Sendable {}

// MARK: - SigningDataResponse.Success + Codable

extension SigningDataResponse.Success: Codable {
    private enum CodginKeys: CodingKey {
        case timestamp
        case domain
        case address
        case signature
        case payload
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodginKeys.self)

        self.timestamp = try container.decode(UInt64.self, forKey: .timestamp)
        self.address = try container.decode(InternalAddress.self, forKey: .address)
        self.domain = try container.decode(String.self, forKey: .domain)
        self.signature = try container.decode(Data.self, forKey: .signature)
        self.payload = try container.decode(SignDataPayload.self, forKey: .payload)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodginKeys.self)

        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(address, forKey: .address)
        try container.encode(domain, forKey: .domain)
        try container.encode(signature, forKey: .signature)
        try container.encode(payload, forKey: .payload)
    }
}

// MARK: - SigningDataResponse.Error

public extension SigningDataResponse {
    struct Error: ConnectErrorConvertible, Sendable {
        // MARK: Lifecycle

        private init(code: ConnectError.Code, message: String?) {
            self.code = code
            self.message = message
        }

        // MARK: Public

        public let code: ConnectError.Code
        public let message: String?
    }
}

public extension SigningDataResponse.Error {
    static func unknown(
        _ message: String? = nil
    ) -> Self { .init(code: .unknown, message: message) }

    static func badRequest(
        _ message: String? = nil
    ) -> Self { .init(code: .badRequest, message: message) }

    static func unknownWebApplication(
        _ message: String? = nil
    ) -> Self { .init(code: .unknownWebApplication, message: message) }

    static func userDeclined(
        _ message: String? = nil
    ) -> Self { .init(code: .userDeclined, message: message) }

    static func unsupportedMethod(
        _ message: String? = nil
    ) -> Self { .init(code: .unsupportedMethod, message: message) }
}
