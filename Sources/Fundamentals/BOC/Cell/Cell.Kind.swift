//
//  Created by Anton Spivak
//

// MARK: - Cell.Kind

public extension Cell {
    enum Kind: Int32 {
        /// A standard or “ordinary” cell with no exotic features.
        case ordinary = -1

        /// A pruned branch cell, used in Merkle-like proofs to indicate truncated sub-trees.
        case prunedBranch = 1

        /// A library reference cell that can link to external code or data.
        case libraryReference = 2

        /// A Merkle proof cell (exotic), typically used to prove partial branches.
        case merkleProof = 3

        /// A Merkle update cell (exotic), used for incremental proof modifications.
        case merkleUpdate = 4
    }
}

public extension Cell.Kind {
    /// Indicates whether this cell kind is considered “exotic.”
    /// Exotic cells often have specialized structures or constraints.
    /// 
    /// - Returns: true for any non-ordinary kind, false otherwise.
    var isExotic: Bool {
        switch self {
        case .ordinary: false
        default: true
        }
    }
}

// MARK: - Cell.Kind + CustomStringConvertible

extension Cell.Kind: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ordinary: "Ordinary"
        case .prunedBranch: "Pruned Branch"
        case .libraryReference: "Library Reference"
        case .merkleProof: "Merkle Proof"
        case .merkleUpdate: "Merkle Update"
        }
    }
}

// MARK: - Cell.Kind + Sendable

extension Cell.Kind: Sendable {}

// MARK: - Cell.Kind + Hashable

extension Cell.Kind: Hashable {}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: Cell.Kind) {
        appendLiteral("\(value.description)")
    }
}
