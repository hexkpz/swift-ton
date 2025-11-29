//
//  Created by Anton Spivak
//

import BigInt

// MARK: - CurrencyValue

/// A lightweight value type representing a currency amount with arbitrary precision.
///
/// `CurrencyValue` stores a `BigUInt` representing the integer value and
/// a `decimals` count that indicates where the decimal point appears.
/// You can create a `CurrencyValue` from a string (e.g., `"123.45"`),
/// a floating-point or integer literal, or manually by providing
/// `BigUInt` and `decimals`.
public struct CurrencyValue {
    // MARK: Lifecycle

    /// Creates a new `CurrencyValue` from a `BigUInt`.
    ///
    /// - Parameter rawValue: The raw integer representation of the currency amount
    public init(rawValue: BigUInt) {
        self.rawValue = rawValue
    }

    /// Creates a new `CurrencyValue` from a decimal string.
    ///
    /// - Parameter rawValue: A string representing a non-negative decimal number,
    ///   interpreted with the default scale of 9 fractional digits.
    public init?(rawValue: String) {
        guard let rawValue = BigUInt(rawValue) else { return nil }
        self.init(rawValue: rawValue)
    }

    /// Internal initializer that interprets a string with a given scale.
    ///
    /// - Parameters:
    ///   - value: The string to parse (e.g., "123.45").
    ///   - interpretLike: The number of fractional digits to use when parsing.
    public init?<T>(_ value: T, interpretLike decimals: UInt?) where T: StringProtocol {
        let parts = value.components(separatedBy: ".")

        let lhs: String
        let rhs: String

        switch parts.count {
        case 1:
            lhs = parts[0]
            rhs = ""
        case 2:
            lhs = parts[0]
            rhs = parts[1]
        default:
            return nil
        }

        guard lhs.trimmingCharacters(in: .decimalDigits.inverted).count == lhs.count,
              rhs.trimmingCharacters(in: .decimalDigits.inverted).count == rhs.count,
              !lhs.isEmpty
        else {
            return nil
        }

        var _value: BigUInt?
        if let decimals, rhs.count < decimals {
            // If decimals are specified and the fraction is too short, pad with zeros.
            let remaining = decimals - UInt(rhs.count)
            let _rhs = rhs + String(repeating: "0", count: Int(remaining))

            _value = BigUInt("\(lhs)\(_rhs)", radix: 10)
        } else if let decimals, rhs.count > decimals {
            // If decimals are specified and the fraction is too long, cut and possibly round.
            let overdo = UInt(rhs.count) - decimals
            let suffix = rhs.suffix(Int(overdo))

            let _rhs = rhs.dropLast(Int(overdo))
            _value = BigUInt("\(lhs)\(_rhs)", radix: 10)

            // Basic "round half up" logic: if the dropped part >= half of 10^(overdo), round up by 1.
            if let _suffix = BigUInt(suffix, radix: 10),
               _suffix * 2 >= BigUInt(10).power(Int(overdo))
            {
                _value = switch _value {
                case .none: nil
                case let .some(value): value + 1
                }
            }
        } else {
            // Otherwise, just treat the entire string as "lhs + rhs"
            _value = BigUInt("\(lhs)\(rhs)", radix: 10)
        }

        guard let _value
        else {
            return nil
        }

        self.rawValue = _value
    }

    // MARK: Public

    /// The raw integer representation of this currency value.
    public let rawValue: BigUInt
}

// MARK: Sendable

extension CurrencyValue: Sendable {}

// MARK: Hashable

extension CurrencyValue: Hashable {}

public extension CurrencyValue {
    @inlinable @inline(__always)
    static func + (lhs: Self, rhs: Self) -> Self {
        CurrencyValue(rawValue: lhs.rawValue + rhs.rawValue)
    }

    @inlinable @inline(__always)
    static func - (lhs: Self, rhs: Self) -> Self {
        CurrencyValue(rawValue: lhs.rawValue - rhs.rawValue)
    }
}

public extension CurrencyValue {
    @inlinable @inline(__always)
    static func + <T>(lhs: CurrencyValue, rhs: T) -> Self where T: FixedWidthInteger {
        CurrencyValue(rawValue: lhs.rawValue + BigUInt(rhs))
    }

    @inlinable @inline(__always)
    static func - <T>(lhs: CurrencyValue, rhs: T) -> Self where T: FixedWidthInteger {
        CurrencyValue(rawValue: lhs.rawValue - BigUInt(rhs))
    }

    @inlinable @inline(__always)
    static func * <T>(lhs: CurrencyValue, rhs: T) -> Self where T: FixedWidthInteger {
        CurrencyValue(rawValue: lhs.rawValue * BigUInt(rhs))
    }

    @inlinable @inline(__always)
    static func / <T>(lhs: CurrencyValue, rhs: T) -> Self where T: FixedWidthInteger {
        CurrencyValue(rawValue: lhs.rawValue / BigUInt(rhs))
    }
}

public extension String {
    /// Initializes a new string from a `CurrencyValue` by inserting a decimal point in the correct position.
    ///
    /// - Parameters:
    ///   - value: The `CurrencyValue` representing an integer amount in the smallest units.
    ///   - decimals: The number of fractional digits (scale) to use (default is 9).
    ///
    /// Examples:
    /// ```swift
    /// let value = CurrencyValue(rawValue: "123456")   // rawValue = 123456
    /// String(value, decimals: 3)                      // "123.456"
    /// String(value, decimals: 6)                      // "0.123456"
    /// String(value, decimals: 0)                      // "123456"
    /// ```
    init(_ value: CurrencyValue, decimals: UInt) {
        let rawString = String(value.rawValue, radix: 10)
        if rawString.count > decimals {
            let integerPart = rawString.prefix(rawString.count - Int(decimals))
            // Only include decimal separator if there is at least one fractional digit
            let suffix = decimals > 0 ? ".\(rawString.suffix(Int(decimals)))" : ""
            self = "\(integerPart)\(suffix)"
        } else {
            let padding = String(repeating: "0", count: Int(decimals) - rawString.count)
            // Always include "0." prefix when scale > 0
            self = decimals > 0 ? "0.\(padding)\(rawString)" : rawString
        }
    }

    /// Options for formatting `CurrencyValue` when converting to string.
    struct CurrencyValueFormat {
        // MARK: Lifecycle

        /// Creates a new format configuration.
        ///
        /// - Parameters:
        ///   - maximumFractionDigits: Maximum allowed fraction digits (default 9).
        ///   - minimumFractionDigits: Minimum fraction digits to pad (default 2).
        ///   - decimalSeparator: Character to use as decimal separator (default ".").
        ///   - groupingSeparator: Character to use as grouping separator (default ",").
        ///   - removesTrailingZeros: Removes trailing zeros from fraction part if needed
        public init(
            maximumFractionDigits: UInt = 9,
            minimumFractionDigits: UInt = 2,
            decimalSeparator: String = ".",
            groupingSeparator: String = ",",
            removesTrailingZeros: Bool = true
        ) {
            self.maximumFractionDigits = maximumFractionDigits
            self.minimumFractionDigits = minimumFractionDigits
            self.decimalSeparator = decimalSeparator
            self.groupingSeparator = groupingSeparator
            self.removesTrailingZeros = removesTrailingZeros
        }

        // MARK: Public

        /// Maximum number of fraction digits to display.
        public var maximumFractionDigits: UInt

        /// Minimum number of fraction digits to display (pads with zeros if needed).
        public var minimumFractionDigits: UInt

        /// Character to use as decimal separator (e.g., ".").
        public var decimalSeparator: String

        /// Character to use as grouping (thousands) separator (e.g., ",").
        public var groupingSeparator: String

        /// Removes trailing zeros from fraction part if needed
        public var removesTrailingZeros: Bool
    }

    /// Initializes a formatted string from a `CurrencyValue` using the given format options.
    ///
    /// - Parameters:
    ///   - value: The `CurrencyValue` representing an integer amount in the smallest units.
    ///   - decimals: The number of fractional digits (scale) used to divide the raw value (default is 9).
    ///   - format: Formatting options (grouping, decimal separators, fraction digit limits).
    ///
    /// Examples:
    /// ```swift
    /// let value = CurrencyValue(rawValue: "123456")   // rawValue = 123456
    /// let format = CurrencyValueFormat(maximumFractionDigits: 2, minimumFractionDigits: 2)
    ///
    /// String(value, decimals: 3, format: format) // "123.46"  // rounded from "123.456"
    /// ```
    init(_ value: CurrencyValue, decimals: UInt = 9, format: CurrencyValueFormat = .init()) {
        let string = String(value, decimals: decimals)
        let parts = string.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)

        var integer = String(parts[0])
        var fraction = parts.count > 1 ? String(parts[1]) : ""

        if decimals > 0 {
            if fraction.count < Int(format.minimumFractionDigits) {
                let paddingCount = Int(format.minimumFractionDigits) - fraction.count
                fraction += String(repeating: "0", count: paddingCount)
            } else if fraction.count > Int(format.maximumFractionDigits) {
                let rounded = (integer + "." + fraction).roundingHalfUp(
                    to: Int(format.maximumFractionDigits)
                )
                integer = rounded.integer
                fraction = rounded.fractional
            }

            if format.removesTrailingZeros {
                while fraction.last == "0",
                      fraction.count > Int(format.minimumFractionDigits)
                {
                    fraction.removeLast()
                }
            }
        } else {
            fraction = ""
        }

        let groupedInteger = integer.group(with: format.groupingSeparator)
        self = decimals > 0 && !fraction.isEmpty
            ? "\(groupedInteger)\(format.decimalSeparator)\(fraction)"
            : groupedInteger
    }

    /// Rounds a decimal string "half up" to the given scale.
    @usableFromInline
    internal func roundingHalfUp(to scale: Int) -> (integer: String, fractional: String) {
        let parts = split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)

        var integerPart = String(parts[0])
        let fractionPart = parts.count > 1 ? String(parts[1]) : ""

        if fractionPart.count <= scale {
            let padding = String(repeating: "0", count: scale - fractionPart.count)
            return (integerPart, fractionPart + padding)
        }

        let cutoff = fractionPart.index(fractionPart.startIndex, offsetBy: scale)
        var kept = String(fractionPart[..<cutoff])
        let firstDiscarded = fractionPart[cutoff]

        if firstDiscarded >= "5" {
            let plusResult = kept.plusOne()
            kept = plusResult.result
            if plusResult.carry > 0 {
                integerPart = integerPart.plusOne().result
            }
            if kept.count > scale {
                kept.removeFirst(kept.count - scale)
            }
        }

        return (integerPart, kept)
    }

    /// Increments a numeric string by one, returning the new string and any carry-out.
    @usableFromInline
    internal func plusOne() -> (result: String, carry: Int) {
        var digits = Array(self)
        var carry = 1
        for i in (0 ..< digits.count).reversed() {
            let sum = Int(String(digits[i]))! + carry
            digits[i] = Character(String(sum % 10))
            carry = sum / 10
            if carry == 0 { break }
        }
        if carry > 0 {
            digits.insert("1", at: 0)
        }
        return (String(digits), carry)
    }

    /// Groups digits in a numeric string using the provided separator every three digits.
    @usableFromInline
    internal func group(with separator: String) -> String {
        var result = ""
        for (i, char) in reversed().enumerated() {
            if i > 0 && i % 3 == 0 {
                result.append(separator)
            }
            result.append(char)
        }
        return String(result.reversed())
    }
}

public extension String.StringInterpolation {
    /// Interpolates a `CurrencyValue` into a string with given scale.
    ///
    /// - Parameters:
    ///   - value: The `CurrencyValue` to format.
    ///   - decimals: The number of fractional digits to use (default is 9).
    ///   - format: Formatting options (grouping, decimal separators, fraction digit limits).
    mutating func appendInterpolation(
        _ value: CurrencyValue,
        decimals: UInt = 9,
        format: String.CurrencyValueFormat = .init()
    ) {
        appendInterpolation("\(String(value, decimals: decimals, format: format))")
    }
}

// MARK: - CurrencyValue + LosslessStringConvertible

extension CurrencyValue: LosslessStringConvertible {
    /// A textual representation of this `CurrencyValue`, using 9 fractional digits.
    @inlinable @inline(__always)
    public var description: String { String(self, decimals: 9) }

    /// Creates a `CurrencyValue` from a decimal string with 9 fractional digits.
    @inlinable @inline(__always)
    public init?(_ description: String) {
        self.init(description, interpretLike: 9)
    }
}

// MARK: - CurrencyValue + CustomDebugStringConvertible

extension CurrencyValue: CustomDebugStringConvertible {
    /// A debug string describing this `CurrencyValue` (same as `description`).
    @inlinable @inline(__always)
    public var debugDescription: String { description }
}

// MARK: - CurrencyValue + ExpressibleByStringLiteral

extension CurrencyValue: ExpressibleByStringLiteral {
    /// Creates a `CurrencyValue` from a string literal. Crashes if the literal
    /// is invalid or negative.
    ///
    /// ```swift
    /// let price: CurrencyValue = "123.45"
    /// ```
    ///
    /// - Parameter value: A string literal representing a decimal number.
    public init(stringLiteral value: StringLiteralType) {
        guard let value = Self(value, interpretLike: 9)
        else { fatalError("Couldn't convert \(value) to CurrencyValue") }
        self = value
    }
}

// MARK: - CurrencyValue + ExpressibleByIntegerLiteral

extension CurrencyValue: ExpressibleByIntegerLiteral {
    /// Creates a `CurrencyValue` from an integer literal (scale 9).
    ///
    /// ```swift
    /// let tokens: CurrencyValue = 100
    /// ```
    ///
    /// - Parameter value: An integer literal.
    public init(integerLiteral value: IntegerLiteralType) {
        guard let value = Self("\(value)", interpretLike: 9)
        else { fatalError("Couldn't convert \(value) to CurrencyValue") }
        self = value
    }

    /// Creates a `CurrencyValue` from an unsigned integer (scale 9).
    ///
    /// - Parameter value: An unsigned integer to be represented as a `CurrencyValue`.
    @inlinable @inline(__always)
    public init<T>(_ value: T) where T: UnsignedInteger {
        self.init("\(value)", interpretLike: 9)!
    }

    /// Creates a `CurrencyValue` from a signed integer (scale 9), or nil if negative.
    ///
    /// - Parameter value: A signed integer to be represented, must be non-negative.
    @inlinable @inline(__always)
    public init?<T>(_ value: T) where T: SignedInteger {
        guard value >= 0 else { return nil }
        self.init("\(value)", interpretLike: 9)
    }
}

// MARK: - CurrencyValue + ExpressibleByFloatLiteral

extension CurrencyValue: ExpressibleByFloatLiteral {
    /// Creates a `CurrencyValue` from a float literal (scale 9).
    ///
    /// ```swift
    /// let price: CurrencyValue = 99.99
    /// ```
    ///
    /// - Parameter value: A floating-point literal representing a non-negative
    ///   decimal number.
    @inlinable @inline(__always)
    public init(floatLiteral value: FloatLiteralType) {
        guard let value = Self("\(value)", interpretLike: 9)
        else { fatalError("Couldn't convert \(value) to CurrencyValue") }
        self = value
    }

    /// Creates a `CurrencyValue` from any floating-point value (scale 9), or nil if negative.
    ///
    /// - Parameter value: A floating-point value to be represented.
    @inlinable @inline(__always)
    public init?<T>(_ value: T) where T: FloatingPoint {
        guard value >= 0
        else { return nil }
        self.init("\(value)", interpretLike: 9)
    }
}

// MARK: - CurrencyValue + BitStorageRepresentable

extension CurrencyValue: BitStorageRepresentable {
    public init(bitStorage: inout ContinuousReader<BitStorage>) throws {
        self = try CurrencyValue(rawValue: VUInt4(bitStorage: &bitStorage).rawValue)
    }

    public func appendTo(_ bitStorage: inout BitStorage) {
        VUInt4(rawValue).appendTo(&bitStorage)
    }
}
