//
//  Created by Anton Spivak
//

import Foundation

// MARK: - Address

/// A flexible address wrapper that can hold either an `InternalAddress` (raw 36-byte)
/// or a `FriendlyAddress` (human-readable, base64-encoded). It provides a unified
/// interface for operations like accessing `workchain` or the 32-byte `hash`.
///
/// **Example**:
/// ```swift
/// // Create from internal address
/// let intAddr = InternalAddress(workchain: .basic, hash: some32ByteHash)!
/// let address = Address(intAddr)
/// print(address)  // prints internal address in "<workchain>:<hash>" format
///
/// // Create from friendly address (e.g., "EQAr...")
/// if let friendlyAddr = Address("EQAr...base64URLor64") {
///     print("Parsed friendly address:", friendlyAddr)
/// }
/// ```
public struct Address: RawRepresentable {
    // MARK: Lifecycle

    /// Initializes an `Address` from an `InternalAddress`.
    ///
    /// - Parameter internalAddress: The lower-level 36-byte raw address to wrap.
    @inlinable @inline(__always)
    public init(_ internalAddress: InternalAddress) {
        self.init(rawValue: .internal(internalAddress))
    }

    /// Initializes an `Address` from a `FriendlyAddress`, which is a base64/base64URL
    /// string plus bounce/test flags.
    ///
    /// - Parameter friendlyAddress: The higher-level, human-readable TON address.
    @inlinable @inline(__always)
    public init(_ friendlyAddress: FriendlyAddress) {
        self.init(rawValue: .friendly(friendlyAddress))
    }

    /// Creates an `Address` from a raw enum value of type `Address.RawValue`.
    ///
    /// - Parameter rawValue: A `.internal(...)` or `.friendly(...)` case.
    @inlinable @inline(__always)
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public let rawValue: RawValue

    /// The `Workchain` from whichever address type is stored. For an `InternalAddress`,
    /// it's the four-byte integer. For a `FriendlyAddress`, it's parsed from the
    /// user-friendly base64 data.
    public var workchain: Workchain {
        switch rawValue {
        case let .internal(internalAddress): internalAddress.workchain
        case let .friendly(friendlyAddress): friendlyAddress.workchain
        }
    }

    /// The 32-byte hash portion of the address. For an `InternalAddress`, it's
    /// the raw hash. For a `FriendlyAddress`, it’s decoded from the base64.
    public var hash: Data {
        switch rawValue {
        case let .internal(internalAddress): internalAddress.hash
        case let .friendly(friendlyAddress): friendlyAddress.hash
        }
    }
}

// MARK: LosslessStringConvertible

extension Address: LosslessStringConvertible {
    /// Converts this address to a string. If it's a `.friendly` variant, returns
    /// the base64/base64URL string. If it's `.internal`, returns `<workchain>:<hash>`.
    public var description: String {
        switch rawValue {
        case let .friendly(friendlyAddress): friendlyAddress.description
        case let .internal(rawAddress): rawAddress.description
        }
    }

    /// Attempts to parse either an `InternalAddress` or a `FriendlyAddress` from
    /// the given string. Returns `nil` if parsing fails for both.
    ///
    /// **Example**:
    /// ```swift
    /// let addr = Address("0:ABCDEF...") ?? Address("EQAr...")
    /// ```
    public init?(_ description: String) {
        if let internalAddress = InternalAddress(description) {
            self.rawValue = .internal(internalAddress)
        } else if let friendlyAddress = FriendlyAddress(description) {
            self.rawValue = .friendly(friendlyAddress)
        } else {
            return nil
        }
    }
}

// MARK: CustomDebugStringConvertible

extension Address: CustomDebugStringConvertible {
    /// Same as `.description`, which is either the internal or friendly address string.
    @inlinable @inline(__always)
    public var debugDescription: String { description }
}

public extension String.StringInterpolation {
    /// Enables string interpolation of an `Address`, returning `.description`.
    ///
    /// **Example**:
    /// ```swift
    /// let addr: Address = "EQAr..."
    /// print("Address is: \(addr)")
    /// ```
    mutating func appendInterpolation(_ value: Address) {
        appendLiteral("\(value.description)")
    }
}

// MARK: - Address + ExpressibleByStringLiteral

extension Address: ExpressibleByStringLiteral {
    /// Creates an `Address` from a string literal. If parsing fails, crashes.
    ///
    /// **Example**:
    /// ```swift
    /// let myAddr: Address = "EQAr..."
    /// ```
    public init(stringLiteral value: StringLiteralType) {
        guard let address = Self(value)
        else {
            fatalError("Couldn't decode \(value) as `Address`")
        }
        self = address
    }
}

// MARK: - Address + Sendable

extension Address: Sendable {}

// MARK: - Address + Hashable

extension Address: Hashable {}

// MARK: - Address.RawValue

public extension Address {
    enum RawValue: Sendable, Hashable {
        case `internal`(InternalAddress)
        case friendly(FriendlyAddress)
    }
}

// MARK: - Address + BitStorageRepresentable, CustomOptionalBitStorageRepresentable

extension Address: BitStorageRepresentable, CustomOptionalBitStorageRepresentable {
    public static var nilBitStorageRepresentation: BitStorage {
        InternalAddress.nilBitStorageRepresentation
    }

    /// Decodes an `Address` from bits by first building an `InternalAddress` from
    /// the storage. If successful, wraps it in `.internal(...)`.
    /// (Currently does not decode a `.friendly` variant from bits.)
    ///
    /// - Parameter bitStorage: The storage to read from.
    /// - Throws: If bit decoding fails.
    public init(bitStorage: inout ContinuousReader<BitStorage>) throws {
        self = try .init(rawValue: .internal(.init(bitStorage: &bitStorage)))
    }

    /// Appends the underlying address to the bit storage. If `.friendly`, we fall
    /// back to appending its `internalAddress`. If `.internal`, we just append it.
    ///
    /// - Parameter bitStorage: The storage to which bits are written.
    public func appendTo(_ bitStorage: inout BitStorage) {
        switch rawValue {
        case let .friendly(address):
            address.internalAddress.appendTo(&bitStorage)
        case let .internal(address):
            address.appendTo(&bitStorage)
        }
    }
}

public extension FriendlyAddress {
    /// Initializes a `FriendlyAddress` by unwrapping the given `Address`, optionally
    /// overriding `options` or `format`.
    ///
    /// - Parameters:
    ///   - address: The `Address` to interpret as friendly or internal.
    ///   - options: If provided, overrides the default bounce/test flags.
    ///   - format: If provided, overrides `.base64URL`.
    init(_ address: Address, options: Options = [], format: Format = .base64URL) {
        switch address.rawValue {
        case let .internal(internalAddress):
            self.init(internalAddress, options: options, format: format)
        case let .friendly(friendlyAddress):
            self.init(friendlyAddress.internalAddress, options: options, format: format)
        }
    }
}

public extension InternalAddress {
    /// Converts a general `Address` into an `InternalAddress`. If it’s already
    /// `.internal(...)`, returns that directly. If it’s `.friendly`, extracts
    /// the `internalAddress`.
    ///
    /// - Parameter address: An `Address` that can be internal or friendly.
    init(_ address: Address) {
        switch address.rawValue {
        case let .internal(internalAddress):
            self = internalAddress
        case let .friendly(friendlyAddress):
            self = friendlyAddress.internalAddress
        }
    }
}
