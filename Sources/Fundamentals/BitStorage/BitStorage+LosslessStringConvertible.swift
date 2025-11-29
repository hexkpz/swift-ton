//
//  Created by Anton Spivak
//

// MARK: - BitStorage + LosslessStringConvertible

extension BitStorage: LosslessStringConvertible {
    /// A string describing the bit storage as a sequence of `'0'` and `'1'`.
    ///
    /// This property iterates over each bit (`Bool`) and converts `true` into `'1'`
    /// and `false` into `'0'`, concatenating all bits in order.
    ///
    /// ```swift
    /// let bits = BitStorage([true, false, true])
    /// print(bits) // "101"
    /// ```
    ///
    /// - Returns: A string composed of '0' and '1' characters.
    public var description: String { map({ $0._utf8 }).joined() }

    /// Creates a new `BitStorage` by parsing a string of `'0'` and `'1'` characters.
    ///
    /// If the string contains any characters other than `'0'` or `'1'`,
    /// initialization fails and returns `nil`.
    ///
    /// ```swift
    /// let validBits = BitStorage("1010")
    /// // validBits is non-nil and contains 4 bits
    ///
    /// let invalidBits = BitStorage("10x0")
    /// // invalidBits is nil, since 'x' is not a valid bit
    /// ```
    ///
    /// - Parameter description: A string literal composed of '0' and '1'.
    /// - Returns: A new `BitStorage` if the string is valid; otherwise, `nil`.
    @inlinable @inline(__always)
    public init?(_ description: String) {
        self.init(_utf8: description.utf8)
    }

    @usableFromInline
    init?<T>(_utf8: T) where T: Collection, T.Element == UInt8 {
        self.init()
        let elements: [Bool] = _utf8.compactMap({
            guard $0 == ._ascii0 || $0 == ._ascii1
            else {
                return nil
            }
            return $0 == ._ascii1
        })
        guard elements.count == _utf8.count
        else {
            return nil
        }
        append(contentsOf: elements)
    }
}

private extension Bool {
    @inline(__always)
    var _utf8: String { self ? "1" : "0" }
}

private extension UInt8 {
    @inline(__always)
    static var _ascii0: Self { 48 }

    @inline(__always)
    static var _ascii1: Self { 49 }
}
