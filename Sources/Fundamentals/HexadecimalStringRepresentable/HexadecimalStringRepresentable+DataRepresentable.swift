//
//  Created by Anton Spivak
//

public extension ExpressibleByHexadecimalString where Self: DataConvertible {
    var hexadecimalString: String {
        data(with: .big).map(\.hexadecimalString).joined(separator: "")
    }
}

public extension ExpressibleByHexadecimalString where Self: ExpressibleByData {
    init?(hexadecimalString: String) {
        guard hexadecimalString.count.isMultiple(of: 2)
        else { return nil }

        let bytes = stride(from: 0, to: hexadecimalString.count, by: 2).compactMap({
            UInt8(hexadecimalString: String(hexadecimalString[$0 ..< $0 + 1]))
        })

        self.init(data: Data(bytes), .big)
    }
}
