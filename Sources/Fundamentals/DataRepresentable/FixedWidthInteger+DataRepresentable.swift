//
//  Created by Anton Spivak
//

import Foundation

public extension DataConvertible where Self: FixedWidthInteger {
    func data(with endianness: Endianness = .big) -> Data {
        var value = switch endianness {
        case .little: littleEndian
        case .big: bigEndian
        }
        return withUnsafeBytes(of: &value, { Data($0) })
    }
}

public extension ExpressibleByData where Self: FixedWidthInteger {
    init(data: Data, _ endianness: Endianness = .big) {
        var bytes = data
        let lackingBytesCount = MemoryLayout<Self>.size - bytes.count

        precondition(
            lackingBytesCount >= 0,
            "Couldn't initialize \(String(describing: Self.self)):\(MemoryLayout<Self>.size) with bytes count \(bytes.count)"
        )

        if lackingBytesCount > 0 {
            let lackingBytes = [UInt8](repeating: 0x00, count: lackingBytesCount)
            switch endianness {
            case .little: bytes = bytes + lackingBytes
            case .big: bytes = lackingBytes + bytes
            }
        }

        let value = bytes.withUnsafeBytes({ $0.load(as: Self.self) })
        self = switch endianness {
        case .little: value // Swift uses .littleEndian by default
        case .big: value.byteSwapped
        }
    }
}

// MARK: - Int + DataRepresentable

extension Int: DataRepresentable {}

// MARK: - UInt8 + DataRepresentable

extension UInt8: DataRepresentable {}

// MARK: - UInt16 + DataRepresentable

extension UInt16: DataRepresentable {}

// MARK: - UInt32 + DataRepresentable

extension UInt32: DataRepresentable {}

// MARK: - UInt64 + DataRepresentable

extension UInt64: DataRepresentable {}

// MARK: - UInt + DataRepresentable

extension UInt: DataRepresentable {}

// MARK: - Int8 + DataRepresentable

extension Int8: DataRepresentable {}

// MARK: - Int16 + DataRepresentable

extension Int16: DataRepresentable {}

// MARK: - Int32 + DataRepresentable

extension Int32: DataRepresentable {}

// MARK: - Int64 + DataRepresentable

extension Int64: DataRepresentable {}
