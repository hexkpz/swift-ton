//
//  Created by Anton Spivak
//

// MARK: - SimpleLibrary

public struct SimpleLibrary {
    // MARK: Lifecycle

    public init(isPublic: Bool, reference: Cell) {
        self.isPublic = isPublic
        self.reference = reference
    }

    // MARK: Public

    public let isPublic: Bool
    public let reference: Cell
}

// MARK: Hashable

extension SimpleLibrary: Hashable {}

// MARK: Sendable

extension SimpleLibrary: Sendable {}

// MARK: CellCodable

///
/// https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L145
/// ```
/// simple_lib$_
///  public:Bool
///  root:^Cell
///  = SimpleLib;
/// ```
extension SimpleLibrary: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        self.isPublic = try container.decode(Bool.self)
        self.reference = try container.decode(Cell.self)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(isPublic)
        try container.encode(reference)
    }
}

// MARK: HashmapE.Value

extension SimpleLibrary: HashmapE.Value {}
