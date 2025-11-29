//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - SendingTransactionRequest

public struct SendingTransactionRequest {
    // MARK: Lifecycle

    public init(id: String, parameters: Parameters) {
        self.id = id
        self.parameters = parameters
    }

    // MARK: Public

    public var id: String
    public var parameters: Parameters
}

// MARK: Sendable

extension SendingTransactionRequest: Sendable {}

// MARK: WebApplicationRequest

extension SendingTransactionRequest: WebApplicationRequest {
    public static let name: String = "sendTransaction"

    public typealias Response = SendingTransactionResponse
    public typealias Error = SendingTransactionResponse.Error
}

// MARK: SendingTransactionRequest.Parameters

public extension SendingTransactionRequest {
    struct Parameters {
        // MARK: Lifecycle

        public init(
            network: NetworkKind?,
            senderAddress: InternalAddress?,
            expiredAt: Date,
            messages: [Message]
        ) {
            self.network = network
            self.senderAddress = senderAddress
            self.expiredAt = expiredAt
            self.messages = messages
        }

        // MARK: Public

        public let network: NetworkKind?
        public let senderAddress: InternalAddress?

        public let expiredAt: Date
        public let messages: [Message]
    }
}

// MARK: - SendingTransactionRequest.Parameters + Sendable

extension SendingTransactionRequest.Parameters: Sendable {}

// MARK: - SendingTransactionRequest.Parameters + Codable

extension SendingTransactionRequest.Parameters: Codable {
    private enum CodingKeys: String, CodingKey {
        case network
        case from
        case validUntil = "valid_until"
        case messages
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let _network = try container.decodeIfPresent(String.self, forKey: .network) {
            guard let rawValue = Int32(_network),
                  let network = NetworkKind(rawValue: rawValue)
            else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid `network` format"
                ))
            }
            self.network = network
        } else {
            self.network = nil
        }

        self.messages = try container.decode([Message].self, forKey: .messages)
        self.senderAddress = try container.decodeIfPresent(InternalAddress.self, forKey: .from)
        self.expiredAt = try Date(timeIntervalSince1970: TimeInterval(container.decode(
            UInt64.self,
            forKey: .validUntil
        )))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(messages, forKey: .messages)
        if let network {
            try container.encode("\(network.rawValue)", forKey: .network)
        }
        try container.encodeIfPresent(senderAddress, forKey: .from)
        try container.encode(UInt64(expiredAt.timeIntervalSince1970), forKey: .validUntil)
    }
}

// MARK: - SendingTransactionRequest.Parameters.Message

public extension SendingTransactionRequest.Parameters {
    struct Message {
        // MARK: Lifecycle

        public init(
            address: FriendlyAddress,
            amount: CurrencyValue,
            payload: Cell?,
            stateInitial: StateInit?
        ) {
            self.address = address
            self.amount = amount
            self.payload = payload
            self.stateInitial = stateInitial
        }

        // MARK: Public

        public let address: FriendlyAddress
        public let amount: CurrencyValue
        public let payload: Cell?
        public let stateInitial: StateInit?
    }
}

// MARK: - SendingTransactionRequest.Parameters.Message + Sendable

extension SendingTransactionRequest.Parameters.Message: Sendable {}

// MARK: - SendingTransactionRequest.Parameters.Message + Codable

extension SendingTransactionRequest.Parameters.Message: Codable {
    private enum CodingKeys: String, CodingKey {
        case address
        case amount
        case payload
        case stateInit
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let address = try container.decode(Address.self, forKey: .address)
        switch address.rawValue {
        case let .friendly(friendly):
            self.address = friendly
        case let .internal(internal_):
            self.address = .init(internal_, options: [.bounceable])
        }

        self.amount = try container.decode(CurrencyValue.self, forKey: .amount)
        self.payload = try container.decodeIfPresent(BOC.self, forKey: .payload)?.cells.first
        self.stateInitial = try container.decodeIfPresent(BOC.self, forKey: .stateInit)?
            .cells
            .first?
            .decode(StateInit.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(address, forKey: .address)
        try container.encode(amount, forKey: .amount)

        if let payload {
            try container.encode(BOC(payload), forKey: .payload)
        }

        if let stateInitial {
            try container.encode(BOC(Cell(stateInitial)), forKey: .payload)
        }
    }
}
