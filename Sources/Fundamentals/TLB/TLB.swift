//
//  Created by Anton Spivak
//

// MARK: - TLBCodingError

public struct TLBCodingError {
    // MARK: Lifecycle

    @inlinable @inline(__always)
    public init(_ description: String) {
        self.description = description
    }

    // MARK: Public

    public let description: String
}

public extension TLBCodingError {
    static func invalidEnumerationFlagValue(for type: Any.Type) -> Self {
        .init("Invalid enumeration flag value for: `\(String(describing: type))`.")
    }

    static func hashmapEKeysMustBeSameSize() -> Self {
        .init("HashmapE keys must be the same size.")
    }

    static func invalidSnakeEncodedData() -> Self {
        .init("Invalid snake encoded data.")
    }
}

// MARK: LocalizedError

extension TLBCodingError: LocalizedError {
    @inlinable @inline(__always)
    public var errorDescription: String? { description }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: TLBCodingError) {
        appendLiteral("\(value.description)")
    }
}
