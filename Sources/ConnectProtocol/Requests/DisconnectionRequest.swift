//
//  Created by Anton Spivak
//

// MARK: - DisconnectionRequest

public struct DisconnectionRequest {
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

extension DisconnectionRequest: Sendable {}

// MARK: WebApplicationRequest

extension DisconnectionRequest: WebApplicationRequest {
    public static let name: String = "disconnect"

    public typealias Response = DisconnectionResponse
    public typealias Error = DisconnectionResponse.Error
}
