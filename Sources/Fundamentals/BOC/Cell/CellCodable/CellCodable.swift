//
//  Created by Anton Spivak
//

/// A typealias that combines both `CellEncodable` and `CellDecodable`
/// in a TON-specific context.
///
/// Types conforming to `CellCodable` should be capable of encoding themselves
/// into a TON `Cell` (used widely in the TON blockchain for data storage),
/// as well as decoding from such a `Cell`.
///
/// In a typical TON-based dApp or smart contract interaction, you may need
/// to serialize structures into cells for on-chain storage or TVM execution.
public typealias CellCodable = CellEncodable & CellDecodable

// MARK: - _CellCodable

/// A low-level protocol indicating a type’s "kind" when encoded into a TON `Cell`.
///
/// This protocol is primarily used internally by `CellCodable` and related types.
/// By default, `kind` is `.ordinary`, meaning a normal cell (without exotic flags).
/// If you need an exotic cell (e.g., `.merkleProof`), override `kind` in your type.
public protocol _CellCodable {
    /// Specifies the kind of TON `Cell` to use when encoding or decoding this type.
    ///
    /// In the TON blockchain, a cell can be `.ordinary` or one of several exotic forms.
    /// By default, data structures typically use `.ordinary` cells unless specialized
    /// logic is required.
    static var kind: Cell.Kind { get }
}

public extension _CellCodable {
    /// The default cell kind for `_CellCodable`-conforming types.
    ///
    /// If your structure needs an exotic cell type, override this property to
    /// something like `.prunedBranch` or `.merkleProof`.
    static var kind: Cell.Kind { .ordinary }
}

// MARK: - CellContainerSpace

public struct CellContainerSpace {
    // MARK: Lifecycle

    /// Creates a new `CellContainerSpace`, specifying how many bits and child references
    /// must remain free in the current container.
    ///
    /// - Parameters:
    ///   - storage: The number of bit positions to reserve (default = 0).
    ///   - children: The number of child references to reserve (default = 0).
    public init(storage: Int = 0, children: Int = 0) {
        self.storage = storage
        self.children = children
    }

    // MARK: Public

    /// The number of bits that must remain unoccupied in the container.
    public let storage: Int

    /// The number of child references that must remain unoccupied.
    public let children: Int
}

// MARK: Sendable

extension CellContainerSpace: Sendable {}

extension Optional where Wrapped == CellContainerSpace {
    @inline(__always)
    var storage: Int {
        switch self {
        case .none: 0
        case let .some(wrapped): wrapped.storage
        }
    }

    @inline(__always)
    var children: Int {
        switch self {
        case .none: 0
        case let .some(wrapped): wrapped.children
        }
    }
}
