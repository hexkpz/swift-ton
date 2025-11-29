//
//  Created by Anton Spivak
//

/// Allows `BitStorage` to be initialized with an array literal of `Bool`.
///
/// ```swift
/// let bits: BitStorage = [true, false, true]
/// // bits.count == 3
/// // bits[0] == true, bits[1] == false, bits[2] == true
/// ```
extension BitStorage: ExpressibleByArrayLiteral {
    /// Creates a new `BitStorage` from the given Boolean values.
    ///
    /// - Parameter elements: A variadic list of `Bool` values to store as bits.
    @inlinable @inline(__always)
    public init(arrayLiteral elements: Bool...) {
        self.init()
        append(contentsOf: elements)
    }
}
