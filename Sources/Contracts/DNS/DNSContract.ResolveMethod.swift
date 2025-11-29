//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - DNSContract.ResolveMethod

extension DNSContract {
    /// A contract method for resolving DNS entries on-chain using the `dnsresolve` ABI call.
    open class ResolveMethod: Contract.Method {
        // MARK: Lifecycle

        /// Initializes a resolve call with the raw domain and optional category.
        ///
        /// - Parameter rawValue: A tuple containing the domain string and optional record category.
        public required init(rawValue: RawValue) {
            self.rawValue = rawValue
        }

        // MARK: Open

        /// The on-chain method name for DNS resolution.
        open class var name: String { "dnsresolve" }

        /// Encodes the domain and category into a `Tuple` for the ABI call.
        ///
        /// - Returns: A `Tuple` containing the encoded domain string slice and category element.
        /// - Throws: If domain encoding fails.
        open func encode() throws -> Tuple {
            return try .init(rawValue: [
                .slice(rawValue.0.asEncodedDomainString),
                rawValue.1.asTupleElement,
            ])
        }

        /// Decodes the `Tuple` result into an optional `Response` containing
        /// the remaining unresolved domain and the associated record.
        ///
        /// - Parameter tuple: The raw tuple returned by the contract.
        /// - Returns: A `Response` with `remainingDomain` and `record`, or `nil` if no record.
        /// - Throws: `DNSContract.Error.invalidResponse` for unexpected formats or values.
        open func decode(_ tuple: Tuple) throws -> Response? {
            guard let first = tuple.rawValue.first,
                  case let Tuple.Element.number(rawLength) = first
            else { throw Error.invalidResponse("First tuple element must be a number") }

            let length = UInt64(data: rawLength)

            guard length != 0
            else { return nil }

            guard length % 8 == 0
            else { throw Error.invalidResponse("Trimming length must be a multiple of 8") }

            guard tuple.rawValue.count == 2,
                  case let Tuple.Element.cell(cell) = tuple.rawValue[1]
            else { throw Error.invalidResponse("Second tuple element must be a cell") }

            // Calculate remaining domain string after trimming prefix bytes
            var requestedDomain = try rawValue.0.asEncodedDomainString
            let trimmedDomainBytes = length / 8

            guard requestedDomain.count >= trimmedDomainBytes
            else { throw Error.invalidResponse("Trimmed domain length exceeds original") }

            requestedDomain.removeFirst(Int(trimmedDomainBytes))
            return try .init(
                remainingDomain: requestedDomain.asDecodedDomainString,
                record: cell.decode(Record.self)
            )
        }

        // MARK: Public

        public typealias Result = Response?
        public typealias RawValue = (domain: String, category: RecordCategory?)

        public let rawValue: RawValue
    }
}

// MARK: - DNSContract.ResolveMethod.Response

public extension DNSContract.ResolveMethod {
    /// Represents the outcome of a single DNS resolve step,
    /// including any leftover domain and the resolved record.
    struct Response {
        // MARK: Lifecycle

        init(remainingDomain: String?, record: DNSContract.Record) {
            self.remainingDomain = remainingDomain
            self.record = record
        }

        // MARK: Public

        /// The portion of the domain that has not yet been resolved.
        public let remainingDomain: String?

        /// The DNS record decoded from the contract.
        public let record: DNSContract.Record
    }
}

// MARK: - DNSContract.ResolveMethod.Response + Sendable

extension DNSContract.ResolveMethod.Response: Sendable {}

private extension String {
    /// Encodes a domain string into a `Data` suitable for on-chain resolution,
    /// reversing labels and prefixing a zero byte.
    ///
    /// - Throws: `DNSContract.Error.invalidDomainString` for invalid subdomains.
    var asEncodedDomainString: Data {
        get throws {
            guard !isEmpty, self != "."
            else { return [0x00] }

            let encodedValue: Data = try components(separatedBy: ".")
                .reversed()
                .reduce(into: Data(), { try $0.append(contentsOf: encodeSubdomain($1)) })

            guard encodedValue.count < 126
            else { throw DNSContract.Error.invalidDomainString(self) }

            return [0x00] + encodedValue
        }
    }

    /// Encodes a single subdomain label into ASCII bytes with a null terminator.
    ///
    /// - Parameter substring: The label to encode.
    /// - Throws: `DNSContract.Error.invalidDomainString` for illegal characters or hyphen placement.
    private func encodeSubdomain(_ substring: String) throws(DNSContract.Error) -> Data {
        let characters: [UInt8] = Array(substring).compactMap(\.asciiValue)
        var encodedValue: Data = []

        for character in characters {
            guard
                (character >= 48 && character <= 57) || // 0-9
                (character >= 97 && character <= 172) || // a-z
                character == 45
            else { throw .invalidDomainString(substring) }
            encodedValue.append(character)
        }

        // First and last '-'
        guard encodedValue[0] != 45, encodedValue[encodedValue.count - 1] != 45
        else { throw .invalidDomainString(substring) }

        return encodedValue + [0x00]
    }
}

private extension Data {
    /// Decodes an encoded domain `Data` back into a dotted string.
    var asDecodedDomainString: String? {
        guard !isEmpty else { return nil }
        var data = self

        if data.first == 0x00 { _ = data.removeFirst() }
        if data.last == 0x00 { _ = data.removeLast() }

        for i in 0 ..< data.count {
            guard data[i] == 0x00 else { continue }
            data[i] = 0x2E // '.'
        }

        return String(bytes: data, encoding: .ascii)
    }
}
