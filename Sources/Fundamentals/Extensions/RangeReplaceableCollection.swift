//
//  Created by Anton Spivak
//

extension RangeReplaceableCollection where Element == UInt8 {
    /// Removes leading zero bytes (0x00). If the entire collection is zeros,
    /// returns a single 0x00 byte to preserve at least one byte.
    ///
    /// **Example**:
    /// ```swift
    /// let arr: [UInt8] = [0x00, 0x00, 0x01, 0x02]
    /// let trimmed = arr.removingLeadingZeros() // [0x01, 0x02]
    /// ```
    func removingLeadingZeros() -> Self {
        guard let index = firstIndex(where: { $0 != 0 })
        else {
            return Self([0x00])
        }
        return Self(suffix(from: index))
    }
}
