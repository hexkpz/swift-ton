//
//  Created by Anton Spivak
//

// MARK: - AnyEvent

public enum AnyEvent {
    case connection(ConnectionEvent)
    case connectionError(ConnectionErrorEvent)
    case disconnection(DisconnectionEvent)
}

// MARK: Sendable

extension AnyEvent: Sendable {}

// MARK: Codable

extension AnyEvent: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        switch name {
        case ConnectionEvent.name:
            self = try .connection(.init(from: decoder))
        case ConnectionErrorEvent.name:
            self = try .connectionError(.init(from: decoder))
        case DisconnectionEvent.name:
            self = try .disconnection(.init(from: decoder))
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unsupported event name \(name)"
            ))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .connection(connectionEvent):
            try connectionEvent.encode(to: encoder)
        case let .connectionError(connectionErrorEvent):
            try connectionErrorEvent.encode(to: encoder)
        case let .disconnection(disconnectionEvent):
            try disconnectionEvent.encode(to: encoder)
        }
    }
}
