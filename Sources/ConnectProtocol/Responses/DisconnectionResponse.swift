//
//  Created by Anton Spivak
//

// MARK: - DisconnectionResponse

public struct DisconnectionResponse: HostApplicationResponse {
    // MARK: Lifecycle

    public init(id: String, result: Result<Success, ConnectError>) {
        self.id = id
        self.result = result
    }

    // MARK: Public

    public struct Success: Codable, Sendable {
        public init() {}
    }

    public var id: String
    public let result: Result<Success, ConnectError>
}

// MARK: Sendable

extension DisconnectionResponse: Sendable {}

// MARK: DisconnectionResponse.Error

public extension DisconnectionResponse {
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

public extension DisconnectionResponse.Error {
    static func unknown(
        _ message: String? = nil
    ) -> Self { .init(code: .unknown, message: message) }

    static func badRequest(
        _ message: String? = nil
    ) -> Self { .init(code: .badRequest, message: message) }

    static func webApplicationManifestNotFound(
        _ message: String? = nil
    ) -> Self { .init(code: .webApplicationManifestNotFound, message: message) }

    static func unsupportedMethod(
        _ message: String? = nil
    ) -> Self { .init(code: .unsupportedMethod, message: message) }
}
