//
//  Created by Anton Spivak
//

import Foundation

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

// MARK: - SnakeData

/// A snake-encoded byte collection for storing strings or arbitrary data
/// in a recursive "snake" cell layout. Often used to pack more than 1023 bits
/// across multiple cells.
public struct SnakeData: RawRepresentable, Sendable, Hashable {
    // MARK: Lifecycle

    /// Creates a `SnakeData` from a `Data`.
    ///
    /// - Parameter rawValue: The underlying bytes to be stored in a snake-encoded format.
    @inlinable @inline(__always)
    public init(_ rawValue: Data) {
        self.init(rawValue: rawValue)
    }

    @inlinable @inline(__always)
    public init(rawValue: Data) {
        self.rawValue = rawValue
    }

    // MARK: Public

    /// The bytes stored in this snake-encoded collection.
    public let rawValue: Data
}

// MARK: CellCodable

extension SnakeData: CellCodable {
    /// Decodes a `SnakeData` from multiple concatenated "snake" cells.
    /// It recursively consumes child cells until it has read all bytes.
    ///
    /// - Parameter container: The decoding container to read from.
    /// - Throws: `TLBCodingError.invalidSnakeEncodedData()` if the cell structure is malformed.
    public init(from container: inout CellDecodingContainer) throws {
        var rawValue = Data()
        try SnakeData._assume(from: &container, to: &rawValue)
        self = .init(rawValue: rawValue)
    }

    /// Encodes this `SnakeData` into one or more cells. If the raw bytes
    /// exceed the available bits in the current cell, it splits them and encodes
    /// the remainder in a child cell.
    ///
    /// - Parameter container: The container in which to write bits/children.
    /// - Throws: If the data doesn't fit or there's an encoding constraint error.
    public func encode(to container: inout CellEncodingContainer) throws {
        guard !rawValue.isEmpty
        else {
            return
        }

        let capacity = Int(floor(Double(container.remaining.storage / 8)))
        if rawValue.count > capacity {
            try container.encode(Data(rawValue[0 ..< capacity]))
            let postfix = rawValue[capacity ..< rawValue.endIndex]
            try container.encode(Data(postfix))
        } else {
            try container.encode(rawValue)
        }
    }

    static func _assume(
        from container: inout CellDecodingContainer,
        to rawValue: inout Data
    ) throws {
        let storage = container.storage.remaining.count
        guard storage % 8 == 0
        else { throw TLBCodingError.invalidSnakeEncodedData() }

        try rawValue.append(contentsOf: container.decode())

        let children = container.storage.remaining.count
        guard children < 2
        else { throw TLBCodingError.invalidSnakeEncodedData() }

        var container = try CellDecodingContainer(container.decode(Cell.self))
        try _assume(from: &container, to: &rawValue)
    }
}

// MARK: - SnakeEncodedString

/// A snake-encoded UTF-8 string. Wraps `SnakeData` but interprets the bytes as text.
public struct SnakeEncodedString: RawRepresentable {
    // MARK: Lifecycle

    /// Creates a `SnakeEncodedString` from a plain `String`.
    ///
    /// - Parameter rawValue: The UTF-8 string content to store.
    @inlinable @inline(__always)
    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    @inlinable @inline(__always)
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public let rawValue: String
}

// MARK: Hashable

extension SnakeEncodedString: Hashable {}

// MARK: Sendable

extension SnakeEncodedString: Sendable {}

// MARK: CellCodable

extension SnakeEncodedString: CellCodable {
    public init(from container: inout CellDecodingContainer) throws {
        let _ = try container.decode(UInt32.self) // header
        let snakeData = try SnakeData(from: &container)
        self.rawValue = String(decoding: snakeData.rawValue, as: UTF8.self)
    }

    public func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(0, truncatingToBitWidth: 32)
        try SnakeData(rawValue: Data(rawValue.utf8)).encode(to: &container)
    }
}
