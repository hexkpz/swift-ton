//
//  Created by Anton Spivak
//

import BIP

// MARK: - Mnemonica.CompatibilityOptions

/// A set of optional flags controlling how a BIP-39 mnemonic is generated or interpreted
/// in a TON-compatible manner. Conforming to `OptionSet`, it allows combining multiple
/// flags if needed.
///
/// **Example**:
/// ```swift
/// // Generate a mnemonic enforcing the TON seed version.
/// let options: Mnemonica.CompatibilityOptions = [.ton]
/// let mnemonic = Mnemonica.generate(with: options)
/// print(mnemonic.options.contains(.ton)) // true
/// ```
///
/// See also:
/// - [BIP-39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
public extension Mnemonica {
    struct CompatibilityOptions: OptionSet {
        // MARK: Lifecycle

        /// Creates a new set of compatibility options from the given raw value.
        ///
        /// - Parameter rawValue: A `UInt64` representing the bitmask.
        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }

        // MARK: Public

        /// Indicates that the generated mnemonic should be compatible
        /// with the TON seed version, ensuring the first seed byte is zero.
        public static let ton = Self(rawValue: 1 << 1)

        /// The raw bitmask that combines one or more `CompatibilityOptions`.
        public let rawValue: UInt64
    }
}

// MARK: - Mnemonica.CompatibilityOptions + Hashable

extension Mnemonica.CompatibilityOptions: Hashable {}

// MARK: - Mnemonica.CompatibilityOptions + Sendable

extension Mnemonica.CompatibilityOptions: Sendable {}

extension Mnemonica {
    /// Generates a BIP-39 mnemonic, optionally enforcing TON seed compatibility.
    ///
    /// If the `.ton` option is present, this method keeps regenerating a mnemonic until
    /// one passes the TON seed version check (i.e., leading zero byte in the seed).
    ///
    /// - Parameters:
    ///   - compatibilityOptions: A set of `CompatibilityOptions`. Default is `[.ton]`.
    ///   - length: The number of words (12, 18, or 24) to generate. Defaults to 24.
    ///   - glossary: The language-specific word list (default is `.english`).
    /// - Returns: A newly generated `Mnemonica` structure conforming to BIP-39 rules,
    ///            optionally forced to match TON seed version requirements.
    ///
    /// **Example**:
    /// ```swift
    /// // Create a 24-word TON-compatible mnemonic in English.
    /// let mnemonic = Mnemonica.generate()
    /// print(mnemonic.isTONSeedVersion) // true, guaranteed
    /// ```
    static func generate(
        with compatibilityOptions: CompatibilityOptions = [.ton],
        length: BIP39.Mnemonica.Length = .w24,
        glossary: BIP39.Mnemonica.Glossary = .english,
    ) -> Mnemonica {
        var mnemonica = BIP39.Mnemonica(length: length, glossary: glossary)
        if compatibilityOptions.contains(.ton) {
            while !mnemonica.isTONSeedVersion {
                // If `.ton` is required, ensure the seed's first byte is zero.
                // Otherwise, regenerate until condition is met.
                mnemonica = BIP39.Mnemonica(length: length, glossary: glossary)
            }
        }
        return mnemonica
    }
}

public extension Mnemonica {
    /// Returns a set of `CompatibilityOptions` inferred from this mnemonic.
    ///
    /// If `isTONSeedVersion` is `true`, the returned options include `.ton`.
    /// Otherwise, it returns an empty set.
    ///
    /// **Example**:
    /// ```swift
    /// let mnemonic = Mnemonica.generate()
    /// print(mnemonic.compatibilityOptions) // might be [.ton] if it passes TON seed checks
    /// ```
    var compatibilityOptions: CompatibilityOptions {
        var options: CompatibilityOptions = []
        if isTONSeedVersion { options.insert(.ton) }
        return options
    }
}

extension Mnemonica {
    /// Indicates whether this mnemonic satisfies the TON seed version check, i.e.,
    /// the first seed byte is 0x00 when derived via the specified algorithm sequence:
    ///
    /// - `HMAC-SHA512`
    /// - `PKCS5` with:
    ///   - salt = "TON seed version"
    ///   - password = ""
    ///   - iterations = 100,000 / 256 (minimum 1)
    ///   - klength = 32
    ///
    /// If the resulting seed’s leading byte is zero, we consider it “TON-compatible”.
    ///
    /// [Reference Implementation (tonweb-mnemonic)](https://github.com/toncenter/tonweb-mnemonic/blob/a338a00d4ca0ed833431e0e49e4cfad766ac713c/src/functions/common.ts#L8)
    ///
    /// - Returns: `true` if the derived seed starts with 0x00, otherwise `false`.
    var isTONSeedVersion: Bool {
        seed(with: .init([
            .hmac(kind: .sha512),
            .pkcs5(
                salt: "TON seed version",
                password: "",
                iterations: max(1, 100_000 / 256),
                klength: 32
            ),
        ]))[0] == 0x00
    }
}
