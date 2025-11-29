//
//  Created by Anton Spivak
//

import BigInt

#if canImport(Darwin)
import Darwin
#elseif canImport(Musl)
import Musl
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Bionic)
import Bionic
#else
#error("Unsupported platform")
#endif

// MARK: - VariableWidthInteger

public protocol VariableWidthInteger:
    RawRepresentable, Sendable, Hashable, Equatable
    where
    RawValue: BinaryInteger
{
    static var sizeBitWidth: Int { get }

    init(rawValue: RawValue)
}

public extension VariableWidthInteger {
    @inlinable @inline(__always)
    init(_ rawValue: RawValue) {
        self.init(rawValue: rawValue)
    }
}

/// Variable Sized Integer
///
/// ```
/// var_uint$_ {n:#}
///  len:(#< n)
///  value:(uint (len * 8))
///  = VarUInteger n;
///  ```
///
///  ```
/// var_int$_
///  {n:#} len:(#< n)
///  value:(int (len * 8))
///  = VarInteger n;
/// ```
public extension VariableWidthInteger {
    func appendTo(_ bitStorage: inout BitStorage) {
        guard rawValue != 0
        else {
            bitStorage.append(bitPattern: 0, truncatingToBitWidth: Self.sizeBitWidth)
            return
        }

        let byteWidth = Int(ceil(Double(rawValue.bitWidth) / 8))
        precondition(
            Self.sizeBitWidth >= 64 - Int64(byteWidth).leadingZeroBitCount,
            "byteWidth (\(byteWidth)) couldn't fit to sizeBitWidth (\(Self.sizeBitWidth)) bits"
        )

        bitStorage.append(bitPattern: byteWidth, truncatingToBitWidth: Self.sizeBitWidth)
        bitStorage.append(bitPattern: rawValue, truncatingToBitWidth: byteWidth * 8)
    }

    init(bitStorage: inout ContinuousReader<BitStorage>) throws {
        let byteWidth = try bitStorage.read(UInt.self, truncatingToBitWidth: Self.sizeBitWidth)
        guard byteWidth > 0
        else {
            self.init(0)
            return
        }

        try self.init(RawValue(truncatingIfNeeded: bitStorage.read(Int(byteWidth) * 8)))
    }
}

// MARK: - VInt4

/// Up-to-15-byte (120-bit) unsigned integer (4-bit length prefix)
public struct VInt4: VariableWidthInteger, BitStorageRepresentable {
    // MARK: Lifecycle

    public init(rawValue: BigInt) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public static let sizeBitWidth: Int = 4

    public var rawValue: BigInt
}

// MARK: - VUInt4

/// Up-to-15-byte (120-bit) unsigned integer (4-bit length prefix)
public struct VUInt4: VariableWidthInteger, BitStorageRepresentable {
    // MARK: Lifecycle

    public init(rawValue: BigUInt) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public static let sizeBitWidth: Int = 4

    public var rawValue: BigUInt
}

// MARK: - VInt5

/// Up-to-31-byte (248-bit) unsigned integer (5-bit length prefix)
public struct VInt5: VariableWidthInteger, BitStorageRepresentable {
    // MARK: Lifecycle

    public init(rawValue: BigInt) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public static let sizeBitWidth: Int = 5

    public var rawValue: BigInt
}

// MARK: - VUInt5

/// Up-to-31-byte (248-bit) unsigned integer (5-bit length prefix)
public struct VUInt5: VariableWidthInteger, BitStorageRepresentable {
    // MARK: Lifecycle

    public init(rawValue: BigUInt) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public static let sizeBitWidth: Int = 5

    public var rawValue: BigUInt
}
