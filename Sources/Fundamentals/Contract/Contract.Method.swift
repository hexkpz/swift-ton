//
//  Created by Anton Spivak
//

// MARK: - Contract.Method

public extension Contract {
    /// Protocol defining a typed contract method, responsible for
    /// encoding arguments for on-chain calls and decoding returned results.
    ///
    /// Conforming types must specify:
    /// 1. A static `name` matching the on-chain method name in the contract ABI.
    /// 2. An associated `Result` type that represents the decoded return value.
    /// 3. A `RawValue` (alias `Arguments`) representing the input parameters before encoding.
    ///
    /// At runtime, clients construct an instance via `init(rawValue:)`, call
    /// `encode()` to produce a `Tuple` for transmission, and after the network
    /// response is received, call `decode(_:)` to obtain the strongly-typed result.
    protocol Method: RawRepresentable {
        /// The on-chain method name used in ABI calls.
        /// Must match exactly the method identifier in the smart contract.
        static var name: String { get }

        /// The decoded return type of the method.
        associatedtype Result

        /// Alias for the raw argument type before encoding.
        /// By default, `Arguments` == `RawValue`.
        typealias Arguments = RawValue

        /// Initializes the method with raw argument data.
        ///
        /// - Parameter rawValue: The raw arguments provided by the caller,
        ///   matching the expected shape (e.g., a tuple of parameters).
        init(rawValue: RawValue)

        /// Encodes the arguments into a `Tuple` ready for transport over the network.
        ///
        /// - Returns: A `Tuple` representing the ABI-encoded arguments.
        /// - Throws: Any error encountered during encoding (e.g., invalid parameter types).
        func encode() throws -> Tuple

        /// Decodes a returned `Tuple` into the typed `Result`.
        ///
        /// - Parameter result: The raw `Tuple` returned by the network provider.
        /// - Returns: A `Result` value reconstructed from the tuple contents.
        /// - Throws: Any decoding error (e.g., unexpected tuple shape, missing fields).
        func decode(_ result: Tuple) throws -> Result
    }
}

public extension Contract.Method where RawValue == Void {
    /// Default implementation of `encode()` for methods that take no arguments.
    /// Simply returns an empty `Tuple` (zero elements).
    ///
    /// - Returns: A `Tuple` with an empty `rawValue` array.
    /// - Throws: This implementation never throws.
    func encode() throws -> Tuple { .init(rawValue: []) }
}
