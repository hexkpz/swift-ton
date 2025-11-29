//
//  Created by Anton Spivak
//

import Foundation

// MARK: - Cell.ConstraintError

public extension Cell {
    /// An error indicating that one of the cell’s storage or children constraints
    /// was violated (e.g., too many bits, insufficient children).
    struct ConstraintError: Swift.Error {
        // MARK: Lifecycle

        /// Creates a new `ConstraintError` describing a mismatch between a
        /// constraint (`min`, `exactly`, or `max`) and the actual count.
        ///
        /// - Parameters:
        ///  - constraintKind: The specific constraint (minimum, exactly, maximum).
        ///  - cellKind: The cell kind (e.g. `.ordinary`).
        ///  - trait: Indicates whether the error is about `storage` bits or `children`.
        ///  - value: The actual number that violated the constraint.
        init(
            _ constraintKind: Kind,
            _ cellKind: Cell.Kind,
            _ trait: CellTrait,
            _ value: Int
        ) {
            self.constraintKind = constraintKind
            self.cellKind = cellKind
            self.trait = trait
            self.value = value
        }

        // MARK: Internal

        let constraintKind: Kind
        let cellKind: Cell.Kind

        let trait: CellTrait
        let value: Int
    }
}

// MARK: - Cell.ConstraintError + CustomStringConvertible

extension Cell.ConstraintError: CustomStringConvertible {
    /// A user-friendly textual description of the constraint mismatch.
    ///
    /// **Example**:
    /// ```
    /// "Cell (Ordinary) requires that storage must have at most 1023 bits, but got 1200."
    /// ```
    public var description: String {
        let constraintMessage: String
        switch constraintKind {
        case let .minimum(minimum): constraintMessage = "must have at least \(minimum)"
        case let .exactly(exactly): constraintMessage = "must have exactly \(exactly)"
        case let .maximum(maximum): constraintMessage = "must have at most \(maximum)"
        }
        let traitSuffixMessage: String
        switch trait {
        case .storage: traitSuffixMessage = "bits"
        case .children: traitSuffixMessage = "children"
        }
        return "Cell (\(cellKind)) requires that \(trait) \(constraintMessage) \(traitSuffixMessage), but got \(value)."
    }
}

// MARK: - Cell.ConstraintError + LocalizedError

extension Cell.ConstraintError: LocalizedError {
    /// Same as `description`, suitable for localized error messages.
    @inlinable @inline(__always)
    public var errorDescription: String? { description }
}

// MARK: - Cell.ConstraintError.Kind

extension Cell.ConstraintError {
    /// Describes the type of constraint to be enforced:
    ///
    /// - `.minimum(Int)`: must be at least `Int`
    /// - `.exactly(Int)`: must be exactly `Int`
    /// - `.maximum(Int)`: must be at most `Int`
    enum Kind {
        case minimum(Int)
        case exactly(Int)
        case maximum(Int)
    }
}

// MARK: - Cell.ConstraintError.CellTrait

extension Cell.ConstraintError {
    enum CellTrait {
        case storage
        case children
    }
}

// MARK: - Cell.ConstraintError.CellTrait + CustomStringConvertible

extension Cell.ConstraintError.CellTrait: CustomStringConvertible {
    var description: String {
        switch self {
        case .children: "children"
        case .storage: "storage"
        }
    }
}

extension Collection {
    /// Checks this collection's `count` against a specified constraint
    /// (`minimum`, `exactly`, or `maximum`).
    ///
    /// - Parameters:
    ///  - cellKind: The kind of cell imposing these constraints.
    ///  - constrintKind: The constraint to check (e.g. `.minimum(2)`).
    ///  - trait: Whether we're checking `.storage` or `.children`.
    /// - Throws: `Cell.ConstraintError` if the constraint is violated.
    ///
    /// **Example**:
    /// ```swift
    /// let bits = [Bool](repeating: false, count: 500)
    /// try bits.check(.ordinary, for: .maximum(1023), trait: .storage)
    /// // passes (500 <= 1023)
    /// ```
    func check(
        _ cellKind: Cell.Kind,
        for constrintKind: Cell.ConstraintError.Kind,
        trait: Cell.ConstraintError.CellTrait
    ) throws (Cell.ConstraintError) {
        switch constrintKind {
        case let .minimum(value) where count < value:
            throw Cell.ConstraintError(constrintKind, cellKind, trait, count)
        case let .exactly(value) where count != value:
            throw Cell.ConstraintError(constrintKind, cellKind, trait, count)
        case let .maximum(value) where count > value:
            throw Cell.ConstraintError(constrintKind, cellKind, trait, count)
        default:
            break
        }
    }
}

extension Collection where Element == Bool {
    /// Validates this `Bool` collection (bit storage) against a `constrintKind`,
    /// forwarding to `check(_, for: trait:)` with `.storage`.
    ///
    /// **Example**:
    /// ```swift
    /// let bits = Array(repeating: true, count: 1025)
    /// try bits.check(.ordinary, for: .maximum(1023)) // throws if > 1023
    /// ```
    @inline(__always)
    func check(
        _ cellKind: Cell.Kind,
        for constrintKind: Cell.ConstraintError.Kind
    ) throws (Cell.ConstraintError) {
        try check(cellKind, for: constrintKind, trait: .storage)
    }
}

extension Collection where Element == Cell {
    /// Validates this array of `Cell` references against a `constrintKind`,
    /// forwarding to `check(_, for: trait:)` with `.children`.
    ///
    /// **Example**:
    /// ```swift
    /// let children = [Cell(), Cell(), Cell()]
    /// try children.check(.ordinary, for: .maximum(4)) // OK if <= 4
    /// ```
    @inline(__always)
    func check(
        _ cellKind: Cell.Kind,
        for constrintKind: Cell.ConstraintError.Kind
    ) throws (Cell.ConstraintError) {
        try check(cellKind, for: constrintKind, trait: .children)
    }
}

extension Collection where Element == Bool {
    func capacity(for cellKind: Cell.Kind) -> Int {
        switch cellKind {
        case .ordinary: 1023
        case .prunedBranch: 16 + 256 * 3 + 16 * 3 // up to level=3
        case .libraryReference: 264
        case .merkleProof: 280
        case .merkleUpdate: 552
        }
    }

    /// Checks the maximum allowed bits for each cell kind.
    /// E.g., `.ordinary` -> 1023 bits; `.merkleUpdate` -> 552 bits, etc.
    ///
    /// - Parameter cellKind: The kind of cell imposing the limit.
    /// - Throws: `Cell.ConstraintError` if `count` exceeds that limit.
    ///
    /// **Example**:
    /// ```swift
    /// let bits = Array(repeating: false, count: 1050)
    /// try bits.checkMaximumValue(for: .ordinary) // throws, because 1050 > 1023
    /// ```
    func checkMaximumValue(for cellKind: Cell.Kind) throws (Cell.ConstraintError) {
        try check(cellKind, for: .maximum(capacity(for: cellKind)))
    }

    /// Checks the minimum required bits for each cell kind.
    ///
    /// - Parameter cellKind: The kind of cell imposing this requirement.
    /// - Throws: `Cell.ConstraintError` if `count` is below that minimum.
    ///
    /// **Example**:
    /// ```swift
    /// let bits = Array(repeating: false, count: 6)
    /// try bits.checkMinimumValue(for: .merkleProof) // must be at least 280 bits => throws
    /// ```
    func checkMinimumValue(for cellKind: Cell.Kind) throws (Cell.ConstraintError) {
        let minimumValue: Int = switch cellKind {
        case .ordinary: 0
        case .prunedBranch: 8 // type byte
        case .libraryReference: 264
        case .merkleProof: 280
        case .merkleUpdate: 552
        }
        try check(cellKind, for: .minimum(minimumValue))
    }
}

extension Collection where Element == Cell {
    func capacity(for cellKind: Cell.Kind) -> Int {
        switch cellKind {
        case .ordinary: 4
        case .prunedBranch: 0
        case .libraryReference: 0
        case .merkleProof: 1
        case .merkleUpdate: 2
        }
    }

    /// Checks the maximum allowed child references for each cell kind.
    ///
    /// **Example**:
    /// ```swift
    /// let kids: [Cell] = [cellA, cellB, cellC, cellD, cellE]
    /// try kids.checkMaximumValue(for: .ordinary) // throws if > 4
    /// ```
    func checkMaximumValue(for cellKind: Cell.Kind) throws (Cell.ConstraintError) {
        try check(cellKind, for: .maximum(capacity(for: cellKind)))
    }

    /// Checks the minimum required child references for a given cell kind.
    /// - `.merkleProof` => at least 1
    /// - `.merkleUpdate` => at least 2
    ///
    /// **Example**:
    /// ```swift
    /// let kids: [Cell] = []
    /// try kids.checkMinimumValue(for: .merkleProof) // throws if < 1
    /// ```
    func checkMinimumValue(for cellKind: Cell.Kind) throws (Cell.ConstraintError) {
        let minimumValue: Int = switch cellKind {
        case .ordinary: 0
        case .prunedBranch: 0
        case .libraryReference: 0
        case .merkleProof: 1
        case .merkleUpdate: 2
        }
        try check(cellKind, for: .minimum(minimumValue))
    }
}
