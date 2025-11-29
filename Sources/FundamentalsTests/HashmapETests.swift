//
//  Created by Anton Spivak
//

import Testing

@testable import Fundamentals

// MARK: - HashmapETests

struct HashmapETests {
    struct Model: CellCodable {
        // MARK: Lifecycle

        init(_ dictionary: [UInt64: UInt64]) {
            self.dictionary = dictionary
        }

        init(from container: inout CellDecodingContainer) throws {
            self.dictionary = try container.decode([UInt64: UInt64].self)
        }

        // MARK: Internal

        let dictionary: [UInt64: UInt64]

        func encode(to container: inout CellEncodingContainer) throws {
            try container.encode(dictionary)
        }
    }

    @Test()
    func some() throws {
        let model = Model([
            1: 0,
            2: 1,
            3: 4,
            5: 6,
        ])

        let cell = try Cell(model)
        print(cell.debugDescription)

        let _model = try cell.decode(Model.self)
        print(_model.dictionary)
    }
}
