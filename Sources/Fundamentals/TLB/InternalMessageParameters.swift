//
//  Created by Anton Spivak
//

// MARK: - InternalMessageParameters

/// `MessageParameters` describes how a TON message is configured, combining
/// exactly one `Mode` (0, 64, or 128) with zero or more `Flags` (1, 2, 16, 32).
/// The combination is a simple sum of the mode value plus the flags' raw values.
///
/// According to the official documentation:
/// - Mode determines whether the message is ordinary (0),
///   adds the remaining inbound value (64), or spends the current contract’s
///   entire remaining balance (128).
/// - Flags can be combined to control various message behaviors,
///   such as paying fees separately, ignoring errors, bouncing on failure,
///   or destroying an empty account.
///
/// The sum-based combination means if `rawValue = 66`, for instance,
/// that implies `mode = 64` and `flags = 2`.
public struct InternalMessageParameters {
    // MARK: Lifecycle

    @inlinable @inline(__always)
    public init(mode: Mode, flags: Flags) {
        self.rawValue = mode.rawValue | flags.rawValue
    }

    // MARK: Public

    public let rawValue: UInt8

    public var mode: Mode { Mode(rawValue: rawValue & 0b1100_0000) }
    public var flags: Flags { Flags(rawValue: rawValue & 0b0011_1111) }
}

public extension InternalMessageParameters {
    /// A recommended default message configuration for typical usage,
    /// with `mode = .ordinary`, and the flags:
    /// - `.payMessageFees` = 1
    /// - `.ignoreErrors` = 2
    static let `default` = InternalMessageParameters(
        mode: .ordinary,
        flags: [.payMessageFeesSeparately]
    )
}

// MARK: Hashable

extension InternalMessageParameters: Hashable {}

// MARK: Sendable

extension InternalMessageParameters: Sendable {}

// MARK: InternalMessageParameters.Mode

public extension InternalMessageParameters {
    /// `Mode` is an 8-bit raw value that indicates one of the three possible
    /// special behaviors for the outgoing TON message:
    /// - `0` (ordinary),
    /// - `64` (use inbound leftover),
    /// - `128` (spend contract’s entire remaining balance).
    struct Mode: RawRepresentable {
        // MARK: Lifecycle

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        // MARK: Public

        public let rawValue: UInt8
    }
}

public extension InternalMessageParameters.Mode {
    /// An ordinary message. No special leftover or entire-balance usage.
    static let ordinary = Self(rawValue: 0)

    /// Carry all the remaining value of the inbound message in addition to
    /// the initially indicated value.
    static let addRemainingIncomingValue = Self(rawValue: 64)

    /// Carry the current contract’s entire remaining balance instead of the
    /// indicated value. Typically used with certain flags, such as
    /// `.destroyWhenEmpty`.
    static let addRemainingBalance = Self(rawValue: 128)
}

// MARK: - InternalMessageParameters.Mode + Hashable

extension InternalMessageParameters.Mode: Hashable {}

// MARK: - InternalMessageParameters.Mode + Sendable

extension InternalMessageParameters.Mode: Sendable {}

// MARK: - InternalMessageParameters.Flags

public extension InternalMessageParameters {
    /// `Flags` is an OptionSet representing zero or more bit-level features:
    /// - `.payMessageFees = 1`
    /// - `.ignoreErrors = 2`
    /// - `.spendRemainingBalance = 16`
    /// - `.destroyWhenEmpty = 32`
    ///
    /// Example combination: `[.payMessageFees, .ignoreErrors]` => rawValue = 3.
    struct Flags: OptionSet {
        // MARK: Lifecycle

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        // MARK: Public

        public let rawValue: UInt8
    }
}

public extension InternalMessageParameters.Flags {
    /// Pay transfer fees separately from the message value.
    static let payMessageFeesSeparately = Self(rawValue: 1)

    /// Ignore certain “not enough” errors in the action phase, but
    /// not format or library-related errors. Typically important in external
    /// messages to wallets.
    static let ignoreErrors = Self(rawValue: 2)

    /// If an action fails, bounce the transaction back to the sender.
    /// No effect if `.ignoreErrors` is also used, and not recommended for
    /// external messages to wallets.
    static let spendRemainingBalance = Self(rawValue: 16)

    /// Destroy this account if its balance reaches zero.
    /// Often used with `Mode.addRemainingBalance`.
    static let destroyWhenEmpty = Self(rawValue: 32)
}

// MARK: - InternalMessageParameters.Flags + Hashable

extension InternalMessageParameters.Flags: Hashable {}

// MARK: - InternalMessageParameters.Flags + Sendable

extension InternalMessageParameters.Flags: Sendable {}

// MARK: - InternalMessageParameters + BitStorageRepresentable

extension InternalMessageParameters: BitStorageRepresentable {
    public init(bitStorage: inout ContinuousReader<BitStorage>) throws {
        self.rawValue = try bitStorage.read(UInt8.self)
    }

    public func appendTo(_ bitStorage: inout BitStorage) {
        bitStorage.append(bitPattern: rawValue)
    }
}
