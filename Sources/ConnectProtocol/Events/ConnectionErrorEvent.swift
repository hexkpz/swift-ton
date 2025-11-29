//
//  Created by Anton Spivak
//

// MARK: - ConnectionErrorEvent

public struct ConnectionErrorEvent {
    // MARK: Lifecycle

    private init(id: Int = -1, code: ConnectError.Code, message: String? = nil) {
        self.id = id
        self.error = .init(code, message: message)
    }

    // MARK: Public

    public let id: Int
    public let error: ConnectError
}

public extension ConnectionErrorEvent {
    static func unknown(
        id: Int = 0,
        message: String? = nil
    ) -> ConnectionErrorEvent {
        .init(id: id, code: .unknown, message: message)
    }

    static func badRequest(
        id: Int = 0,
        message: String? = nil
    ) -> ConnectionErrorEvent {
        .init(id: id, code: .badRequest, message: message)
    }

    static func webApplicationManifestNotFound(
        id: Int = 0,
        message: String? = nil
    ) -> ConnectionErrorEvent {
        .init(id: id, code: .webApplicationManifestNotFound, message: message)
    }

    static func invalidWebApplicationManifest(
        id: Int = 0,
        message: String? = nil
    ) -> ConnectionErrorEvent {
        .init(id: id, code: .invalidWebApplicationManifest, message: message)
    }

    static func unknownWebApplication(
        id: Int = 0,
        message: String? = nil
    ) -> ConnectionErrorEvent {
        .init(id: id, code: .unknownWebApplication, message: message)
    }

    static func userDeclined(
        id: Int = 0,
        message: String? = nil
    ) -> ConnectionErrorEvent {
        .init(id: id, code: .userDeclined, message: message)
    }
}

extension ConnectionErrorEvent {
    static let name = "connect_error"
}

// MARK: Sendable

extension ConnectionErrorEvent: Sendable {}

// MARK: Codable

extension ConnectionErrorEvent: Codable {
    public init(from decoder: any Decoder) throws {
        let event = try HostApplicationEvent<ConnectError>(from: decoder)
        guard event.name == Self.name
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Expected event name to be `\(Self.name)`"
            ))
        }

        self.id = event.id
        self.error = event.payload
    }

    public func encode(to encoder: any Encoder) throws {
        try HostApplicationEvent(
            id: id,
            name: Self.name,
            payload: error
        ).encode(to: encoder)
    }
}
