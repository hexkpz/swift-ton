//
//  Created by Anton Spivak
//

import Testing

@testable import Fundamentals

// MARK: - InternalAddressCodingTests

struct CurrencyValueTests {
    struct CurrencyValueCodable: CellDecodable {
        // MARK: Lifecycle

        init(from container: inout CellDecodingContainer) throws {
            self.value = try container.decode(CurrencyValue.self)
        }

        // MARK: Internal

        let value: CurrencyValue
    }

    @Test(arguments: [
        ("0", "5331fed036518120c7f345726537745c5929b8ea1fa37b99b2bb58f702671541"),
        ("0.000000001", "d46edee086ccbace01f45c13d26d49b68f74cd1b7616f4662e699c82c6ec728b"),
        ("0.536870912", "5e18a3f34f9957786ed0b7e28c9d1c657caadad64ff2d5a4dd890cfe31c98a05"),
        ("0.536870914", "681029927bb12ece2084b6e52be754541ed6ead58cbec5ce2e18d95df80c0a7b"),
        ("0.000263201", "de7ba967556f89971bf4c7761dc6114631075308d334b12d3649f4e10b64615e"),
        (
            "1000000000.000000000",
            "729486b95b285e244b62c562aff34273a2f489307f136118518c1f80ceace7d3"
        ),
        (
            "2361183241434.822606850",
            "7025f1c100c415c9da7bde5637d79372e7195f4841c4133c15f90aceec5b5cb4"
        ),
        (
            "452675467235452367457325476.237642378",
            "9121be67e3be390f3575d1b3b3cc3e60dbc41991eb031a69b4dfcc868bde257b"
        ),
    ])
    func testDecimalUInt(_ value: (CurrencyValue, cellHash: Data)) throws {
        let cellb: Cell = try Cell { value.0 }
        let cells: Cell = "\(value.0)"

        #expect(cellb == cells)
        #expect(cellb.representationHash == value.cellHash)

        try #expect(cellb.decode(CurrencyValueCodable.self).value == value.0)
        try #expect(cells.decode(CurrencyValueCodable.self).value == value.0)
    }

    @Test(arguments: [
        (BigUInt(123_456), UInt(3), "123.456"),
        (BigUInt(123_456), UInt(6), "0.123456"),
        (BigUInt(123_456), UInt(0), "123456"),
    ])
    func testStringInitDecimals(_ value: (BigUInt, UInt, String)) {
        let (rawValue, decimals, expected) = value
        let value = CurrencyValue(rawValue: rawValue)
        let string = String(value, decimals: decimals)
        #expect(string == expected)
    }

    @Test(arguments: [
        ("1.2", UInt(3), BigUInt(1200)),
        ("1.2346", UInt(3), BigUInt(1235)),
    ])
    func testInitFromStringWithInterpret(_ value: (String, UInt, BigUInt)) {
        let (input, decimals, expectedRaw) = value
        let value = CurrencyValue(input, interpretLike: decimals)
        #expect(value != nil)
        #expect(value!.rawValue == expectedRaw)
    }

    @Test(arguments: [
        ("1.2345", "1", "235", 3),
        ("99.9999", "100", "00", 2)
    ])
    func testRoundingHalfUp(_ value: (String, String, String, Int)) {
        let (input, integer, fraction, scale) = value
        let rounded = input.roundingHalfUp(to: scale)
        #expect(rounded.integer == integer)
        #expect(rounded.fractional == fraction)
    }

    @Test
    func testAdditionAndSubtraction() {
        let a = CurrencyValue("1.23", interpretLike: 2)!
        let b = CurrencyValue("2.34", interpretLike: 2)!
        let sum = a + b
        let diff = b - a
        #expect(String(sum, decimals: 2) == "3.57")
        #expect(String(diff, decimals: 2) == "1.11")
    }

    @Test
    func testMultiplication() {
        let a = CurrencyValue("1.23", interpretLike: 2)!
        let product = a * 2
        #expect(String(product, decimals: 2) == "2.46")
    }

    @Test
    func testDivision() {
        let a = CurrencyValue("2.00", interpretLike: 2)!
        let quotient = a / 2
        #expect(String(quotient, decimals: 2) == "1.00")
    }
}
