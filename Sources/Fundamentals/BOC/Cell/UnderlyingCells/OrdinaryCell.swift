//
//  Created by Anton Spivak
//

import Crypto

// MARK: - OrdinaryCell

@usableFromInline
struct OrdinaryCell: UnderlyingCellProtocol {
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
        try storage.checkMinimumValue(for: .ordinary)
        try storage.checkMaximumValue(for: .ordinary)

        try children.checkMinimumValue(for: .ordinary)
        try children.checkMaximumValue(for: .ordinary)

        var levels = CellData.LevelMask()
        for child in children {
            levels.formUnion(child.underlyingCell.levels)
        }

        return calculate(levels, storage, children)
    }

    @inline(__always)
    static func calculate(
        _ levels: CellData.LevelMask,
        _ storage: BitStorage,
        _ children: [Cell]
    ) -> CellData.PrecalculatedData {
        var precalculatedData = CellData.PrecalculatedData(levels)
        for i in 0 ... levels.highestLevel {
            guard levels.contains(level: i)
            else {
                continue
            }

            let _level: CellData.LevelMask = .with(level: i)
            let _data = CellData(
                kind: .ordinary,
                precalculated: .init(_level),
                storage: storage,
                children: children
            )

            var depth: UInt16 = 0
            children.forEach({
                let child = $0.underlyingCell.data
                let clevel = switch $0.kind {
                case .merkleProof, .merkleUpdate: i + 1
                default: i
                }
                depth = max(depth, child.depth(at: clevel))
            })

            if !children.isEmpty {
                depth += 1
            }

            var _hash = SHA256()
            _hash.update(data: _data.representation(i))

            precalculatedData.set(depth: depth, with: .with(level: i))
            precalculatedData.set(
                hash: _hash.finalize().withUnsafeBytes({ Data($0) }),
                with: .with(level: i)
            )
        }
        return precalculatedData
    }
}
