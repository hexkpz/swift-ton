//
//  Created by Anton Spivak
//

@usableFromInline
struct MerkleProofCell: UnderlyingCellProtocol {
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
        try storage.checkMinimumValue(for: .merkleProof)
        try storage.checkMaximumValue(for: .merkleProof)

        try children.checkMinimumValue(for: .merkleProof)
        try children.checkMaximumValue(for: .merkleProof)

        fatalError("Not implemented yet")
    }
}
