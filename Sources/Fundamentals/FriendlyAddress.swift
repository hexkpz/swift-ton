//
//  Created by Anton Spivak
//

import Foundation

// MARK: - FriendlyAddress

/// A “friendly” human-readable address format in TON, typically base64 or base64URL
/// encoded. Internally comprises:
/// - A `workchain` (4 bytes, `Int32`)
/// - A 32-byte `hash`
/// - Additional `options` (e.g., bounceable/testable)
/// - An encoding `format` (e.g., `.base64`, `.base64URL`)
///
/// When serialized (`rawValue`), it includes a one-byte header plus the 36-byte raw address,
/// then a 2-byte CRC16 for integrity, base64/base64URL encoded.
///
/// **Usage Example**:
/// ```swift
/// let raw = RawAddress(workchain: .basic, hash: my32ByteHash)!
/// let friendly = FriendlyAddress(raw)
/// print(friendly.rawValue)     // base64 or base64URL string
/// print(friendly.workchain)    // e.g. .basic
/// ```
public struct FriendlyAddress: RawRepresentable {
    // MARK: Lifecycle

    /// Creates a `FriendlyAddress` from a `RawAddress`, specifying optional `options`
    /// (like `.bounceable`, `.testable`) and the address `format` (`.base64` or
    /// `.base64URL`).
    ///
    /// - Parameters:
    ///  - rawAddress: The underlying 36-byte `RawAddress`.
    ///  - options: Additional flags (default = `[]`).
    ///  - format: The desired encoding format (`.base64URL` by default).
    ///
    /// **Usage Example**:
    /// ```swift
    /// let raw = RawAddress(workchain: .basic, hash: some32ByteHash)!
    /// let friendly = FriendlyAddress(raw, options: [.bounceable], format: .base64)
    /// print(friendly.rawValue) // base64-encoded string
    /// ```
    public init(
        _ internalAddress: InternalAddress,
        options: Options = [],
        format: Format = .base64URL
    ) {
        self.init(options: options, format: format, internalAddress: internalAddress)
    }

    /// Creates a `FriendlyAddress` by parsing a base64/base64URL string (with optional flags).
    /// Returns `nil` if decoding or CRC checks fail.
    ///
    /// - Parameter rawValue: The base64/base64URL string containing:
    ///  1-byte header + up to 4 bytes for workchain + 32 bytes of hash + 2-byte CRC16.
    ///
    /// **Example**:
    /// ```swift
    /// if let friendly = FriendlyAddress(rawValue: "EQCb...") {
    ///    print("Decoded friendly address: \(friendly)")
    /// }
    /// ```
    public init?(rawValue: String) {
        var format: Format = .base64URL

        let base64URLUnescapedString = rawValue.base64URLUnescaped()
        if base64URLUnescapedString == rawValue {
            format = .base64
        }

        guard let data = Data(base64Encoded: base64URLUnescapedString), data.count >= 36
        else {
            return nil
        }

        var value = data[0 ..< data.count - 2]
        guard value.crc16citt().withUnsafeBytes({ Data($0) }) == Data(data.suffix(2))
        else {
            return nil
        }

        var header = value[0]
        value = value.dropFirst(1)

        var options: Options = []
        if header & FriendlyAddress.testableFlag != 0 {
            options.insert(.testable)
            header ^= FriendlyAddress.testableFlag
        }

        switch header {
        case FriendlyAddress.bounceableFlag: options.insert(.bounceable)
        case FriendlyAddress.nonBounceableFlag: break
        default: return nil
        }

        let workchain = Workchain(data: Data(value.prefix(value.count - 32)))
        let hash = Data(value.suffix(32))

        guard let internalAddress = InternalAddress(workchain: workchain, hash: hash)
        else {
            return nil
        }

        self.init(options: options, format: format, internalAddress: internalAddress)
    }

    private init(options: Options, format: Format, internalAddress: InternalAddress) {
        self.options = options
        self.format = format
        self.internalAddress = internalAddress
    }

    // MARK: Public

    /// Various flags that can alter how the address is used or represented
    /// (e.g., `.bounceable`, `.testable`).
    public let options: Options

    /// The encoding style for this address, either `.base64` or `.base64URL`.
    public let format: Format

    /// Returns the `workchain` extracted from `rawAddress.workchain`.
    @inlinable @inline(__always)
    public var workchain: Workchain { internalAddress.workchain }

    /// A 32-byte hash from the underlying `RawAddress`.
    @inlinable @inline(__always)
    public var hash: Data { internalAddress.hash }

    /// A base64/base64URL-encoded string containing:
    /// 1. 1 byte header for bounce/test
    /// 2. up to 4 bytes for `workchain`
    /// 3. 32 bytes for the hash
    /// 4. 2-byte CRC16 at the end
    ///
    /// **Example**:
    /// ```swift
    /// let s = friendly.rawValue
    /// print(s) // "EQC...someBase64String"
    /// ```
    public var rawValue: String { stringValue() }

    /// Produces the string used by `rawValue`, optionally overriding the default
    /// `options` or `format`.
    ///
    /// - Parameters:
    ///  - anotherOptions: If specified, use these instead of `self.options`.
    ///  - anotherFormat: If specified, use this instead of `self.format`.
    /// - Returns: The encoded address string with a 2-byte CRC.
    public func stringValue(
        _ anotherOptions: Options? = nil,
        _ anotherFormat: Format? = nil
    ) -> String {
        let options = anotherOptions ?? options
        let format = anotherFormat ?? format

        var header: UInt8 = 0x00
        if options.contains(.bounceable) {
            header = FriendlyAddress.bounceableFlag
        } else {
            header = FriendlyAddress.nonBounceableFlag
        }

        if options.contains(.testable) {
            header = header | 0x80
        }

        var value = [UInt8]()
        value.append(header)
        value.append(contentsOf: internalAddress.workchain.data().removingLeadingZeros())
        value.append(contentsOf: internalAddress.hash)

        let base64String = Data(value + value.crc16citt()).base64EncodedString()
        return switch format {
        case .base64: base64String
        case .base64URL: base64String.base64URLEscaped()
        }
    }

    // MARK: Internal

    @usableFromInline
    let internalAddress: InternalAddress

    // MARK: Private

    private static let testableFlag: UInt8 = 0x80
    private static let bounceableFlag: UInt8 = 0x11
    private static let nonBounceableFlag: UInt8 = 0x51
}

// MARK: LosslessStringConvertible

extension FriendlyAddress: LosslessStringConvertible {
    /// A textual representation of the address, identical to rawValue.
    /// Typically, a base64 or base64URL string with optional flags.
    ///
    /// **Example**:
    /// ```swift
    /// let desc = friendly.description
    /// print(desc) // e.g. "EQA...someBase64Encoded"
    /// ```
    @inlinable @inline(__always)
    public var description: String { rawValue }

    /// Constructs a `FriendlyAddress` from a string. Returns `nil` if parsing fails.
    ///
    /// **Example**:
    /// ```swift
    /// let addr = FriendlyAddress("EQA...")
    /// if let a = addr {
    ///  print("Got address: \(a)")
    /// }
    /// ```
    public init?(_ description: String) {
        guard let value = FriendlyAddress(rawValue: description)
        else {
            return nil
        }
        self = value
    }
}

// MARK: CustomDebugStringConvertible

extension FriendlyAddress: CustomDebugStringConvertible {
    /// Same as `.description`.
    @inlinable @inline(__always)
    public var debugDescription: String { description }
}

public extension String.StringInterpolation {
    /// Inserts the `.description` form of FriendlyAddress into a string interpolation.
    ///
    /// **Example**:
    /// ```swift
    /// print("Address is: \\(friendly)")
    /// ```
    mutating func appendInterpolation(_ friendlyAddress: FriendlyAddress) {
        appendLiteral("\(friendlyAddress.description)")
    }
}

// MARK: - FriendlyAddress + ExpressibleByStringLiteral

extension FriendlyAddress: ExpressibleByStringLiteral {
    /// Creates a FriendlyAddress from a string literal.
    /// Crashes if the string is invalid.
    ///
    /// **Example**:
    /// ```swift
    /// let addr: FriendlyAddress = "EQAZ..."
    /// ```
    public init(stringLiteral value: StringLiteralType) {
        guard let address = FriendlyAddress(rawValue: value)
        else {
            fatalError("Couldn't decode \(value) as `FriendlyAddress`")
        }
        self = address
    }
}

// MARK: - FriendlyAddress + Sendable

extension FriendlyAddress: Sendable {}

// MARK: - FriendlyAddress + Hashable

extension FriendlyAddress: Hashable {}

// MARK: - FriendlyAddress.Format

public extension FriendlyAddress {
    /// The encoding format used for storing/reading the address:
    /// - .base64
    /// - .base64URL (default)
    ///
    /// Affects how the final string representation is escaped/unescaped.
    enum Format {
        case base64
        case base64URL
    }
}

// MARK: - FriendlyAddress.Format + Sendable

extension FriendlyAddress.Format: Sendable {}

// MARK: - FriendlyAddress.Format + Hashable

extension FriendlyAddress.Format: Hashable {}

// MARK: - FriendlyAddress.Options

public extension FriendlyAddress {
    struct Options: OptionSet {
        // MARK: Lifecycle

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        // MARK: Public

        /// If not set, address is non-bounceable (uses 0x51 header). If set, uses 0x11 header.
        public static let bounceable = Self(rawValue: 1 << 0)

        /// If set, address is flagged as “testable,” indicated by highest bit (0x80).
        public static let testable = Self(rawValue: 1 << 1)

        public let rawValue: Int
    }
}

// MARK: - FriendlyAddress.Options + Sendable

extension FriendlyAddress.Options: Sendable {}

// MARK: - FriendlyAddress.Options + Hashable

extension FriendlyAddress.Options: Hashable {}
