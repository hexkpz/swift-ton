//
//  Created by Anton Spivak
//

// MARK: - AnyResponse

public enum AnyResponse {
    case disconnection(DisconnectionResponse)
    case sending(SendingTransactionResponse)
    case signing(SigningDataResponse)
}

// MARK: Sendable

extension AnyResponse: Sendable {}

// MARK: Codable

extension AnyResponse: Codable {
    public init(from decoder: any Decoder) throws {
        if let disconnection = try? DisconnectionResponse(from: decoder) {
            self = .disconnection(disconnection)
        } else if let sendingTransaction = try? SendingTransactionResponse(from: decoder) {
            self = .sending(sendingTransaction)
        } else if let signingData = try? SigningDataResponse(from: decoder) {
            self = .signing(signingData)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unsupported response type"
            ))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .disconnection(value):
            try value.encode(to: encoder)
        case let .sending(value):
            try value.encode(to: encoder)
        case let .signing(value):
            try value.encode(to: encoder)
        }
    }
}
