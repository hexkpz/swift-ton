//
//  Created by Anton Spivak
//

import Foundation

// MARK: - AnyAddress

public enum AnyAddress {
    case `internal`(InternalAddress)
    case external(ExternalAddress)
}

// MARK: Sendable

extension AnyAddress: Sendable {}

// MARK: Hashable

extension AnyAddress: Hashable {}

// MARK: BitStorageRepresentable, CustomOptionalBitStorageRepresentable

/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L100
/// ```
/// addr_none$00 = MsgAddressExt;
///
/// addr_extern$01
///  len:(## 9)
///  external_address:(bits len)
///  = MsgAddressExt;
///
/// anycast_info$_
///  depth:(#<= 30) { depth >= 1 }
///  rewrite_pfx:(bits depth)
///  = Anycast;
///
/// addr_std$10 anycast:(Maybe Anycast)
///   workchain_id:int8
///   address:bits256
///   = MsgAddressInt;
///
/// addr_var$11
///  anycast:(Maybe Anycast)
///  addr_len:(## 9)
///  workchain_id:int32
///  address:(bits addr_len)
///  = MsgAddressInt;
///
/// _ _:MsgAddressInt = MsgAddress;
/// _ _:MsgAddressExt = MsgAddress;
/// ```
extension AnyAddress: BitStorageRepresentable, CustomOptionalBitStorageRepresentable {
    public static let nilBitStorageRepresentation = BitStorage("00")

    public init(bitStorage: inout ContinuousReader<BitStorage>) throws {
        self = switch try Self.kind(from: &bitStorage) {
        case .internal: try .internal(InternalAddress(bitStorage: &bitStorage))
        case .external: try .external(ExternalAddress(bitStorage: &bitStorage))
        }
    }

    public func appendTo(_ bitStorage: inout BitStorage) {
        switch self {
        case let .internal(internalAddress):
            internalAddress.appendTo(&bitStorage)
        case let .external(externalAddress):
            externalAddress.appendTo(&bitStorage)
        }
    }

    private enum Kind {
        case `internal`
        case external
    }

    @inline(__always)
    private static func kind(from bitStorage: inout ContinuousReader<BitStorage>) throws -> Kind {
        let kind = try bitStorage.read(UInt8.self, truncatingToBitWidth: 2)
        try bitStorage.back(2)
        return switch kind {
        case 0: preconditionFailure("nilBitStorageRepresentation?")
        case 1: .internal
        case 2, 3: .external
        default: preconditionFailure("Must not happen")
        }
    }
}

// MARK: - InternalAddress

public struct InternalAddress: RawRepresentable {
    // MARK: Lifecycle

    /// Creates a `RawAddress` from a `FriendlyAddress`, extracting its `workchain` and 32-byte `hash`.
    /// Useful if you need to switch from a human-friendly address representation to the raw bytes.
    ///
    /// - Parameter friendlyAddress: The human-readable address including flags, format, etc.
    ///
    /// **Usage Example**:
    /// ```swift
    /// let friendly = FriendlyAddress("EQAZ...")!
    /// let raw = RawAddress(friendly)
    /// print(raw.workchain) // e.g. .basic
    /// print(raw.hash.count) // 32
    /// ```
    @inlinable @inline(__always)
    public init(_ friendlyAddress: FriendlyAddress) {
        self.init(friendlyAddress.workchain, friendlyAddress.hash)
    }

    /// Creates a `RawAddress` from a 36-byte raw value: the first 4 bytes
    /// represent the `workchain` (Int32), and the last 32 bytes the `hash`.
    ///
    /// - Parameter rawValue: A `Data` of exactly 36 bytes.
    ///
    /// **Example**:
    /// ```swift
    /// let rawValue: Data = wcBytes + hashBytes // 4 + 32
    /// let address = RawAddress(rawValue: rawValue)
    /// ```
    public init?(rawValue: Data) {
        guard rawValue.count == 36
        else {
            return nil
        }
        self.rawValue = rawValue
    }

    /// Creates a `RawAddress` from a specified `workchain` and 32-byte hash.
    /// Returns `nil` if hash size is not 32 bytes.
    ///
    /// - Parameters:
    ///  - workchain: The `Workchain` ID (e.g., `.master`, `.basic`, or `.other(Int32)`).
    ///  - hash: A `Data` of 32 bytes.
    ///
    /// **Example**:
    /// ```swift
    /// let raw = RawAddress(workchain: .basic, hash: hash32Bytes)
    /// ```
    public init?(workchain: Workchain, hash: Data) {
        guard hash.count == 32
        else { return nil }
        self.init(rawValue: workchain.data() + hash)
    }

    @usableFromInline
    init(_ workchain: Workchain, _ hash: Data) {
        self.rawValue = workchain.data() + hash
    }

    // MARK: Public

    /// The raw 36-byte data: 4 bytes for the `workchain` + 32 bytes for the `hash`.
    public let rawValue: Data

    /// The `Workchain` extracted from the first 4 bytes of `rawValue`.
    public var workchain: Workchain { .init(data: Data(rawValue[0 ..< 4])) }

    /// The 32-byte hash extracted from bytes 4..36 in `rawValue`.
    public var hash: Data { .init(rawValue[4 ..< 36]) }
}

// MARK: LosslessStringConvertible

extension InternalAddress: LosslessStringConvertible {
    /// A textual representation: <workchain>:<hash> in uppercase hex form.
    ///
    /// - e.g. `"0:FFEEDDCCBBAA..."`.
    public var description: String {
        "\(workchain):\(hash.hexadecimalString(separator: ""))".uppercased()
    }

    /// Creates a `RawAddress` from the string `"<workchain>:<hash>"`.
    ///
    /// - e.g. `"0:FFEEDDCCBBAA..."`.
    /// Returns `nil` if parsing fails or if hash is not 32 bytes in hex.
    public init?(_ description: String) {
        let components = description.components(separatedBy: ":")
        guard components.count == 2,
              let workchain = Int32(components[0], radix: 10),
              let hash = Data(hexadecimalString: components[1])
        else { return nil }
        self.init(workchain: .init(rawValue: workchain), hash: hash)
    }
}

// MARK: CustomDebugStringConvertible

extension InternalAddress: CustomDebugStringConvertible {
    /// Same as `.description`.
    @inlinable @inline(__always)
    public var debugDescription: String { description }
}

public extension String.StringInterpolation {
    /// Enables string interpolation of a RawAddress. E.g. "\(rawAddress)".
    mutating func appendInterpolation(_ value: InternalAddress) {
        appendLiteral("\(value.description)")
    }
}

// MARK: - InternalAddress + ExpressibleByStringLiteral

extension InternalAddress: ExpressibleByStringLiteral {
    /// Creates a RawAddress from a string literal like "0:FFEEDDCC...".
    /// Crashes if the string is not valid.
    ///
    /// **Example**:
    /// ```swift
    /// let addr: RawAddress = "0:ABCDEF..."
    /// ```
    public init(stringLiteral value: StringLiteralType) {
        guard let address = Self(value)
        else {
            fatalError("Couldn't decode \(value) as `RawAddress`")
        }
        self = address
    }
}

// MARK: - InternalAddress + Sendable

extension InternalAddress: Sendable {}

// MARK: - InternalAddress + Hashable

extension InternalAddress: Hashable {}

// MARK: - InternalAddress + BitStorageRepresentable, CustomOptionalBitStorageRepresentable

/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L105
/// ```
/// addr_std$10
///  anycast:(Maybe Anycast)
///  workchain_id:int8
///  address:bits256
///  = MsgAddressInt;
///
/// addr_var$11
///  anycast:(Maybe Anycast)
///  addr_len:(## 9)
///  workchain_id:int32
///  address:(bits addr_len)
///  = MsgAddressInt;
/// ```
extension InternalAddress: BitStorageRepresentable, CustomOptionalBitStorageRepresentable {
    public static let nilBitStorageRepresentation = BitStorage("00")

    public init(bitStorage: inout ContinuousReader<BitStorage>) throws {
        let type = try bitStorage.read(UInt8.self, truncatingToBitWidth: 2)
        guard type == 2 || type == 3
        else {
            throw TLBCodingError.invalidEnumerationFlagValue(for: Self.self)
        }

        guard try !bitStorage.read()
        else {
            throw TLBCodingError("Not implemented yet (anycast)")
        }

        let workchain: Int32
        let hash: Data

        switch type {
        case 2:
            workchain = try Int32(bitStorage.read(Int8.self))
            hash = try BitStorage(bitStorage.read(256)).alignedData()
        case 3:
            let count = try Int(bitStorage.read(UInt.self, truncatingToBitWidth: 9))
            workchain = try bitStorage.read(Int32.self)
            hash = try BitStorage(bitStorage.read(count)).alignedData()
        default:
            preconditionFailure("Invalid address type \(type)")
        }

        self = InternalAddress(workchain: Workchain(rawValue: workchain), hash: hash)!
    }

    public func appendTo(_ bitStorage: inout BitStorage) {
        bitStorage.append(contentsOf: "100") // [1,0](addr_std$10) + [0](anycast);
        bitStorage.append(bitPattern: workchain.rawValue, truncatingToBitWidth: 8)
        bitStorage.append(contentsOf: BitStorage(hash))
    }
}

// MARK: - ExternalAddress

public struct ExternalAddress: RawRepresentable {
    // MARK: Lifecycle

    @inlinable @inline(__always)
    public init(rawValue: BitStorage) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public let rawValue: BitStorage
}

// MARK: CustomStringConvertible

extension ExternalAddress: CustomStringConvertible {
    public var description: String {
        "External<\(rawValue.count):\(rawValue.nibbleFiftHexadecimalString()))>"
    }
}

// MARK: CustomDebugStringConvertible

extension ExternalAddress: CustomDebugStringConvertible {
    /// Same as `.description`.
    @inlinable @inline(__always)
    public var debugDescription: String { description }
}

public extension String.StringInterpolation {
    /// Enables string interpolation of a ExternalAddress. E.g. "\(rawAddress)".
    mutating func appendInterpolation(_ rawAddress: ExternalAddress) {
        appendLiteral("\(rawAddress.description)")
    }
}

// MARK: - ExternalAddress + Sendable

extension ExternalAddress: Sendable {}

// MARK: - ExternalAddress + Hashable

extension ExternalAddress: Hashable {}

// MARK: - ExternalAddress + BitStorageRepresentable, CustomOptionalBitStorageRepresentable

/// https://github.com/ton-blockchain/ton/blob/ea0dc161639ef2640876d6de06f7224ac5873847/crypto/block/block.tlb#L101
/// ```
/// addr_extern$01
///  len:(## 9)
///  external_address:(## len)
///  = MsgAddressExt;
/// ```
extension ExternalAddress: BitStorageRepresentable, CustomOptionalBitStorageRepresentable {
    public static let nilBitStorageRepresentation = BitStorage("00")

    public init(bitStorage: inout ContinuousReader<BitStorage>) throws {
        let count = try Self.count(from: &bitStorage)
        let rawValue = try bitStorage.read(count)
        self.init(rawValue: BitStorage(rawValue))
    }

    public func appendTo(_ bitStorage: inout BitStorage) {
        bitStorage.append(contentsOf: "01") // [0,1](addr_extern$01)
        bitStorage.append(bitPattern: rawValue.count, truncatingToBitWidth: 9)
        bitStorage.append(contentsOf: rawValue)
    }

    @inline(__always)
    private static func count(from bitStorage: inout ContinuousReader<BitStorage>) throws -> Int {
        let type = try bitStorage.read(UInt8.self, truncatingToBitWidth: 2)
        guard type == 1
        else {
            throw TLBCodingError.invalidEnumerationFlagValue(for: self)
        }
        return try Int(bitStorage.read(UInt.self, truncatingToBitWidth: 9))
    }
}
