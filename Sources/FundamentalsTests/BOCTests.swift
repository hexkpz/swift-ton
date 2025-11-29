//
//  Created by Anton Spivak
//

import Testing

@testable import Fundamentals

struct BOCTests {
    // MARK: Internal

    @Test("BOC encoding / decoding", arguments: [
        [],
        [.crc32c],
        [.indices],
        [.crc32c, .indices],
    ] as [BOC.IncludedOptions])
    func testCoding(_ options: BOC.IncludedOptions) throws {
        let cells = try cells
        for cell in cells {
            try ed([cell], options)
        }
        try ed(cells, options)
    }

    // MARK: Private

    private var cells: [Cell] {
        get throws {
            try [
                Cell { "" },
                Cell { "0" },
                Cell { "1" },
                Cell { "00000000" },
                Cell { "11111111" },
                Cell {
                    [true, true, false, true]
                    [true, true, false, true]
                    [true, true, false, true]
                    try Cell { true }
                    try Cell { false }
                    try Cell {
                        true
                        try Cell { true }
                        try Cell { false }
                    }
                    try Cell { false }
                },
                Cell {
                    [true, true, false, true]
                    [true, true, false, true]
                    [true, true, false, true]
                    try Cell { true }
                    try Cell { false }
                    try Cell {
                        true
                        try Cell { true }
                        try Cell { false }
                    }
                    try Cell { false }
                },
                Cell { "0000001" },
                Cell { "0000000" },
                Cell {
                    UInt8(24)
                    try Cell { true }
                    try Cell { false; UInt32(45) }
                },
                Cell {},
            ]
        }
    }

    private func ed(_ cells: [Cell], _ options: BOC.IncludedOptions) throws {
        let encoded = try BOC(cells, options: options)
        guard let decoded = BOC(encoded.hexadecimalString) else {
            #expect(Bool(false), Comment(stringLiteral: "Couldn't decode BOC: \(encoded)"))
            return
        }
        #expect(decoded == encoded)
    }
}

