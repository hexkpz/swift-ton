//
//  Created by Anton Spivak
//

// MARK: - HashmapE.UInt256

public extension HashmapE {
    /// A convenience type representing a 256-bit unsigned integer
    /// (backed by `BigUInt`) that can be used as a key in `HashmapE`.
    struct UInt256: RawRepresentable {
        // MARK: Lifecycle

        public init(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }

        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }

        // MARK: Public

        public let rawValue: BigUInt
    }
}

// MARK: - HashmapE.UInt256 + Hashable

extension HashmapE.UInt256: Hashable {}

// MARK: - HashmapE.UInt256 + Sendable

extension HashmapE.UInt256: Sendable {}

// MARK: - HashmapE.UInt256 + HashmapE.Key

extension HashmapE.UInt256: HashmapE.Key {
    public init(keyRepresentation bitStorage: BitStorage) throws {
        self.rawValue = BigUInt(truncatingIfNeeded: bitStorage)
    }

    public var keyRepresentation: BitStorage {
        BitStorage(bitPattern: rawValue, truncatingToBitWidth: 256)
    }
}

// MARK: - HashmapE.UInt256 + HashmapE.FixedWidthKey

extension HashmapE.UInt256: HashmapE.FixedWidthKey {
    public static var keyBitWidth: Int { 256 }
}
