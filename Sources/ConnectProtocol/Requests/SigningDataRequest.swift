//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - SigningDataRequest

public struct SigningDataRequest {
    // MARK: Lifecycle

    public init(id: String, parameters: SignDataPayload) {
        self.id = id
        self.parameters = parameters
    }

    // MARK: Public

    public var id: String
    public var parameters: SignDataPayload
}

// MARK: Sendable

extension SigningDataRequest: Sendable {}

// MARK: WebApplicationRequest

extension SigningDataRequest: WebApplicationRequest {
    public static let name: String = "signData"

    public typealias Response = SigningDataResponse
    public typealias Error = SigningDataResponse.Error
}
