//
//  Created by Anton Spivak
//

import Foundation

import Fundamentals
import FundamentalsExtensions

// MARK: - StackElement

enum StackElement {
    case number(Data)
    case cell(Cell)
    case slice(Cell)
}

// MARK: Codable

extension StackElement: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "num":
            let originalValue = try container.decode(String.self, forKey: .value)
            var hexadecimalString = originalValue

            if hexadecimalString.starts(with: "0x") {
                hexadecimalString.removeFirst(2)
            }

            if !hexadecimalString.count.isMultiple(of: 2) {
                hexadecimalString = "0\(hexadecimalString)"
            }

            guard let data = Data(hexadecimalString: hexadecimalString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: CodingKeys.value,
                    in: container,
                    debugDescription: "Couldn't decode raw bytes `\(originalValue)`"
                )
            }

            self = .number(data)
        case "cell":
            self = try .cell(container.decode(Cell.self, forKey: .value))
        case "slice":
            self = try .slice(container.decode(Cell.self, forKey: .value))
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Couldn't decode 'StackElement' with type `\(type)`"
            ))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .number(value):
            try container.encode("num", forKey: .type)
            try container.encode("0x\(value.hexadecimalString)", forKey: .value)
        case let .cell(value):
            try container.encode("cell", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .slice(value):
            try container.encode("slice", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    private enum CodingKeys: CodingKey {
        case type
        case value
    }
}

extension Tuple.Element {
    init(from stackElement: StackElement) {
        self = switch stackElement {
        case let .number(value): .number(value)
        case let .cell(value): .cell(value)
        case let .slice(value): .slice(value)
        }
    }
}

extension StackElement {
    init(from tupleElement: Tuple.Element) {
        self = switch tupleElement {
        case let .number(value): .number(value)
        case let .cell(value): .cell(value)
        case let .slice(value): .slice(value)
        }
    }
}
