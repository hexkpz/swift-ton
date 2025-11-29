//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - WalletSignedMessage

/// A structure representing a signed wallet message.
/// It contains a signature (`signature`) and a message body (`body`).
struct WalletSignedMessage {
    // MARK: Lifecycle

    init(signature: Data, body: Cell, position: SignaturePosition = .leading) {
        self.signature = signature
        self.body = body
        self.position = position
    }

    // MARK: Internal

    enum SignaturePosition {
        case leading
        case trailing
    }

    let signature: Data
    let body: Cell
    let position: SignaturePosition
}

// MARK: CellEncodable

extension WalletSignedMessage: CellEncodable {
    func encode(to container: inout CellEncodingContainer) throws {
        switch position {
        case .leading:
            try container.encode(signature)
            try container.encode(contentsOf: body)
        case .trailing:
            try container.encode(contentsOf: body)
            try container.encode(signature)
        }
    }
}

// MARK: - WalletOutboundMessage

/// A structure representing an outbound wallet message.
/// It contains the internal message parameters (`parameters`) and message data (`data`).
@usableFromInline
struct WalletOutboundMessage {
    // MARK: Lifecycle

    @usableFromInline
    init(parameters: InternalMessageParameters, data: MessageRelaxed) {
        self.parameters = parameters
        self.data = data
    }

    // MARK: Internal

    let parameters: InternalMessageParameters
    let data: MessageRelaxed
}

/// Computes a subwallet identifier based on the workchain.
///
/// - Parameter workchain: The workchain associated with the wallet.
/// - Returns: A unique identifier for the subwallet.
func WalletSubwallet(for workchain: Workchain) -> UInt32 {
    698_983_191 + UInt32(workchain.rawValue)
}

// MARK: - WalletIdentifier

/// Represents a unique identifier for a wallet, derived from the network kind and context.
public struct WalletIdentifier: RawRepresentable {
    // MARK: Lifecycle

    /// Initializes a `WalletIdentifier` from a given network and context.
    ///
    /// - Parameters:
    ///   - network: The blockchain network kind.
    ///   - context: The context, which can be a client or a custom identifier.
    public init(network: NetworkKind, context: Context) {
        var rawValue: UInt32
        switch context {
        case let .client(workchain, version, subwalletID):
            // First bit must be equal `1` for client context
            rawValue = UInt32(2_147_483_648)
            rawValue |= (UInt32(truncatingIfNeeded: workchain.rawValue) & UInt32(UInt8.max)) << 23
            rawValue |= UInt32(version.rawValue) << 15
            rawValue |= UInt32(subwalletID) & UInt32(32767)
        case let .custom(value):
            // First bit must be equal `0` for custom context
            rawValue = value & (UInt32.max >> 1)
        }
        self.init(rawValue: UInt32(truncatingIfNeeded: network.rawValue) ^ rawValue)
    }

    /// Initializes a `WalletIdentifier` with a raw `UInt32` value.
    ///
    /// - Parameter rawValue: The raw representation of the wallet identifier.
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    // MARK: Public

    /// The raw `UInt32` value of the wallet identifier.
    public let rawValue: UInt32

    /// Creates a client `WalletIdentifier` based on network, workchain, version, and subwallet ID.
    ///
    /// - Parameters:
    ///   - network: The blockchain network kind, default is `.mainnet`.
    ///   - workchain: The workchain associated with the wallet, default is `.basic`.
    ///   - version: The wallet version.
    ///   - subwalletID: The subwallet identifier.
    /// - Returns: A `WalletIdentifier` instance.
    @inlinable @inline(__always)
    public static func client(
        network: NetworkKind = .mainnet,
        workchain: Workchain = .basic,
        version: Version,
        subwalletID: UInt16
    ) -> WalletIdentifier {
        return self.init(network: network, context: .client(workchain, version, subwalletID))
    }

    /// Creates a custom `WalletIdentifier` with a given network and context.
    ///
    /// - Parameters:
    ///   - network: The blockchain network kind, default is `.mainnet`.
    ///   - context: A custom `UInt32` value representing the context.
    /// - Returns: A `WalletIdentifier` instance.
    @inlinable @inline(__always)
    public static func custom(
        network: NetworkKind = .mainnet, context: UInt32
    ) -> WalletIdentifier {
        self.init(network: network, context: .custom(context))
    }

    /// Retrieves the context associated with a specific network.
    ///
    /// - Parameter network: The blockchain network kind.
    /// - Returns: The corresponding `Context` (either `client` or `custom`).
    public func context(for network: NetworkKind) -> Context {
        let rawValue = UInt32(truncatingIfNeeded: network.rawValue) ^ rawValue
        if (rawValue & 2_147_483_648) != 0 {
            let wc = (rawValue & (UInt32(UInt8.max) << 23)) >> 23
            return .client(
                Workchain(rawValue: Int32(Int8(truncatingIfNeeded: wc))),
                Version(rawValue: UInt8(rawValue & (UInt32(UInt8.max) << 15)) >> 15),
                UInt16(rawValue & UInt32(32767))
            )
        } else {
            return .custom(rawValue)
        }
    }
}

// MARK: Hashable

extension WalletIdentifier: Hashable {}

// MARK: Sendable

extension WalletIdentifier: Sendable {}

// MARK: BitStorageRepresentable

extension WalletIdentifier: BitStorageRepresentable {
    public init(bitStorage: inout ContinuousReader<BitStorage>) throws {
        self.rawValue = try bitStorage.read(UInt32.self)
    }

    public func appendTo(_ bitStorage: inout BitStorage) {
        bitStorage.append(bitPattern: rawValue)
    }
}

// MARK: WalletIdentifier.Context

public extension WalletIdentifier {
    enum Context {
        /// Represents a client-based identifier with a workchain, version, and subwallet ID.
        case client(Workchain, Version, UInt16)

        /// Represents a custom identifier.
        case custom(UInt32)
    }
}

// MARK: - WalletIdentifier.Context + Hashable

extension WalletIdentifier.Context: Hashable {}

// MARK: - WalletIdentifier.Context + Sendable

extension WalletIdentifier.Context: Sendable {}

// MARK: - WalletIdentifier.Version

public extension WalletIdentifier {
    /// Defines wallet versions.
    enum Version: RawRepresentable {
        case v5r1
        case unknown(UInt8)

        // MARK: Lifecycle

        public init(rawValue: UInt8) {
            self = switch rawValue {
            case Self.v5r1.rawValue: .v5r1
            default: .unknown(rawValue)
            }
        }

        // MARK: Public

        public var rawValue: UInt8 {
            switch self {
            case .v5r1: 0
            case let .unknown(rawValue): rawValue
            }
        }
    }
}

// MARK: - WalletIdentifier.Version + Hashable

extension WalletIdentifier.Version: Hashable {}

// MARK: - WalletIdentifier.Version + Sendable

extension WalletIdentifier.Version: Sendable {}
