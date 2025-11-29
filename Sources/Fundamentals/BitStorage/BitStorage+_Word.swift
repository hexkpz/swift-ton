//
//  Created by Anton Spivak
//

import Foundation

// MARK: - BitStorage._Word

extension BitStorage {
    @usableFromInline
    typealias _Word = UInt64
}

/// An internal type holding the position of a specific bit within a `[_Word]`.
@usableFromInline
typealias BitPosition = (word: Int, offset: Int, bit: BitStorage._Word)

extension BitStorage {
    /// Ensures that `_count` bits are properly represented,
    /// truncating any extra bits if necessary.
    @inline(__always)
    mutating func _truncateToBitWidth() {
        _words._truncate(toTargetBitCount: _count)
    }
}

extension Array where Element == BitStorage._Word {
    /// Returns a `BitPosition` tuple for the specified absolute bit index.
    ///
    /// - Parameter index: The absolute bit index.
    /// - Precondition: `index` must be within the array's total bit capacity.
    @usableFromInline
    subscript(bitIndex index: Int) -> BitPosition {
        let bitWidth = Element.bitWidth
        precondition(index < count * bitWidth, "Index out of bounds")
        let offset = index % bitWidth
        let bit = BitStorage._Word(1) << (bitWidth - offset - 1)
        return (index / bitWidth, offset, bit)
    }

    /// Gets or sets the bit at a specific `BitPosition`.
    ///
    /// - Parameter position: A `BitPosition` that identifies the target bit.
    @usableFromInline
    subscript(bitPosition position: BitPosition) -> Bool {
        get { self[position.word] & position.bit != 0 }
        set {
            if newValue {
                self[position.word] |= position.bit
            } else {
                self[position.word] &= ~position.bit
            }
        }
    }
}

extension Array where Element == BitStorage._Word {
    /// Merges bits from another array into this one, aligning them as needed.
    ///
    /// - Parameters:
    ///   - other: The array from which to merge bits.
    ///   - fromBitCount: The current bit count before merging.
    ///   - targetBitCount: The new total bit count after merging.
    @usableFromInline
    mutating func _merge(with other: Self, fromBitCount: Int, targetBitCount: Int) {
        let bitWidth = Element.bitWidth
        if fromBitCount % bitWidth == 0 {
            append(contentsOf: other)
        } else {
            let appendinx = other._lwshift(by: bitWidth - fromBitCount % bitWidth)
            let count = count
            append(contentsOf: [Element](repeating: 0, count: appendinx.count - 1))
            for i in 0 ..< appendinx.count {
                self[i + count - 1] |= appendinx[i]
            }
        }
        _truncate(toTargetBitCount: targetBitCount)
    }

    /// Truncates or extends the array to match a specific target bit count,
    /// truncating any extra bits if necessary.
    ///
    /// - Parameter bitCount: The total number of bits required.
    @usableFromInline
    mutating func _truncate(toTargetBitCount bitCount: Int) {
        let bitWidth = Element.bitWidth
        let requiredWordsCount = (bitCount + bitWidth - 1) / bitWidth

        if count < requiredWordsCount {
            append(contentsOf: [Element](repeating: 0, count: requiredWordsCount - count))
        } else if count > requiredWordsCount {
            removeLast(count - requiredWordsCount)
        }

        let remainder = bitCount % bitWidth
        guard remainder > 0, count > 0
        else {
            return
        }

        self[count - 1] &= (Element.max << (bitWidth - remainder))
    }
}

extension Array where Element == BitStorage._Word {
    /// Produces a reduced subarray holding only the bits in the given range.
    ///
    /// - Parameter range: The bit range to extract.
    /// - Returns: A new array containing bits for the specified range.
    @usableFromInline
    func _reduced(forBitRange range: Range<Int>) -> Self {
        let bitWidth = Element.bitWidth
        guard !range.isEmpty
        else {
            return []
        }

        let reducedWordsCount = (range.count + bitWidth - 1) / bitWidth
        var reducedWords = [Element](repeating: 0, count: reducedWordsCount)

        let startingPosition = self[bitIndex: range.lowerBound]
        for i in 0 ..< reducedWordsCount {
            let index = startingPosition.word + i

            let current = (index < count) ? self[index] : 0
            let left = current << startingPosition.offset

            let next = ((index + 1) < count) ? self[index + 1] : 0
            let right = next >> (bitWidth - startingPosition.offset)

            reducedWords[i] = left | right
        }

        reducedWords._truncate(toTargetBitCount: range.count)
        return reducedWords
    }

    /// Leftwise-shifts all bits by a specified amount within each word,
    /// optionally overflowing into an extra word.
    ///
    /// - Parameter amount: Number of bits to shift left, must be within `[0, bitWidth)`.
    /// - Returns: A new array with shifted bits.
    @usableFromInline
    func _lwshift(by amount: Int) -> Self {
        precondition(amount >= 0 && amount < Element.bitWidth, "Amount out of bounds")
        if amount == 0 {
            return self
        }

        let bitWidth = Element.bitWidth
        var value = Self(repeating: Element.zero, count: count + 1)

        for i in 0 ..< count {
            value[i] |= self[i] >> (bitWidth - amount)
            value[i + 1] |= (self[i] << amount)
        }

        return value
    }
}

extension BitStorage {
    /// Creates a `Data` from this bit storage,
    /// with bits grouped by the specified chunk size.
    ///
    /// - Parameter chunk: The size of each chunk in bits. Must divide `_count`.
    /// - Returns: A `Data` holding the extracted chunks in order.
    @usableFromInline
    func _data(byChunkSize chunk: Int) -> Data {
        _words._data(byChunkSize: chunk, effectiveBitsCount: _count)
    }
}

extension Array where Element == BitStorage._Word {
    /// Initializes the array from a `Data`,
    /// interpreting each group of bytes as a `_Word`.
    ///
    /// - Parameter _data: The collection of bytes to convert.
    init(_data: Data) {
        self.init()

        let bytesPerWord = Element.bitWidth / 8
        for i in stride(from: 0, to: _data.count, by: bytesPerWord) {
            var word = Element(0)
            for j in 0 ..< bytesPerWord {
                word <<= 8
                guard i + j < _data.count
                else {
                    continue
                }
                word |= Element(_data[i + j])
            }
            append(word)
        }
    }

    /// Splits the internal bits into consecutive chunks of size `chunk`,
    /// then stores each chunk as a single byte in the resulting `Data`.
    ///
    /// - Parameters:
    ///   - chunk: The chunk size in bits (4 or 8).
    ///   - count: The effective number of bits to process.
    /// - Returns: A `Data` containing the extracted byte values.
    @usableFromInline
    func _data(byChunkSize chunk: Int, effectiveBitsCount count: Int) -> Data {
        precondition(chunk == 4 || chunk == 8, "Chunk size must be 4 or 8")
        precondition(count % chunk == 0, "Effective bits count must be divisible by chunk")

        var result = Data()
        result.reserveCapacity(count / chunk)

        let bitWidth = Element.bitWidth
        let byte = { (word: Element, index: Int) -> UInt8 in
            let shift = bitWidth - chunk * (index + 1)
            let mask = (Element(1) << chunk) &- 1
            return UInt8(truncatingIfNeeded: (word >> shift) & Element(mask))
        }

        var used = 0
        for word in self {
            for j in 0 ..< Element.bitWidth / chunk {
                result.append(byte(word, j))

                used += chunk
                if used >= count {
                    break
                }
            }
        }

        return result
    }
}
