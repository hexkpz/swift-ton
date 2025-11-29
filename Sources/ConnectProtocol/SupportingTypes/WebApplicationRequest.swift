//
//  Created by Anton Spivak
//

import Foundation

// MARK: - AnyWebApplicationRequest

public protocol AnyWebApplicationRequest {
    associatedtype Response
    associatedtype Error
}

// MARK: - WebApplicationRequest

public protocol WebApplicationRequest: Codable, AnyWebApplicationRequest {
    associatedtype Parameters: Codable

    static var name: String { get }

    var id: String { get set }
    var parameters: Parameters { get }

    init(id: String, parameters: Parameters)
}

// MARK: - _WebApplicationRequest

private struct _WebApplicationRequest: Codable {
    // MARK: Internal

    let id: String
    let method: String
    let parameters: [String]

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case id
        case method
        case parameters = "params"
    }
}

public extension WebApplicationRequest {
    init(from decoder: any Decoder) throws {
        let request = try _WebApplicationRequest(from: decoder)

        guard Self.name == request.method
        else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Method name (\(request.method)) does not match expected (\(Self.name))"
            ))
        }

        guard let _parameters = request.parameters.first
        else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Method name (\(request.method)) requires parameters"
            ))
        }

        let parameters = try JSONDecoder().decode(Parameters.self, from: Data(_parameters.utf8))
        self.init(id: request.id, parameters: parameters)
    }

    func encode(to encoder: any Encoder) throws {
        let parameters = try JSONEncoder().encode(self.parameters)
        guard let _parameters = String(data: parameters, encoding: .utf8)
        else {
            throw EncodingError.invalidValue(parameters, .init(
                codingPath: encoder.codingPath,
                debugDescription: "Failed to convert parameters to string"
            ))
        }

        try _WebApplicationRequest(
            id: id,
            method: Self.name,
            parameters: [_parameters]
        ).encode(to: encoder)
    }
}

public extension WebApplicationRequest where Parameters == EmptyParameters {
    init(from decoder: any Decoder) throws {
        let request = try _WebApplicationRequest(from: decoder)

        guard Self.name == request.method
        else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Method name (\(request.method)) does not match expected (\(Self.name))"
            ))
        }

        self.init(id: request.id, parameters: EmptyParameters())
    }

    func encode(to encoder: any Encoder) throws {
        try _WebApplicationRequest(
            id: id,
            method: Self.name,
            parameters: []
        ).encode(to: encoder)
    }
}

public extension WebApplicationRequest
    where
    Self.Response: HostApplicationResponse,
    Self.Error: ConnectErrorConvertible
{
    func success(result: Response.Success) -> Response {
        .init(id: id, result: .success(result))
    }

    func failure(error: Error) -> Response {
        .init(id: id, result: .failure(.init(error)))
    }

    func result(returning result: Result<Response.Success, Error>) -> Response {
        .init(id: id, result: {
            switch result {
            case let .success(result): .success(result)
            case let .failure(error): .failure(.init(error))
            }
        }())
    }
}
