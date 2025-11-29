//
//  Created by Anton Spivak
//

public extension RawRepresentable where RawValue: HexadecimalStringConvertible {
    var hexadecimalString: String { rawValue.hexadecimalString }
}

public extension RawRepresentable where RawValue: ExpressibleByHexadecimalString {
    init?(hexadecimalString: String) {
        guard let rawValue = RawValue(hexadecimalString: hexadecimalString)
        else { return nil }
        self.init(rawValue: rawValue)
    }
}

public extension RawRepresentable
    where
    RawValue: RangeReplaceableCollection,
    RawValue.Element: HexadecimalStringConvertible
{
    var hexadecimalString: String { rawValue.hexadecimalString }
}

public extension RawRepresentable
    where
    RawValue: RangeReplaceableCollection,
    RawValue.Element: ExpressibleByHexadecimalString
{
    init?(hexadecimalString: String) {
        guard let rawValue = RawValue(hexadecimalString: hexadecimalString)
        else { return nil }
        self.init(rawValue: rawValue)
    }
}
