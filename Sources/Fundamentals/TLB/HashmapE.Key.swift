//
//  Created by Anton Spivak
//

import Foundation
import BigInt

// MARK: - HashmapE.Key

public extension HashmapE {
    /// A protocol for types that serve as keys in `HashmapE`.
    /// Each must produce a `BitStorage` (`keyRepresentation`) and
    /// be constructible from that storage.
    ///
    /// **Example**:
    /// ```swift
    /// struct MyKey: HashmapE.Key {
    ///     let value: Int
    ///
    ///     var keyRepresentation: BitStorage {
    ///         BitStorage(bitPattern: value)
    ///     }
    ///
    ///     init(keyRepresentation: BitStorage) throws {
    ///         self.value = Int(truncatingIfNeeded: keyRepresentation)
    ///     }
    /// }
    /// ```
    protocol Key {
        var keyRepresentation: BitStorage { get }

        init(keyRepresentation bitStorage: BitStorage) throws
    }
}

// MARK: - HashmapE.FixedWidthKey

public extension HashmapE {
    /// Indicates that a key has a compile-time fixed width in bits, accessed
    /// via `keyBitWidth`.
    ///
    /// Built-in integer types typically conform to this by returning their `bitWidth`.
    protocol FixedWidthKey {
        static var keyBitWidth: Int { get }
    }
}

public extension BinaryInteger where Self: HashmapE.Key {
    @inlinable @inline(__always)
    var keyRepresentation: BitStorage { BitStorage(bitPattern: self) }

    @inlinable @inline(__always)
    init(keyRepresentation bitStorage: BitStorage) throws {
        self.init(truncatingIfNeeded: bitStorage)
    }
}

public extension FixedWidthInteger where Self: HashmapE.FixedWidthKey {
    @inlinable @inline(__always)
    static var keyBitWidth: Int { bitWidth }
}

// MARK: - Int + HashmapE.Key, HashmapE.FixedWidthKey

extension Int: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - Int8 + HashmapE.Key, HashmapE.FixedWidthKey

extension Int8: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - Int16 + HashmapE.Key, HashmapE.FixedWidthKey

extension Int16: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - Int32 + HashmapE.Key, HashmapE.FixedWidthKey

extension Int32: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - Int64 + HashmapE.Key, HashmapE.FixedWidthKey

extension Int64: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - BigInt + HashmapE.Key

extension BigInt: HashmapE.Key {}

// MARK: - UInt + HashmapE.Key, HashmapE.FixedWidthKey

extension UInt: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - UInt8 + HashmapE.Key, HashmapE.FixedWidthKey

extension UInt8: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - UInt16 + HashmapE.Key, HashmapE.FixedWidthKey

extension UInt16: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - UInt32 + HashmapE.Key, HashmapE.FixedWidthKey

extension UInt32: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - UInt64 + HashmapE.Key, HashmapE.FixedWidthKey

extension UInt64: HashmapE.Key, HashmapE.FixedWidthKey {}

// MARK: - BigUInt + HashmapE.Key

extension BigUInt: HashmapE.Key {}

// MARK: - InternalAddress + HashmapE.Key, HashmapE.FixedWidthKey

extension InternalAddress: HashmapE.Key, HashmapE.FixedWidthKey {
    @inlinable @inline(__always)
    public static var keyBitWidth: Int { 267 }

    @inlinable @inline(__always)
    public var keyRepresentation: BitStorage { bitStorage }

    @inlinable @inline(__always)
    public init(keyRepresentation bitStorage: BitStorage) throws {
        var bitStorage = ContinuousReader(bitStorage)
        try self.init(bitStorage: &bitStorage)
    }
}

// MARK: - BitStorage + HashmapE.Key

extension BitStorage: HashmapE.Key {
    @inlinable @inline(__always)
    public var keyRepresentation: BitStorage { self }

    @inlinable @inline(__always)
    public init(keyRepresentation bitStorage: BitStorage) throws {
        self = bitStorage
    }
}

// MARK: - Data + HashmapE.Key

extension Data: HashmapE.Key {
    @inlinable @inline(__always)
    public var keyRepresentation: BitStorage { BitStorage(self) }

    @inlinable @inline(__always)
    public init(keyRepresentation bitStorage: BitStorage) throws {
        precondition(
            bitStorage.count % 8 == 0,
            "Couldn't convert BitStorage to Data: wrong bit length"
        )
        self = bitStorage._data(byChunkSize: 8)
    }
}
