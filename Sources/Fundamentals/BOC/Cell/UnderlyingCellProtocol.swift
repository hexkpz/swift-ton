//
//  Created by Anton Spivak
//

// MARK: - UnderlyingCellProtocol

/// A low-level protocol that defines the essential contract for building
/// and storing a `CellData` object. Conforming types describe how to
/// calculate precomputed data (hash, depth, etc.) from a bit storage
/// and a set of child cells.
protocol UnderlyingCellProtocol: Sendable {
    var data: CellData { get }

    /// Initializes the conforming object with a prepared `CellData`.
    /// Typically used once the data and precomputed fields have been
    /// validated and finalized.
    ///
    /// - Parameter data: A fully constructed `CellData` instance.
    init(data: CellData)

    /// Calculates level-related fields (e.g., depth, hash) for a given
    /// bit storage and array of child cells, returning a `PrecalculatedData`
    /// structure.
    ///
    /// - Parameters:
    ///  - storage: Bits associated with this cell.
    ///  - children: Child cells linked to this cell.
    /// - Throws: `Cell.ConstraintError` if the cell constraints are not met (e.g., too many children, too many bits).
    /// - Returns: A `CellData.PrecalculatedData` containing computed depth and hash arrays, keyed by level.
    static func calculate(
        _ storage: BitStorage,
        _ children: [Cell]
    ) throws (Cell.ConstraintError) -> CellData.PrecalculatedData
}
