//
//  Created by Anton Spivak
//

extension String {
    /// Converts a base64-url encoded string into normal base64 by replacing
    /// ‘-’ with ‘+’ and ‘_’ with ‘/’, plus adds ‘=’ padding if needed.
    ///
    /// https://tools.ietf.org/html/rfc4648#page-7
    ///
    /// - Note: Follows RFC4648 guidelines for base64url <-> base64 conversions.
    func base64URLUnescaped() -> String {
        var replaced = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = replaced.count % 4
        if padding > 0 {
            replaced += String(repeating: "=", count: 4 - padding)
        }
        return replaced
    }

    /// Converts a normal base64 string into base64-url by removing '=' padding
    /// and mapping '+' to '-' and '/' to '_'.
    ///
    /// https://tools.ietf.org/html/rfc4648#page-7
    ///
    /// - Note: Follows RFC4648 for URL-safe base64 encoding.
    func base64URLEscaped() -> String {
        return replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
