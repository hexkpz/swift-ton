//
//  Created by Anton Spivak
//

// MARK: - AnyRequest

public enum AnyRequest {
    case connection(ConnectionRequest)
    case reconnection(ReconnectionRequest)
    case disconnection(DisconnectionRequest)
    case sending(SendingTransactionRequest)
    case signing(SigningDataRequest)
}

// MARK: Sendable

extension AnyRequest: Sendable {}

// MARK: Codable

extension AnyRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case method
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.method) {
            let method = try container.decode(String.self, forKey: .method)
            switch method {
            case ReconnectionRequest.name:
                self = try .reconnection(ReconnectionRequest(from: decoder))
            case DisconnectionRequest.name:
                self = try .disconnection(DisconnectionRequest(from: decoder))
            case SendingTransactionRequest.name:
                self = try .sending(SendingTransactionRequest(from: decoder))
            case SigningDataRequest.name:
                self = try .signing(SigningDataRequest(from: decoder))
            default:
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported method named `\(method)`"
                ))
            }
        } else {
            self = try .connection(ConnectionRequest(from: decoder))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .connection(value):
            try value.encode(to: encoder)
        case let .reconnection(value):
            try value.encode(to: encoder)
        case let .disconnection(value):
            try value.encode(to: encoder)
        case let .sending(value):
            try value.encode(to: encoder)
        case let .signing(value):
            try value.encode(to: encoder)
        }
    }
}
