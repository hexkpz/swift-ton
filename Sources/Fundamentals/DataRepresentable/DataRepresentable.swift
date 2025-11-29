//
//  Created by Anton Spivak
//

import Foundation

// MARK: - DataConvertible

public protocol DataConvertible {
    func data(with endianness: Endianness) -> Data
}

// MARK: - ExpressibleByData

public protocol ExpressibleByData {
    init(data: Data, _ endianness: Endianness)
}

public typealias DataRepresentable =
    DataConvertible &
    ExpressibleByData

extension Data: @retroactive ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = UInt8

    public init(arrayLiteral elements: UInt8...) {
        self = Data(elements)
    }
}
