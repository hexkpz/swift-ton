//
//  Created by Anton Spivak
//

import Foundation

// MARK: - Cell + ExpressibleByStringInterpolation

extension Cell: ExpressibleByStringInterpolation {
    /// Creates a new `Cell` from a string literal containing only bits.
    /// All characters are interpreted as bit values (`"0"` or `"1"`),
    /// and appended to the cell’s storage. If any invalid character or
    /// other error occurs, this method calls `fatalError(_:)`.
    ///
    /// **Example**:
    /// ```swift
    /// let cell: Cell = "101101"
    /// // The cell now contains bits [1,0,1,1,0,1]
    /// ```
    public init(stringLiteral value: String) {
        var interpolation = StringInterpolation(literalCapacity: 0, interpolationCount: 0)
        interpolation.appendLiteral(value)
        self.init(stringInterpolation: interpolation)
    }

    /// Creates a `Cell` from the string interpolation data, interpreting
    /// each inserted piece (bits, integers, child cells, etc.) as a
    /// `CellComponent`. The resulting cell is `.ordinary`.
    ///
    /// If building the cell fails for any reason (e.g., constraints are
    /// violated), this method calls `fatalError(_:)`.
    ///
    /// **Example**:
    /// ```swift
    /// let c: Cell = "100 \(true) 0"
    /// // Interprets "100" as bits, appends a `true` bit, then a `false` bit
    /// // If an error occurs, 'fatalError' is triggered
    /// ```
    public init(stringInterpolation: StringInterpolation) {
        do {
            self = try stringInterpolation.components.build(.ordinary)
        } catch {
            fatalError("Couldn't build Cell from \(stringInterpolation)")
        }
    }
}

// MARK: - Cell.StringInterpolation

public extension Cell {
    /// A custom string interpolation type that collects bits, integers,
    /// `Cell` references, or `CellEncodable` objects and transforms them
    /// into `CellComponent`s, which are later combined into a single cell.
    ///
    /// This enables a DSL-like syntax where you embed data directly
    /// in a string literal to construct a `Cell`.
    struct StringInterpolation: StringInterpolationProtocol {
        // MARK: Lifecycle

        public init(literalCapacity: Int, interpolationCount: Int) {}

        // MARK: Public

        /// Appends a raw string literal, trimming whitespace/newlines,
        /// and interprets all remaining characters as bits (`'0'` or `'1'`).
        /// If invalid characters are found, they are ignored or cause a
        /// `BitStorage` parse failure.
        public mutating func appendLiteral(_ literal: String) {
            components.append(.init(BitStorage(
                stringLiteral: literal.trimmingCharacters(in: .whitespacesAndNewlines)
            )))
        }

        // MARK: Internal

        // The list of captured `CellComponent`s forming the final cell.
        var components: [CellComponent] = []
    }
}

public extension Cell.StringInterpolation {
    /// Interpolates a single `Bool` into the cell, storing one bit.
    mutating func appendInterpolation(_ value: Bool) {
        components.append(.init(value))
    }

    /// Interpolates a `BitStorage`, appending all bits into the cell storage.
    mutating func appendInterpolation(_ value: BitStorage) {
        components.append(.init(value))
    }

    /// Interpolates a `Data`, writing its bytes in big-endian order.
    mutating func appendInterpolation(_ value: Data) {
        components.append(.init(value))
    }
}

public extension Cell.StringInterpolation {
    /// Interpolates a fixed-width integer (optionally truncated to `bitWidth`).
    /// - Parameter value: The integer to encode.
    /// - Parameter bitWidth: If non-nil, truncates to that many bits.
    mutating func appendInterpolation<T>(
        _ value: T,
        truncatingToBitWidth bitWidth: Int? = nil
    ) where T: FixedWidthInteger {
        components.append(.init(value, truncatingToBitWidth: bitWidth))
    }

    /// Interpolates an optional integer with a presence bit. If `nil`,
    /// appends `false`. Otherwise, `true` plus the integer.
    ///
    /// - Parameter value: The optional integer to encode.
    /// - Note: `Maybe (X)`
    mutating func appendInterpolation<T>(
        ifPresent value: T?,
        truncatingToBitWidth bitWidth: Int? = nil
    ) where T: FixedWidthInteger {
        components.append(.init(ifPresent: value, truncatingToBitWidth: bitWidth))
    }
}

public extension Cell.StringInterpolation {
    /// Interpolates a `BitStorageConvertible`, appending its bits.
    mutating func appendInterpolation<T>(_ value: T) where T: BitStorageConvertible {
        components.append(.init(value))
    }

    /// Interpolates an optional `BitStorageConvertible`, preceded by a presence bit.
    ///
    /// - Note: `Maybe (X)`
    mutating func appendInterpolation<T>(ifPresent value: T?) where T: BitStorageConvertible {
        components.append(.init(ifPresent: value))
    }

    /// Interpolates an optional `BitStorageConvertible & CustomOptionalBitStorageRepresentable`,
    /// which may use a custom nil bit pattern if `nil`.
    ///
    /// - Note: `Maybe (X)`
    mutating func appendInterpolation<T>(
        ifPresent value: T?
    ) where T: BitStorageConvertible & CustomOptionalBitStorageRepresentable {
        components.append(.init(ifPresent: value))
    }
}

public extension Cell.StringInterpolation {
    /// Interpolates a `CellEncodable` as a new child cell.
    mutating func appendInterpolation<T>(_ value: T) where T: CellEncodable {
        components.append(.init(value))
    }

    /// Interpolates a `CellEncodable`, merging its bits/children
    /// directly into the current container.
    mutating func appendInterpolation<T>(contentsOf value: T) where T: CellEncodable {
        components.append(.init(contentsOf: value))
    }

    /// Interpolates an optional `CellEncodable`, preceded by a presence bit.
    ///
    /// - Note: `Maybe (X)`
    mutating func appendInterpolation<T>(ifPresent value: T?) where T: CellEncodable {
        components.append(.init(ifPresent: value))
    }

    /// Interpolates a `CellEncodable`, attempting to merge it if space remains,
    /// otherwise stores as a child. One bit indicates merging or not.
    ///
    /// - Note: `Either X ^X`
    mutating func appendInterpolation<T>(
        concatIfPossible value: T,
        preserving space: CellContainerSpace? = nil
    ) where T: CellEncodable {
        components.append(.init(concatIfPossible: value, preserving: space))
    }

    /// Interpolates an optional `CellEncodable`, merging if space is available,
    /// otherwise storing as a child. A presence bit is written first.
    ///
    /// - Note: `Maybe (Either X ^X)`
    mutating func appendInterpolation<T>(
        concatIfPossibleIfPresent value: T,
        preserving space: CellContainerSpace? = nil
    ) where T: CellEncodable {
        components.append(.init(concatIfPossibleIfPresent: value, preserving: space))
    }
}

public extension Cell.StringInterpolation {
    /// Interpolates a raw `Cell`, storing it as a child.
    mutating func appendInterpolation(_ value: Cell) {
        components.append(.init(value))
    }

    /// Interpolates the contents of another `Cell` into the current one,
    /// merging its bits/children.
    mutating func appendInterpolation(contentsOf value: Cell) {
        components.append(.init(contentsOf: value))
    }

    /// Interpolates an optional `Cell`, writing a presence bit followed by
    /// either no data or a child cell.
    ///
    /// - Note: `Maybe (X)`
    mutating func appendInterpolation(ifPresent value: Cell?) {
        components.append(.init(ifPresent: value))
    }

    /// Tries to merge a `Cell` if enough space is left, otherwise adds it
    /// as a separate child. One bit is written indicating the approach.
    ///
    /// - Note: `Either X ^X`
    mutating func appendInterpolation(
        concatIfPossible value: Cell,
        preserving space: CellContainerSpace? = nil
    ) {
        components.append(.init(concatIfPossible: value, preserving: space))
    }

    /// Like `concatIfPossible`, but for an optional `Cell`. If `nil`,
    /// writes `false`; if non-nil, attempts merging or child.
    ///
    /// - Note: `Maybe (Either X ^X)`
    mutating func appendInterpolation(
        concatIfPossibleIfPresent value: Cell,
        preserving space: CellContainerSpace? = nil
    ) {
        components.append(.init(concatIfPossibleIfPresent: value, preserving: space))
    }
}
