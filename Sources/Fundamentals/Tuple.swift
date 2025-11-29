//
//  Created by Anton Spivak
//

import Foundation

// MARK: - Tuple

/// A low-level representation of TVM method arguments or return values,
/// composed of ordered elements.
public struct Tuple: RawRepresentable, Sendable, Hashable {
    // MARK: Lifecycle

    /// Creates a `Tuple` from an array of `Element` values.
    /// - Parameter rawValue: The elements to include in order.
    public init(rawValue: [Element]) {
        self.rawValue = rawValue
    }

    // MARK: Public

    /// Underlying storage of elements in sequence.
    public let rawValue: [Element]
}

// MARK: Tuple.Element

public extension Tuple {
    /// An individual element in a `Tuple`, representing one TVM value.
    enum Element: Sendable, Hashable {
        /// A numeric value, represented by a big-endian byte collection.
        case number(Data)

        /// A nested contract data cell.
        case cell(Cell)

        /// A raw byte slice of data as `Cell`.
        case slice(Cell)

        // MARK: Public

        public static func slice<T>(_ value: T) throws -> Self where T: BitStorageConvertible {
            return try .slice(Cell { value })
        }

        public static func slice<T>(_ value: T) throws -> Self where T: CellEncodable {
            return try .slice(Cell(value))
        }

        public static func slice(_ value: Data) throws -> Self {
            return try .slice(Cell { value })
        }
    }
}
