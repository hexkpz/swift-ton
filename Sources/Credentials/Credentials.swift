//
//  Created by Anton Spivak
//

import Foundation

@_exported import BIP

/// A lightweight wrapper around TON-compatible credential material.
///
/// `Credentials` encapsulates an Ed25519 private key derived from:
/// - a BIP-39 mnemonic using the TON seed function (default), or
/// - a mnemonic + BIP-32 derivation path using SLIP-0010 (if `derivationPath` is provided).
///
/// Examples:
/// ```swift
/// let credentials = try Credentials()
/// ```
///
/// ```swift
/// let credentials = try Credentials(derivationPath: "m/44'/607'/0'")
/// ```
public struct Credentials: RawRepresentable, Sendable {
    // MARK: Lifecycle

    public init(rawValue: Curve25519.Signing.PrivateKey) {
        self.rawValue = rawValue
    }

    /// Initialize from a mnemonic (generated if none provided).
    ///
    /// - If `derivationPath` is `nil`:
    ///   TON seed → Ed25519 key.
    ///
    /// - If `derivationPath` is provided:
    ///   SLIP-0010 derivation (via Ethereum-style algorithm) → Ed25519 key.
    public init(
        _ mnemonica: Mnemonica? = nil,
        derivationPath: DerivationPath? = nil
    ) throws {
        let mnemonica = mnemonica ?? .generate()
        let rawValue: Curve25519.Signing.PrivateKey
        if let derivationPath {
            // SLIP-0010 Ed25519 hierarchical derivation
            rawValue = try .init(mnemonica, algorithm: .ethereum(), derivationPath: derivationPath)
        } else {
            // TON-native seed → Ed25519 key
            let seed = mnemonica.seed(with: .ton())
            rawValue = try .init(rawRepresentation: seed)
        }
        self.init(rawValue: rawValue)
    }

    // MARK: Public

    public let rawValue: Curve25519.Signing.PrivateKey
}

#if canImport(FoundationNetworking)
extension Curve25519.Signing.PrivateKey: @retroactive @unchecked Sendable {}
#endif
