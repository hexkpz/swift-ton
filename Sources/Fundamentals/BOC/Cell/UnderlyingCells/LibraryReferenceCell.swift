//
//  Created by Anton Spivak
//

@usableFromInline
struct LibraryReferenceCell: UnderlyingCellProtocol {
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
        try storage.checkMinimumValue(for: .libraryReference)
        try storage.checkMaximumValue(for: .libraryReference)

        try children.checkMinimumValue(for: .libraryReference)
        try children.checkMaximumValue(for: .libraryReference)

        return OrdinaryCell.calculate(.with(level: 0), storage, children)
    }
}
