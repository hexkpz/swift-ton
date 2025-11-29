//
//  Created by Anton Spivak
//

/// Allows `BitStorage` to be initialized from a string literal containing a
/// valid bit array.
///
/// ```swift
/// let bits: BitStorage = "1011"
/// // 'bits' now contains the four bits: 1, 0, 1, 1
/// ```
extension BitStorage: ExpressibleByStringLiteral {
    /// Creates a new `BitStorage` by parsing each character of the string literal.
    ///
    /// - Parameter value: A string literal that must contain only valid bit
    ///   characters. If parsing fails, this method calls `fatalError(_:)`.
    public init(stringLiteral value: StringLiteralType) {
        guard let value = BitStorage(_utf8: value.utf8)
        else {
            fatalError("Invalid bit array string literal")
        }
        self = value
    }
}
