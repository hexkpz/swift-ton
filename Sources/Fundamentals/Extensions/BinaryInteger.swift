//
//  Created by Anton Spivak
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Musl)
import Musl
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Bionic)
import Bionic
#else
#error("Unsupported platform")
#endif

public extension BinaryInteger {
    /// Returns a version of `self` with all bits reversed (mirrored) up to the integer’s
    /// `bitWidth` (max 64 bits). For instance, if this integer is 16 bits wide, it
    /// flips bit 0 to bit 15, bit 1 to bit 14, etc.
    ///
    /// - Warning: An internal precondition ensures `bitWidth <= 64`.
    ///
    /// **Usage Example**:
    /// ```swift
    /// let value: UInt16 = 0b0001_1010_0011_0101
    /// let mirrored = value.bitsMirrored
    /// // mirrored now has 0b1010_1100_0101_1000
    /// ```
    var bitsMirrored: Self {
        precondition(
            bitWidth <= UInt64.bitWidth,
            "bitsMirrored() supports up to 64-bit integers only."
        )
        let value = _mirrorBits(in: UInt64(truncatingIfNeeded: self))
        return Self(truncatingIfNeeded: value >> (UInt64.bitWidth - bitWidth))
    }

    /// Calculates the minimum number of bytes needed to represent `self`.
    /// This is essentially `ceil((64 - leadingZeroBitCount) / 8)`, ensuring at least 1.
    ///
    /// **Usage Example**:
    /// ```swift
    /// let num: Int = 1024
    /// let width = num.minimumBytesWidth
    /// // width == 2 (because 1024 fits in 2 bytes)
    /// ```
    @inline(__always)
    var minimumBytesWidth: Int {
        Swift.max(Int(ceil(Double(64 - Int64(self).leadingZeroBitCount) / 8)), 1)
    }
}

/// Reverses all 64 bits of `x` using a classic “bit twiddling” approach.
///
/// **Steps**:
///
/// 1. **Swap odd/even bits**:
/// ```
/// y = ((y & 0x5555_5555_5555_5555) << 1) | ((y & 0xAAAA_AAAA_AAAA_AAAA) >> 1)
/// ```
/// This mask-and-shift toggles each bit pair.
///
/// 2. **Swap consecutive bit pairs**:
/// ```
/// y = ((y & 0x3333_3333_3333_3333) << 2) | ((y & 0xCCCC_CCCC_CCCC_CCCC) >> 2)
/// ```
/// It handles bit groups of size 2.
///
/// 3. **Swap nibbles (4-bit groups)**:
/// ```
/// y = ((y & 0x0F0F_0F0F_0F0F_0F0F) << 4) | ((y & 0xF0F0_F0F0_F0F0_F0F0) >> 4)
/// ```
///
/// 4. **Swap bytes (8-bit groups)**:
/// ```
/// y = ((y & 0x00FF_00FF_00FF_00FF) << 8) | ((y & 0xFF00_FF00_FF00_FF00) >> 8)
/// ```
///
/// 5. **Swap 16-bit blocks**:
/// ```
/// y = ((y & 0x0000_FFFF_0000_FFFF) << 16) | ((y & 0xFFFF_0000_FFFF_0000) >> 16)
/// ```
///
/// 6. **Swap 32-bit blocks**:
/// ```
/// y = (y << 32) | (y >> 32)
/// ```
///
/// Each stage effectively doubles the “swapped chunk” size until the entire
/// 64-bit pattern is reversed. This is a well-known bit manipulation
/// technique often referred to as a “bit-reversal” or “bit mirror” algorithm.
///
/// - Parameter x: A 64-bit unsigned integer to mirror.
/// - Returns: A 64-bit value whose bits are reversed from the input.
@usableFromInline @inline(__always)
func _mirrorBits(in x: UInt64) -> UInt64 {
    var y = x
    y = ((y & 0x5555_5555_5555_5555) << 1) | ((y & 0xAAAA_AAAA_AAAA_AAAA) >> 1)
    y = ((y & 0x3333_3333_3333_3333) << 2) | ((y & 0xCCCC_CCCC_CCCC_CCCC) >> 2)
    y = ((y & 0x0F0F_0F0F_0F0F_0F0F) << 4) | ((y & 0xF0F0_F0F0_F0F0_F0F0) >> 4)
    y = ((y & 0x00FF_00FF_00FF_00FF) << 8) | ((y & 0xFF00_FF00_FF00_FF00) >> 8)
    y = ((y & 0x0000_FFFF_0000_FFFF) << 16) | ((y & 0xFFFF_0000_FFFF_0000) >> 16)
    y = (y << 32) | (y >> 32)
    return y
}
