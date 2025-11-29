//
//  Created by Anton Spivak
//

import Foundation

extension Foundation.Data: @retroactive ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        fatalError("Not implemented")
    }
}

extension Foundation.Data: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {
    public init(extendedGraphemeClusterLiteral value: String) {
        fatalError("Not implemented")
    }
}

extension Foundation.Data: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        guard let value = Self(hexadecimalString: value)
        else { fatalError("Could not initialize Foundation.Data from \(value)") }
        self = value
    }
}
