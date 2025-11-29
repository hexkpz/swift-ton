//
//  Created by Anton Spivak
//

import Foundation

// MARK: - Workchain

/// Represents a TON blockchain “workchain” ID.
///
/// A workchain separates accounts (addresses) into different namespaces or
/// shards. For example, -1 is the masterchain, and 0 is the basic workchain.
/// You can also have custom IDs for additional workchains.
///
/// **Example**:
/// ```swift
/// let wcMaster = Workchain.master   // rawValue = -1
/// let wcBasic = Workchain.basic     // rawValue = 0
/// let wcOther = Workchain.other(42) // rawValue = 42
/// print(wcOther)                    // "42"
/// ```
public enum Workchain: RawRepresentable {
    /// workchain ID = `-1`
    case master

    /// workchain ID = `0`
    case basic

    /// arbitrary custom ID
    case other(Int32)

    // MARK: Lifecycle

    /// Creates a `Workchain` from a raw `Int32`. Recognizes `-1` as `.master`,
    /// `0` as `.basic`, or else `.other(...)`.
    ///
    /// - Parameter rawValue: The 32-bit integer representing a workchain ID.
    public init(rawValue: Int32) {
        self = switch rawValue {
        case Workchain.master.rawValue: .master
        case Workchain.basic.rawValue: .basic
        default: .other(rawValue)
        }
    }

    // MARK: Public

    /// Returns the `Int32` representing this workchain:
    /// - `-1` for `.master`
    /// - `0`  for `.basic`
    /// - a custom ID for `.other(Int32)`
    public var rawValue: Int32 {
        switch self {
        case .master: -1
        case .basic: 0
        case let .other(id): id
        }
    }
}

// MARK: LosslessStringConvertible

extension Workchain: LosslessStringConvertible {
    /// Returns a string representation of the workchain's rawValue (e.g., "-1", "0", or a custom ID).
    ///
    /// **Example**:
    /// ```swift
    /// let wc = Workchain(-1)
    /// print(wc.description) // "-1"
    /// ```
    @inlinable @inline(__always)
    public var description: String { "\(rawValue)" }

    /// Creates a `Workchain` from a string by converting it to `Int32`.
    /// Returns `nil` if conversion fails.
    ///
    /// **Example**:
    /// ```swift
    /// let wc = Workchain("-1") // .master
    /// ```
    public init?(_ description: String) {
        guard let rawValue = Int32(description)
        else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}

// MARK: CustomDebugStringConvertible

extension Workchain: CustomDebugStringConvertible {
    /// Same as description, returning the integer ID as a string for debugging.
    @inlinable @inline(__always)
    public var debugDescription: String { description }
}

public extension String.StringInterpolation {
    /// Inserts the workchain’s description in a string interpolation context.
    ///
    /// **Example**:
    /// ```swift
    /// let w = Workchain.master
    /// print("Workchain: \(w)")
    /// // prints "Workchain: -1"
    /// ```
    mutating func appendInterpolation(_ workchain: Workchain) {
        appendLiteral("\(workchain.description)")
    }
}

// MARK: - Workchain + DataRepresentable

extension Workchain: DataRepresentable {
    /// Produces a `Data` from the workchain’s integer ID in the specified
    /// endianness (default is `.big`).
    ///
    /// **Example**:
    /// ```swift
    /// let wc = Workchain.master
    /// let bytes = wc.data() // big-endian 4-byte representation of -1
    /// ```
    public func data(with endianness: Endianness = .big) -> Data {
        rawValue.data(with: endianness)
    }

    /// Initializes a `Workchain` from a `Data`, interpreting the data as
    /// a 32-bit integer in the specified endianness (default is `.big`).
    ///
    /// **Example**:
    /// ```swift
    /// let bytes = Data([0xFF, 0xFF, 0xFF, 0xFF]) // big-endian -1
    /// let wc = Workchain(data: bytes)
    /// // wc => .master
    /// ```
    public init(data: Data, _ endianness: Endianness = .big) {
        self.init(rawValue: Int32(data: data, endianness))
    }
}

// MARK: - Workchain + ExpressibleByIntegerLiteral

extension Workchain: ExpressibleByIntegerLiteral {
    /// Allows creation of a `Workchain` via integer literal (e.g. `Workchain(-1)`).
    ///
    /// **Example**:
    /// ```swift
    /// let chain: Workchain = 0  // .basic
    /// ```
    @inlinable @inline(__always)
    public init(integerLiteral value: Int32) {
        self.init(rawValue: value)
    }
}

// MARK: - Workchain + Sendable

extension Workchain: Sendable {}

// MARK: - Workchain + Hashable

extension Workchain: Hashable {}
