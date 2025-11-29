//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - InternalAddress + Codable

extension InternalAddress: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)

        guard let value = Self(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Couldn't decode 'InternalAddress' from \(description)"
            )
        }

        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

// MARK: - FriendlyAddress + Codable

extension FriendlyAddress: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)

        guard let value = Self(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Couldn't decode 'FriendlyAddress' from \(description)"
            )
        }

        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

// MARK: - Address + Codable

extension Address: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)

        guard let value = Self(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Couldn't decode 'Address' from \(description)"
            )
        }

        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

// MARK: - CurrencyValue + Codable

extension CurrencyValue: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)

        guard let value = Self(rawValue: description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Couldn't decode 'CurrencyValue' from \(description)"
            )
        }

        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(rawValue))
    }
}

// MARK: - BOC + Codable

extension BOC: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Foundation.Data.self)

        guard let value = BOC(rawValue: Foundation.Data(rawValue)) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Couldn't decode 'BOC' from \(rawValue)"
            )
        }

        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Foundation.Data(rawValue))
    }
}

// MARK: - Cell + Codable

extension Cell: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        let boc = try BOC(from: decoder)
        guard boc.cells.count == 1 else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Couldn't decode 'Cell' boc \(boc)"
            )
        }

        self = boc.cells[0]
    }

    public func encode(to encoder: any Encoder) throws {
        try BOC(self).encode(to: encoder)
    }
}

// MARK: - Workchain + Codable

extension Workchain: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(rawValue: container.decode(Int32.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - NetworkKind + Codable

extension NetworkKind: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int32.self)

        self = switch rawValue {
        case NetworkKind.mainnet.rawValue: .mainnet
        case NetworkKind.testnet.rawValue: .testnet
        default:
            throw DecodingError.typeMismatch(
                NetworkKind.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid network: \(rawValue)"
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Tuple + Codable

extension Tuple: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(rawValue: container.decode([Tuple.Element].self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Tuple.Element + Codable

extension Tuple.Element: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        var keys = ArraySlice(container.allKeys)
        guard let key = keys.popFirst(), keys.isEmpty else {
            throw DecodingError.typeMismatch(
                Data.self,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid number of keys found, expected one.",
                    underlyingError: nil
                )
            )
        }

        switch key {
        case .number:
            var container = try container.nestedUnkeyedContainer(forKey: .number)
            self = try .number(container.decode(Foundation.Data.self))
        case .cell:
            var container = try container.nestedUnkeyedContainer(forKey: .cell)
            self = try .cell(container.decode(Cell.self))
        case .slice:
            var container = try container.nestedUnkeyedContainer(forKey: .slice)
            self = try .slice(container.decode(Cell.self))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .number(value):
            var container = container.nestedUnkeyedContainer(forKey: .number)
            try container.encode(value)
        case let .cell(value):
            var container = container.nestedUnkeyedContainer(forKey: .cell)
            try container.encode(value)
        case let .slice(value):
            var container = container.nestedUnkeyedContainer(forKey: .slice)
            try container.encode(value)
        }
    }

    private enum CodingKeys: CodingKey {
        case number
        case cell
        case slice
    }
}
