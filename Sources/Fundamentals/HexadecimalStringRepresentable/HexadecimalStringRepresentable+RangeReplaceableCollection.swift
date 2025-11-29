//
//  Created by Anton Spivak
//

public extension RangeReplaceableCollection where Element: HexadecimalStringConvertible {
    var hexadecimalString: String {
        hexadecimalString(separator: "")
    }

    func hexadecimalString(separator: String = " ") -> String {
        map(\.hexadecimalString).joined(separator: separator)
    }
}

public extension RangeReplaceableCollection where Element: ExpressibleByHexadecimalString {
    init?(hexadecimalString: String) {
        let elementCharacterCount = MemoryLayout<Element>.size * 2
        guard hexadecimalString.count.isMultiple(of: elementCharacterCount)
        else { return nil }

        let elements = stride(
            from: 0,
            to: hexadecimalString.count,
            by: elementCharacterCount
        ).compactMap({
            Element(hexadecimalString: String(hexadecimalString[$0 ..< $0 + elementCharacterCount]))
        })

        guard elements.count == hexadecimalString.count / elementCharacterCount
        else { return nil }

        self.init(elements)
    }
}
