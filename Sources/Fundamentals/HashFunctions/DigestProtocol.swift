//
//  Created by Anton Spivak
//

import Crypto
import Foundation

#if canImport(CryptoKit)
public typealias _Digest = CryptoKit.Digest
#else
public typealias _Digest = Crypto.Digest
#endif

// MARK: - DigestProtocol

/// A protocol that unifies `CryptoKit.Digest` with a `RawRepresentable` constraint,
/// requiring `rawValue` to be a `Data`. This lets you store a digest’s
/// bytes and also treat it like a standard Swift `Digest`.
///
/// **Example**:
/// ```swift
/// struct MyDigest: DigestProtocol {
///    public let rawValue: Data
///    public static let byteCount: Int = 4
///
///    // Conformance to CryptoKit.Digest
///    public init() { self.rawValue = [] }
///    // ...
/// }
/// ```
public protocol DigestProtocol: _Digest, RawRepresentable where RawValue == Data {}

public extension DigestProtocol {
    // MARK: Public

    /// A hex-encoded string of the underlying bytes. Often used for logging or debugging.
    ///
    /// **Example**:
    /// ```swift
    /// let digestStr = digest.description
    /// print("Digest: \(digestStr)")
    /// ```
    @inlinable @inline(__always)
    var description: String { rawValue.hexadecimalString }

    /// Returns the byte at the specified `index`.
    ///
    /// **Example**:
    /// ```swift
    /// let byte = digest[0]
    /// ```
    @inlinable @inline(__always)
    subscript(index: Int) -> UInt8 { rawValue[index] }

    /// Incorporates the digest’s `rawValue` into a `Hasher`, enabling `Hashable` conformance.
    ///
    /// **Example**:
    /// ```swift
    /// var hasher = Hasher()
    /// digest.hash(into: &hasher)
    /// let hashValue = hasher.finalize()
    /// ```
    @inlinable @inline(__always)
    func hash(into hasher: inout Hasher) { hasher.combine(rawValue) }

    /// Provides an iterator over the digest’s bytes, matching the standard `Sequence` interface.
    ///
    /// **Example**:
    /// ```swift
    /// for byte in digest {
    ///    print(byte)
    /// }
    /// ```
    @inlinable @inline(__always)
    func makeIterator() -> Data.Iterator { rawValue.makeIterator() }

    /// Calls a closure with a pointer to the digest’s underlying bytes, enabling low-level
    /// operations without copying.
    ///
    /// - Parameter body: A closure that takes an `UnsafeRawBufferPointer`.
    /// - Returns: Whatever the closure returns (generic `R`).
    /// - Throws: Rethrows any error from the closure.
    ///
    /// **Example**:
    /// ```swift
    /// let result = digest.withUnsafeBytes { buffer in
    ///    // use 'buffer' here
    /// }
    /// ```
    @inlinable @inline(__always)
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try rawValue.withUnsafeBytes(body)
    }
}
