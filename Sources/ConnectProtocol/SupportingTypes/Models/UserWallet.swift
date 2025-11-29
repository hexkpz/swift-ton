//
//  Created by Anton Spivak
//

import Fundamentals
import Contracts
import FundamentalsExtensions

// MARK: - UserWallet

public struct UserWallet {
    // MARK: Lifecycle

    public init(
        address: InternalAddress,
        network: NetworkKind,
        publicKey: Data,
        stateInitial: StateInit
    ) {
        self.address = address
        self.network = network
        self.publicKey = publicKey
        self.stateInitial = stateInitial
    }

    // MARK: Public

    public let address: InternalAddress
    public let network: NetworkKind
    public let publicKey: Data
    public let stateInitial: StateInit
}

// MARK: Sendable

extension UserWallet: Sendable {}

// MARK: Codable

extension UserWallet: Codable {
    private enum CodingKeys: String, CodingKey {
        case address
        case network
        case publicKey
        case stateInitial = "walletStateInit"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.address = try container.decode(InternalAddress.self, forKey: .address)
        
        let _network = try container.decode(String.self, forKey: .network)
        guard let rawValue = Int32(_network),
              let network = NetworkKind(rawValue: rawValue)
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid `network` format"
            ))
        }

        let publicKey = try container.decode(String.self, forKey: .publicKey)
        guard let publicKey = Data(hexadecimalString: publicKey)
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid `publicKey` format"
            ))
        }

        let stateInitial = try container.decode(Data.self, forKey: .stateInitial)
        guard let stateInitial = try? BOC(stateInitial).cells.first?.decode(StateInit.self)
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid `walletStateInit` format"
            ))
        }

        self.network = network
        self.publicKey = publicKey
        self.stateInitial = stateInitial
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encode("\(network.rawValue)", forKey: .network)
        try container.encode(publicKey.hexadecimalString, forKey: .publicKey)
        try container.encode(BOC(Cell(stateInitial)), forKey: .stateInitial)
    }
}
