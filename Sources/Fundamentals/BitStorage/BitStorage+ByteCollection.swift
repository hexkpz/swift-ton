//
//  Created by Anton Spivak
//

import Foundation

public extension BitStorage {
    /// Creates a new `BitStorage` instance from a `Data`, interpreting
    /// each byte as 8 bits in big-endian format.
    ///
    /// The resulting storage will have `source.count * 8` bits.
    ///
    /// ```swift
    /// let bytes = Data([0xFF, 0x0A])
    /// let bitStorage = BitStorage(bytes)
    /// // bitStorage.count == 16
    /// ```
    ///
    /// - Parameter source: The bytes to convert into this bit storage.
    init(_ source: Data) {
        _count = source.count * 8
        _words = .init(_data: source)
    }

    /// Returns a `Data` whose bits are guaranteed to be aligned to
    /// whole-byte boundaries. If the bit storage has a bit count not divisible
    /// by 8, this method aligns it by appending the necessary bits (if any).
    ///
    /// ```swift
    /// var bits = BitStorage()
    /// bits.append(true)      // Now bit count == 1
    /// let alignedBytes = bits.alignedData()
    /// // alignedBytes.count == 1, bits that were appended for alignment are included
    /// ```
    ///
    /// - Returns: A `Data` with full-byte alignment of the bits.
    func alignedData() -> Data {
        var copy = self
        copy.devideIfNeeded(toBitsCount: 8)
        return copy._data(byChunkSize: 8)
    }

    /// Returns a `Data` aligned to the "cell" boundary used internally.
    ///
    /// This is similar to `cellAlignedData()`, but leverages `cellAlign()`
    /// to perform a specialized alignment (e.g., for TON cell-like usage).
    @usableFromInline
    internal func cellAlignedData() -> Data {
        cellAligned()._data(byChunkSize: 8)
    }
}

extension BitStorage {
    /// Returns a copy of `self` where the bits are aligned via `cellAlign()`.
    ///
    /// If the bit count isn't divisible by 8, a `true` bit is appended,
    /// then enough zero bits are appended to reach the next multiple of 8.
    func cellAligned() -> Self {
        var copy = self
        copy.cellAlign()
        return copy
    }

    /// Aligns this `BitStorage` to an internal cell boundary (multiples of 8 bits).
    ///
    /// 1. If the bit count is not divisible by 8, appends a single `true` bit
    ///    followed by enough zero bits to reach a multiple of 8.
    /// 2. Calls `devideIfNeeded(toBitsCount: 8)` to ensure `_count` is updated.
    ///
    /// This approach is sometimes used in TON contexts to distinguish
    /// "manually aligned" segments (indicated by a `true` bit) from
    /// default alignment.
    mutating func cellAlign() {
        let lackingBitsCount = lackingBitsCount(devidingTo: 8)
        if lackingBitsCount > 0 {
            append(true)
        }
        devideIfNeeded(toBitsCount: 8)
    }

    /// Reverses the effect of `cellAlign()` if possible by removing trailing bits.
    ///
    /// This method scans from the end of the bit storage, looking for a trailing
    /// `true` bit followed by the zero bits appended during `cellAlign()`.
    /// If the number of discovered bits is `< 8`, they're removed.
    /// Otherwise, nothing changes (we assume it's a different alignment scenario).
    ///
    /// - SeeAlso: `cellAlign()`
    mutating func cellUnalign() {
        // We start from the last bit, checking if it's zero or true,
        // counting how many bits in total we've progressed.
        var alignedBitsCount = 1
        for i in stride(from: count - 1, through: 0, by: -1) {
            guard !self[i]
            else {
                // Found a `true` bit -> alignment marker.
                // Stop counting more bits, because we only remove if it's strictly fewer than 8 bits total.
                break
            }
            alignedBitsCount += 1
        }

        // If we found fewer than 8 bits (including the `true` bit) and have enough length,
        // remove them.
        guard alignedBitsCount < 8, count >= alignedBitsCount
        else {
            return
        }

        _count -= alignedBitsCount
        _truncateToBitWidth()
    }
}

extension BitStorage {
    /// Produces a hexadecimal string where each nibble (4 bits) maps to a hex digit.
    /// If `count` isn't a multiple of 8, an underscore (`_`) is appended to indicate
    /// partial-byte usage.
    ///
    /// This format is often seen in Fift (a debugging and scripting language in TON)
    /// when dealing with nibble or byte-aligned data.
    ///
    /// - Returns: A hex string (e.g., `"ff0a"`), possibly ending with `_`.
    @usableFromInline
    func nibbleFiftHexadecimalString() -> String {
        var isUnderscoreNeeded = false
        var string = cellAligned()._data(byChunkSize: 4).map({
            String(format: "%01x", $0)
        }).joined()

        if count % 4 == 0 {
            if count % 8 != 0 {
                string.removeLast(1)
            }
        } else {
            isUnderscoreNeeded = true
            if count % 8 <= 4 {
                string.removeLast(1)
            }
        }

        return isUnderscoreNeeded ? "\(string)_" : string
    }
}

extension BitStorage {
    /// Calculates how many bits are missing to make `count` divisible by `bitsCount`.
    ///
    /// - Parameter bitsCount: The boundary (e.g., 8 for byte alignment).
    /// - Returns: The number of additional bits needed to reach that boundary.
    @usableFromInline @inline(__always)
    func lackingBitsCount(devidingTo bitsCount: Int) -> Int {
        (bitsCount - (count % bitsCount)) % bitsCount
    }

    /// Ensures `_count` is a multiple of `bitsCount`. If not, appends zero bits
    /// until it is. Then calls `_truncateToBitWidth()` to finalize.
    ///
    /// - Parameter bitsCount: The alignment size in bits.
    ///
    /// For example, `devideIfNeeded(toBitsCount: 8)` ensures that `count`
    /// is a multiple of 8 bits, effectively aligning to a byte boundary.
    @usableFromInline @inline(__always)
    mutating func devideIfNeeded(toBitsCount bitsCount: Int) {
        let lackingBitsCount = lackingBitsCount(devidingTo: bitsCount)
        guard lackingBitsCount > 0
        else {
            return
        }
        _count += lackingBitsCount
        _truncateToBitWidth()
    }
}
