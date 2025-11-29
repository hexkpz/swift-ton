//
//  Created by Anton Spivak
//

// MARK: - HostApplicationResponse

public protocol HostApplicationResponse: Codable {
    associatedtype Success: Codable, Sendable

    var id: String { get set }
    var result: Result<Success, ConnectError> { get }

    init(id: String, result: Result<Success, ConnectError>)
}

// MARK: - _HostApplicationResponse

private struct _HostApplicationResponse<T> where T: Codable {
    let id: String
    let result: Result<T, ConnectError>
}

// MARK: Codable

extension _HostApplicationResponse: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case result
        case error
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)

        if container.contains(.result) {
            self.result = try .success(container.decode(T.self, forKey: .result))
        } else if container.contains(.error) {
            self.result = try .failure(container.decode(ConnectError.self, forKey: .error))
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.result,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing required key `result` or `error`"
                )
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        switch result {
        case let .success(result):
            try container.encode(result, forKey: .result)
        case let .failure(error):
            try container.encode(error, forKey: .error)
        }
    }
}

public extension HostApplicationResponse {
    init(from decoder: any Decoder) throws {
        let request = try _HostApplicationResponse<Success>(from: decoder)
        self.init(id: request.id, result: request.result)
    }

    func encode(to encoder: any Encoder) throws {
        try _HostApplicationResponse<Success>(
            id: id,
            result: result
        ).encode(to: encoder)
    }
}
