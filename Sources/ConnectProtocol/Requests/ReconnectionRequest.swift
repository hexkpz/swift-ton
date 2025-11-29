//
//  Created by Anton Spivak
//

// MARK: - ReconnectionRequest

public struct ReconnectionRequest {
    // MARK: Lifecycle

    public init(id: String, parameters: EmptyParameters) {
        self.id = id
        self.parameters = parameters
    }

    // MARK: Public

    public var id: String
    public var parameters: EmptyParameters
}

// MARK: Sendable

extension ReconnectionRequest: Sendable {}

// MARK: WebApplicationRequest

extension ReconnectionRequest: WebApplicationRequest {
    public static let name: String = "reconnect"

    public typealias Response = ConnectionEvent
    public typealias Error = ConnectionErrorEvent
}
