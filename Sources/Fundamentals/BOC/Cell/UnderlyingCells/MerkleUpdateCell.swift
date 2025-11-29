//
//  Created by Anton Spivak
//

@usableFromInline
struct MerkleUpdateCell: UnderlyingCellProtocol {
    // MARK: Lifecycle

    init(data: CellData) {
        self.data = data
    }

    // MARK: Internal

    let data: CellData

    @inline(__always)
    static func calculate(
        _ storage: BitStorage,
        _ children: [Cell]
    ) throws (Cell.ConstraintError) -> CellData.PrecalculatedData {
        try storage.checkMinimumValue(for: .merkleUpdate)
        try storage.checkMaximumValue(for: .merkleUpdate)

        try children.checkMinimumValue(for: .merkleUpdate)
        try children.checkMaximumValue(for: .merkleUpdate)

        fatalError("Not implemented yet")
    }
}
