//
//  Created by Anton Spivak
//

import Fundamentals
import FundamentalsExtensions

// MARK: - SignDataPayload

public enum SignDataPayload: Sendable, Hashable {
    case text(String)
    case binary(Data)
    case cell(Cell, schema: String)
}

// MARK: Codable

extension SignDataPayload: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case bytes
        case schema
        case cell
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            self = try .text(container.decode(String.self, forKey: .text))
        case "binary":
            self = try .binary(container.decode(Data.self, forKey: .bytes))
        case "cell":
            let schema = try container.decode(String.self, forKey: .schema)
            guard let cell = try container.decode(BOC.self, forKey: .cell).cells.first
            else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "BOC mus contain exactly one cell"
                ))
            }
            self = .cell(cell, schema: schema)
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown signing data type named \(type)"
            ))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .text(string):
            try container.encode("text", forKey: .type)
            try container.encode(string, forKey: .text)
        case let .binary(data):
            try container.encode("binary", forKey: .type)
            try container.encode(data, forKey: .bytes)
        case let .cell(cell, schema):
            try container.encode("cell", forKey: .type)
            try container.encode(schema, forKey: .schema)
            try container.encode(cell, forKey: .cell)
        }
    }
}
