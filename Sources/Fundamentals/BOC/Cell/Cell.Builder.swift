//
//  Created by Anton Spivak
//

import Foundation

public extension Cell {
    /// Creates a new `Cell` of a specified `kind` by gathering all `CellComponent` items from
    /// a closure annotated with the `@Builder` result-builder. This allows a concise, DSL-like
    /// approach to building cells.
    ///
    /// - Parameters:
    ///   - kind: The desired `Cell.Kind` (e.g. `.ordinary`); defaults to `.ordinary`.
    ///   - builder: A closure (using `Cell.Builder`) that returns an array of `CellComponent`s.
    /// - Throws:
    ///   - `CellEncodingError` if the final cell exceeds storage or child limits.
    ///   - Any other error arising from encoding failures.
    /// - Returns: A newly constructed `Cell` containing all specified bits, integers, child cells, etc.
    ///
    /// **Example**:
    /// ```swift
    /// let cell = try Cell(.ordinary) {
    ///     true                  // encodes one bit
    ///     "1101"                // encodes BitStorage from the literal "1101"
    ///     BitStorage("1001001") // another bits sequence
    ///     try Cell() { false }  // child cell with one 'false' bit
    ///     UInt32(42)            // encodes 42 as a 32-bit integer
    ///     MyCellEncodable()     // encodes a user-defined struct as a child cell
    /// }
    /// // 'cell' now has all these components combined into a single .ordinary cell
    /// ```
    init(
        _ kind: Kind = .ordinary,
        @Builder _ builder: () throws -> Builder.FinalResult
    ) throws {
        self = try builder().build(kind)
    }

    /// Provides a closure-based API to decode data from this cell’s bits and children.
    ///
    /// This method wraps the cell in a `CellDecodingContainer`, then calls your closure,
    /// giving you direct access to decode bits and child cells. You can construct or parse
    /// arbitrary types by reading from the container.
    ///
    /// - Parameter body: A closure that receives an inout `CellDecodingContainer`, from which
    ///   it can decode bits, integers, child cells, etc. Must return a type `T`.
    /// - Returns: The value `T` produced by decoding within the closure.
    /// - Throws: Any decoding errors or container-boundary errors that arise from reading
    ///   insufficient bits or children.
    ///
    /// **Example**:
    /// ```swift
    /// let cell: Cell = ... // previously built or fetched
    /// let result = try cell.decode { container in
    ///     return try container.decode(UInt32.self)
    /// }
    /// print(result)
    /// ```
    func decode<T>(
        _ body: (_ container: inout CellDecodingContainer) throws -> T
    ) rethrows -> T {
        var container = CellDecodingContainer(self)
        return try body(&container)
    }
}

// MARK: - Cell.Builder

public extension Cell {
    /// A result-builder that converts Swift expressions (bits, integers, child cells, etc.)
    /// into an array of `CellComponent`, which can then be combined into a final `Cell`.
    ///
    /// Typically used via:
    /// ```swift
    /// let myCell = try Cell(.ordinary) {
    ///     true
    ///     "1010"
    ///     BitStorage("1100")
    ///     UInt32(123)
    ///     try Cell() { false }
    ///     MyEncodableStruct()
    /// }
    /// ```
    @resultBuilder
    enum Builder {
        // MARK: Public

        public typealias Component = [CellComponent]
        public typealias FinalResult = [CellComponent]

        public static func buildBlock(_ components: Component...) -> Component {
            components.flatMap({ $0 })
        }

        public static func buildBlock(_ component: Component) -> Component {
            component
        }

        public static func buildArray(_ components: [Component]) -> Component {
            components.flatMap({ $0 })
        }

        public static func buildOptional(_ component: Component?) -> Component {
            guard let component
            else {
                return []
            }
            return component
        }

        public static func buildLimitedAvailability(_ component: Component) -> Component {
            component
        }

        public static func buildEither(first component: Component) -> Component { component }
        public static func buildEither(second component: Component) -> Component { component }

        // MARK: Internal

        static func buildFinalResult(_ component: Component) -> Component { component }
    }
}

public extension Cell.Builder {
    /// Interprets a `Bool` expression as a single-bit `CellComponent`.
    static func buildExpression(_ expression: Bool) -> Component {
        [CellComponent(expression)]
    }

    /// Interprets a `CellComponent` directly (already formed).
    static func buildExpression(_ expression: CellComponent) -> Component {
        [expression]
    }

    /// Interprets a `BitStorage` as bits in the final cell.
    static func buildExpression(_ expression: BitStorage) -> Component {
        [CellComponent(expression)]
    }

    /// Interprets a string as `BitStorage(stringLiteral: expression)`.
    /// Each character must be `'0'` or `'1'` to be valid.
    static func buildExpression(_ expression: String) -> Component {
        [CellComponent(BitStorage(stringLiteral: expression))]
    }

    /// Interprets a sequence of `Bool` as a `BitStorage`.
    static func buildExpression<T>(
        _ expression: T
    ) -> Component where T: Sequence, T.Element == Bool {
        [CellComponent(BitStorage(expression))]
    }

    /// Interprets a `Data` as bits in big-endian order.
    static func buildExpression(_ expression: Data) -> Component {
        [CellComponent(expression)]
    }

    /// Encodes a fixed-width integer (e.g., Int32, UInt64).
    static func buildExpression<T>(_ expression: T) -> Component where T: FixedWidthInteger {
        [CellComponent(expression)]
    }

    /// Encodes any `BitStorageConvertible` object (e.g., raw bytes).
    static func buildExpression<T>(_ expression: T) -> Component where T: BitStorageConvertible {
        [CellComponent(expression)]
    }

    /// Interprets a literal `Cell` expression as a child cell.
    static func buildExpression(_ expression: Cell) -> Component {
        [CellComponent(expression)]
    }

    /// Encodes any `CellEncodable` object as a new child cell.
    static func buildExpression<T>(_ expression: T) -> Component where T: CellEncodable {
        [CellComponent(expression)]
    }
}
