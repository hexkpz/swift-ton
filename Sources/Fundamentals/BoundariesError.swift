//
//  Created by Anton Spivak
//

import Foundation

// MARK: - BoundariesError

/// An error indicating that the requested number of elements
/// exceeds what is currently available in the underlying collection.
public struct BoundariesError: Error {
    @usableFromInline
    init() {}
}

// MARK: CustomStringConvertible

extension BoundariesError: CustomStringConvertible {
    public var description: String { "Index out of bounds" }
}

// MARK: LocalizedError

extension BoundariesError: LocalizedError {
    @inlinable @inline(__always)
    public var errorDescription: String? { description }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: BoundariesError) {
        appendLiteral("\(value.description)")
    }
}
