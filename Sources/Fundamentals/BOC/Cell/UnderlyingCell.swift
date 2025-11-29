//
//  Created by Anton Spivak
//

// MARK: - UnderlyingCell

@usableFromInline
enum UnderlyingCell {
    case ordinary(OrdinaryCell)
    case libraryReference(LibraryReferenceCell)
    case prunedBranch(PrunedBranchCell)
    case merkleProof(MerkleProofCell)
    case merkleUpdate(MerkleUpdateCell)
}

extension UnderlyingCell {
    init(_ kind: Cell.Kind, storage: BitStorage, children: [Cell]) throws (Cell.ConstraintError) {
        self = switch kind {
        case .ordinary:
            try .ordinary(.init(data: .init(kind, OrdinaryCell.self, storage, children)))
        case .libraryReference:
            try .ordinary(.init(data: .init(kind, LibraryReferenceCell.self, storage, children)))
        case .prunedBranch:
            try .ordinary(.init(data: .init(kind, PrunedBranchCell.self, storage, children)))
        case .merkleProof:
            try .ordinary(.init(data: .init(kind, MerkleProofCell.self, storage, children)))
        case .merkleUpdate:
            try .ordinary(.init(data: .init(kind, MerkleUpdateCell.self, storage, children)))
        }
    }
}

// MARK: Sendable

extension UnderlyingCell: Sendable {}

extension UnderlyingCell {
    @usableFromInline @inline(__always)
    var kind: Cell.Kind { data.kind }

    @usableFromInline @inline(__always)
    var levels: CellData.LevelMask { data.precalculated.levels }

    @usableFromInline @inline(__always)
    var storage: BitStorage { data.storage }

    @usableFromInline @inline(__always)
    var children: [Cell] { data.children }

    @usableFromInline @inline(__always)
    var data: CellData {
        switch self {
        case let .ordinary(cell): cell.data
        case let .libraryReference(cell): cell.data
        case let .prunedBranch(cell): cell.data
        case let .merkleProof(cell): cell.data
        case let .merkleUpdate(cell): cell.data
        }
    }
}

private extension CellData {
    @inline(__always)
    init<T>(
        _ kind: Cell.Kind,
        _ cell: T.Type,
        _ storage: BitStorage,
        _ children: [Cell]
    ) throws (Cell.ConstraintError) where T: UnderlyingCellProtocol {
        try self.init(
            kind: kind,
            precalculated: T.calculate(storage, children),
            storage: storage,
            children: children
        )
    }
}
