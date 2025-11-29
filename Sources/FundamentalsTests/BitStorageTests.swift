//
//  Created by Anton Spivak
//

import Testing

@testable import Fundamentals

// MARK: - AddressTests

struct BitStorageTests {
    typealias BitPatternTestArguments = (
        value: any BinaryInteger & Sendable,
        expectation: String,
        index: Int
    )

    typealias TruncatingToBitWidthArguments = (
        value: any BinaryInteger & Sendable,
        targetToBitWidth: Int,
        expectation: String,
        index: Int
    )

    @Test("BitStroage(bitPattern:)", arguments: [
        // UInt8
        (UInt8.min, "00000000", 1),
        (UInt8(1), "00000001", 1),
        (UInt8(2), "00000010", 1),
        (UInt8(4), "00000100", 1),
        (UInt8(8), "00001000", 1),
        (UInt8(16), "00010000", 1),
        (UInt8(32), "00100000", 1),
        (UInt8(64), "01000000", 1),
        (UInt8(128), "10000000", 1),
        (UInt8.max, "11111111", 1),

        // Int8
        (Int8.min, "10000000", 2),
        (Int8(-1), "11111111", 2),
        (Int8(+1), "00000001", 2),
        (Int8.max, "01111111", 2),

        // UInt16
        (UInt16.min, "0000000000000000", 3),
        (UInt16(1), "0000000000000001", 3),
        (UInt16.max, "1111111111111111", 3),

        // Int16
        (Int16.min, "1000000000000000", 4),
        (Int16(-1), "1111111111111111", 4),
        (Int16(+1), "0000000000000001", 4),
        (Int16.max, "0111111111111111", 4),

        // UInt32
        (UInt32.min, "00000000000000000000000000000000", 5),
        (UInt32(1), "00000000000000000000000000000001", 5),
        (UInt32.max, "11111111111111111111111111111111", 5),

        // Int32
        (Int32.min, "10000000000000000000000000000000", 6),
        (Int32(-1), "11111111111111111111111111111111", 6),
        (Int32(+1), "00000000000000000000000000000001", 6),
        (Int32.max, "01111111111111111111111111111111", 6),

        // UInt64
        (UInt64.min, "0000000000000000000000000000000000000000000000000000000000000000", 7),
        (UInt64(1), "0000000000000000000000000000000000000000000000000000000000000001", 7),
        (UInt64.max, "1111111111111111111111111111111111111111111111111111111111111111", 7),

        // Int64
        (Int64.min, "1000000000000000000000000000000000000000000000000000000000000000", 8),
        (Int64(-1), "1111111111111111111111111111111111111111111111111111111111111111", 8),
        (Int64(+1), "0000000000000000000000000000000000000000000000000000000000000001", 8),
        (Int64.max, "0111111111111111111111111111111111111111111111111111111111111111", 8),

        // BigUInt
        (BigUInt("0"), "", 9),
        (BigUInt("1"), "1", 9),
        (
            BigUInt("18446744073709551616"),
            "10000000000000000000000000000000000000000000000000000000000000000",
            9
        ),

        // BigInt
        (BigInt("-1"), "11", 10),
        (BigInt("0"), "", 10),
        (BigInt("1"), "01", 10),
        (
            BigInt("-18446744073709551616"),
            "110000000000000000000000000000000000000000000000000000000000000000",
            10
        ),
    ] as [BitPatternTestArguments])
    func testBitPattern(_ tuple: BitPatternTestArguments) throws {
        #expect(BitStorage(bitPattern: tuple.value).description == tuple.expectation)
    }

    @Test("BitStroage(bitPattern:truncatingToBitWidth:)", arguments: [
        // UInt8
        (UInt8(1), 0, "", 1),
        (UInt8(1), 1, "1", 1),
        (UInt8(1), 16, "0000000000000001", 1),
        (
            UInt8(1),
            72,
            "000000000000000000000000000000000000000000000000000000000000000000000001",
            1
        ),

        // Int8
        (Int8(+1), 1, "1", 2), // 0000000[1] -> 1
        (
            Int8(+1),
            72,
            "000000000000000000000000000000000000000000000000000000000000000000000001",
            2
        ),

        // UInt16
        (UInt16(1), 0, "", 3),
        (UInt16(1), 1, "1", 3),
        (UInt16(1), 16, "0000000000000001", 3),
        (
            UInt16(1),
            72,
            "000000000000000000000000000000000000000000000000000000000000000000000001",
            3
        ),

        // UInt32
        (UInt32(1), 0, "", 4),
        (UInt32(1), 1, "1", 4),
        (UInt32(1), 16, "0000000000000001", 4),
        (
            UInt32(1),
            72,
            "000000000000000000000000000000000000000000000000000000000000000000000001",
            4
        ),

        // UInt64
        (UInt64(1), 0, "", 5),
        (UInt64(1), 1, "1", 5),
        (UInt64(1), 16, "0000000000000001", 5),
        (
            UInt64(1),
            72,
            "000000000000000000000000000000000000000000000000000000000000000000000001",
            5
        ),

        // BigUInt
        (BigUInt("1"), 1, "1", 6),
        (BigUInt("2"), 2, "10", 6),
        (
            BigUInt("18446744073709551616"),
            4,
            "0000",
            6
        ),

        // BigInt
        (BigInt("1"), 1, "1", 7),
        (BigInt("2"), 2, "10", 7),
        (
            BigInt("18446744073709551616"),
            4,
            "0000",
            7
        ),
    ] as [TruncatingToBitWidthArguments])
    func testBitPatternTruncating(_ tuple: TruncatingToBitWidthArguments) throws {
        let value = BitStorage(
            bitPattern: tuple.value,
            truncatingToBitWidth: tuple.targetToBitWidth
        )
        #expect(value.description == tuple.expectation)
    }

    @Test("BitStorage.append")
    func testAppendingCollection() throws {
        var bs = BitStorage()
        bs.append(true)
        #expect(bs.description == "1")
        bs.append(false)
        #expect(bs.description == "10")
        bs.append(contentsOf: [true, true, true, true, true, false])
        #expect(bs.description == "10111110")
        bs.append(contentsOf: "1001")
        #expect(bs.description == "101111101001")
    }

    @Test("BitStorage[]")
    func testRandomAccessCollection() {
        let bs = BitStorage("1010100001001010100")
        #expect(bs[0] == true)
        #expect(bs[12] == true)
        #expect(BitStorage(bs[0 ..< 2]).description == "10")
        #expect(BitStorage(bs[2 ..< 9]).description == "1010000")

        let bbs = BitStorage(bitPattern: BigUInt("1844674407370955161612344534553"))
        #expect(
            bbs.description ==
                "10111010010000111011011101000000000000000000000000000000000000000001011011111110010101010011000011001"
        )

        #expect(
            BitStorage(bbs[60 ..< 70]).appending(contentsOf: bbs)
                .description ==
                "000000010110111010010000111011011101000000000000000000000000000000000000000001011011111110010101010011000011001"
        )
    }

    @Test("BinaryInteger.init(_ source:)")
    func testInitialization() {
        let value0 = UInt8(truncatingIfNeeded: BitStorage("11"))
        #expect(value0 == 3)

        let value1 = UInt32(truncatingIfNeeded: BitStorage("0000000000000000000000111"))
        #expect(value1 == 7)

        let value2 = BigUInt(truncatingIfNeeded: BitStorage("0000000000000000000000000000111"))
        print(value2.description == "7")
    }

    @Test("BitStorage.Data")
    func testData() {
        let bytes = Data(repeating: 1, count: 128)

        var bs = BitStorage(bytes)
        bs.append(contentsOf: "10")

        #expect(bs.alignedData() == (bytes + [128]))
    }
}
