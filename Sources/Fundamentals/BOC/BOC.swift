//
//  Created by Anton Spivak
//

import Foundation

// MARK: - BOC

/// A representation of a Bag-of-Cells (BOC), which is a serialized
/// container of multiple TON `Cell` objects (root cells plus their sub-trees).
///
/// It can be initialized from raw bytes or from an array of cells. Once created,
/// you can inspect its `cells`, `options`, or `flags`, or convert it back to bytes
/// (`rawValue`).
///
/// **Example**:
/// ```swift
/// // Create a BOC from multiple root cells
/// let boc = try BOC([cellA, cellB])
/// print(boc.rawValue.hexadecimalString) // the BOC's serialized bytes
/// ```
public struct BOC: RawRepresentable {
    // MARK: Lifecycle

    /// Attempts to create a `BOC` from a byte collection. If initialization fails
    /// (e.g., invalid BOC bytes), returns `nil`.
    ///
    /// **Example**:
    /// ```swift
    /// if let boc = BOC(rawValue: someBytes) {
    ///    print("Successfully decoded BOC")
    /// } else {
    ///    print("Failed to decode BOC")
    /// }
    /// ```
    public init?(rawValue: Foundation.Data) {
        try? self.init(rawValue)
    }

    /// Initializes a `BOC` from a byte collection, throwing on invalid data.
    ///
    /// - Parameter rawValue: The serialized bytes that represent a Bag-of-Cells structure.
    /// - Throws: Any decoding error if the bytes cannot be parsed as a valid BOC.
    ///
    /// **Example**:
    /// ```swift
    /// let boc = try BOC(data)
    /// print(boc.cells.count) // check how many root cells
    /// ```
    public init(_ rawValue: Foundation.Data) throws {
        let data = try BOCDecoder(rawValue).decode()
        self.rawValue = rawValue
        self.data = data
    }

    @inlinable @inline(__always)
    public init(_ cell: Cell, options: IncludedOptions = .default) throws {
        try self.init([cell], options: options)
    }

    /// Constructs a `BOC` from a set of root `Cell`s, optionally with
    /// index or CRC32 included in the final bytes. Internally uses `BOCEncoder`.
    ///
    /// - Parameter cells: An array of root `Cell` objects.
    /// - Parameter options: BOC `.indices`, `.crc32c`, or `.cachingBits` flags (default = `.crc32c`).
    /// - Throws: An encoding error if constraints or topological sorting fails.
    ///
    /// **Example**:
    /// ```swift
    /// let boc = try BOC([rootCellA], options: [.crc32c, .indices])
    /// print(boc.rawValue.hexadecimalString)
    /// ```
    public init(_ cells: [Cell], options: IncludedOptions = .default) throws {
        let data = Data(includedOptions: options, headerFlags: (false, false), rootCells: cells)
        self.rawValue = try BOCEncoder(data).encode()
        self.data = data
    }

    // MARK: Public

    /// The raw bytes of this BOC, as a `Data`.
    /// Can be stored or transferred, then reinitialized with `BOC.init(_:)`.
    public let rawValue: Foundation.Data

    /// A pair of boolean flags derived from the BOC header.
    /// Usually `(false, false)` unless a specialized variant was used.
    @inlinable @inline(__always)
    public var flags: (Bool, Bool) { data.headerFlags }

    /// The included BOC options, such as whether an index is present or if a
    /// 4-byte CRC32 is appended.
    @inlinable @inline(__always)
    public var options: IncludedOptions { data.includedOptions }

    /// An array of root `Cell` objects stored in this BOC.
    @inlinable @inline(__always)
    public var cells: [Cell] { data.rootCells }

    // MARK: Internal

    @usableFromInline
    let data: Data
}

// MARK: LosslessStringConvertible

extension BOC: LosslessStringConvertible {
    /// A hex-encoded string of the underlying rawValue.
    ///
    /// **Example**:
    /// ```swift
    /// let bocString = boc.description // hex string
    /// let newBOC = BOC(bocString)
    /// ```
    ///
    @inlinable @inline(__always)
    public var description: String { rawValue.hexadecimalString }

    /// Creates a BOC from a hex string, returning `nil` if the string
    /// cannot be converted to valid BOC bytes.
    ///
    /// **Example**:
    /// ```swift
    /// let hexString = "B5EE9C72..."
    /// let boc = BOC(hexString)
    /// ```
    public init?(_ description: String) {
        guard let rawValue = Foundation.Data(hexadecimalString: description)
        else { return nil }
        self.init(rawValue: rawValue)
    }
}

// MARK: CustomDebugStringConvertible

extension BOC: CustomDebugStringConvertible {
    /// Same as description, returning the hex-encoded BOC bytes for debug logs.
    @inlinable @inline(__always)
    public var debugDescription: String { description }
}

public extension String.StringInterpolation {
    /// Inserts the hex-encoded BOC bytes into a string literal.
    ///
    /// **Example**:
    /// ```swift
    /// let logStr = "BOC raw: \(boc)"
    /// ```
    ///
    mutating func appendInterpolation(_ value: BOC) {
        appendLiteral("\(value.description)")
    }

    /// Inserts a more verbose multiline debug output, including
    /// BOC options, flags, and root cell structure.
    ///
    /// **Example**:
    /// ```swift
    /// let debugStr = "Detailed BOC: \(describing: boc)"
    /// ```
    mutating func appendInterpolation(describing value: BOC) {
        appendLiteral("\n[\(value.hexadecimalString)]\n")
        appendLiteral(" -> indices: \(value.options.contains(.indices))\n")
        appendLiteral(" -> crc32c: \(value.options.contains(.crc32c))\n")
        appendLiteral(" -> cache bits: \(value.options.contains(.cachingBits))\n")
        appendLiteral(" -> flags: \(value.flags)\n")
        appendLiteral(" -> cells (\(value.cells.count)):\n")
        appendLiteral("\(value.cells._described(4))")
    }
}

// MARK: - BOC + ExpressibleByStringLiteral

extension BOC: ExpressibleByStringLiteral {
    /// Creates a BOC from a string literal containing hex-encoded data.
    ///
    /// **Example**:
    /// ```swift
    /// let boc: BOC = "B5EE9C72..."
    /// ```
    ///
    public init(stringLiteral value: StringLiteralType) {
        // Allow multiline string literals
        let trimmed = value.components(separatedBy: .whitespacesAndNewlines).joined()
        guard let boc = BOC(trimmed)
        else { fatalError("Couldn't decode stringLiteral '\(value)' as BOC.") }
        self = boc
    }
}

// MARK: - BOC + Sendable

extension BOC: Sendable {}

// MARK: - BOC + Equatable

extension BOC: Equatable {
    /// Two BOCs are equal if their underlying data (header flags, root cells, etc.)
    /// is identical.
    @inlinable @inline(__always)
    public static func == (lhs: BOC, rhs: BOC) -> Bool {
        lhs.data == rhs.data
    }
}

// MARK: - BOC + Hashable

extension BOC: Hashable {
    /// Hashes the internal data (which includes root cells, header flags, etc.).
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }
}

// MARK: - BOC.HeaderByte

extension BOC {
    /// Represents a BOC header format variant (TL-B).
    enum HeaderByte: UInt32 {
        /// Includes an index (only one root cell)
        case index = 0x68FF_65F3

        /// Includes index + CRC32 (only one root cell)
        case indexWithCRC32c = 0xACC3_A728

        /// General with optional index/CRC (multiple root cells)
        case generic = 0xB5EE_9C72
    }
}

// MARK: - BOC.HeaderByte + Equatable

extension BOC.HeaderByte: Equatable {}

// MARK: - BOC.IncludedOptions

public extension BOC {
    /// An OptionSet specifying which additional features
    /// were included in a BOC.
    ///
    struct IncludedOptions: OptionSet {
        // MARK: Lifecycle

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        // MARK: Public

        /// Has an index table
        public static let indices = Self(rawValue: 1 << 0)

        /// Includes a 4-byte CRC
        public static let crc32c = Self(rawValue: 1 << 1)

        /// BOC sets “cache bits” flag
        ///
        /// - Note: Unsupported yet
        public static let cachingBits = Self(rawValue: 1 << 2)

        /// The default option set includes `.crc32c`.
        public static let `default`: Self = [.crc32c]

        public let rawValue: UInt32
    }
}

// MARK: - BOC.IncludedOptions + Sendable

extension BOC.IncludedOptions: Sendable {}

// MARK: - BOC.IncludedOptions + Hashable

extension BOC.IncludedOptions: Hashable {}
