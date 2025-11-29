//
//  Created by Anton Spivak
//

// MARK: - DisconnectionEvent

public struct DisconnectionEvent {
    // MARK: Lifecycle

    public init(id: Int = -1) {
        self.id = id
    }

    // MARK: Public

    public let id: Int

    // MARK: Internal

    static let name = "disconnect"

    // MARK: Private

    private struct Payload: Codable {}
}

// MARK: Sendable

extension DisconnectionEvent: Sendable {}

// MARK: Codable

extension DisconnectionEvent: Codable {
    public init(from decoder: any Decoder) throws {
        let event = try HostApplicationEvent<Payload>(from: decoder)
        guard event.name == Self.name
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Expected event name to be `\(Self.name)`"
            ))
        }

        self.id = event.id
    }

    public func encode(to encoder: any Encoder) throws {
        try HostApplicationEvent(
            id: id,
            name: Self.name,
            payload: Payload()
        ).encode(to: encoder)
    }
}
