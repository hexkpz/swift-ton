//
//  Created by Anton Spivak
//

@usableFromInline
struct PrunedBranchCell: UnderlyingCellProtocol {
    // MARK: Lifecycle

    init(data: CellData) {
        self.data = data
    }

    // MARK: Internal

    let data: CellData

    static func calculate(
        _ storage: BitStorage,
        _ children: [Cell]
    ) throws (Cell.ConstraintError) -> CellData.PrecalculatedData {
        try storage.checkMinimumValue(for: .prunedBranch)
        try storage.checkMaximumValue(for: .prunedBranch)

        try children.checkMinimumValue(for: .prunedBranch)
        try children.checkMaximumValue(for: .prunedBranch)
        
        fatalError("Not implemented yet")
    }
}
