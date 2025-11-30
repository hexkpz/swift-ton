//
//  Created by Anton Spivak
//

import Foundation

import Fundamentals
import FundamentalsExtensions

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - ToncenterNetworkProvider

public struct ToncenterNetworkProvider {
    // MARK: Lifecycle

    public init(authenticationKey: String? = nil) {
        self.authenticationKey = authenticationKey
    }

    // MARK: Public

    public let authenticationKey: String?

    // MARK: Private

    private let session = URLSession.shared

    private let mainnet: URL = .init(string: "https://toncenter.com/api/v3")!
    private let testnet: URL = .init(string: "https://testnet.toncenter.com/api/v3")!

    private func request(
        _ path: String,
        query: [URLQueryItem] = [],
        network: NetworkKind
    ) -> URLRequest {
        var url = baseURL(for: network).appendingPathComponent(path)

        if !query.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = query
            if let _url = components?.url {
                url = _url
            }
        }

        var request = URLRequest(url: url)
        var allHTTPHeaderFields = [
            "accept": "application/json",
            "Content-Type": "application/json",
        ]

        if let authenticationKey {
            allHTTPHeaderFields["X-Api-Key"] = authenticationKey
        }

        request.allHTTPHeaderFields = allHTTPHeaderFields
        return request
    }

    private func baseURL(for network: NetworkKind) -> URL {
        switch network {
        case .mainnet: mainnet
        case .testnet: testnet
        }
    }

    private func check(_ response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse
        else { throw ToncenterError.invalidResponse("Network error") }

        guard response.statusCode == 200
        else { throw ToncenterError.invalidResponse("Network error: \(response.statusCode)") }
    }
}

// MARK: Sendable

extension ToncenterNetworkProvider: Sendable {}

// MARK: NetworkProvider

extension ToncenterNetworkProvider: NetworkProvider {
    public func state(
        for address: InternalAddress,
        in network: NetworkKind
    ) async throws -> Contract.State {
        let query: [URLQueryItem] = [
            .init(name: "address", value: FriendlyAddress(address).description),
            .init(name: "include_boc", value: "true"),
        ]

        var request = request("/accountStates", query: query, network: network)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)
        try check(response)

        struct Response: Decodable {
            public let accounts: [FullAccountState]
        }

        let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
        guard let account = decodedResponse.accounts.first,
              account.address == address
        else {
            throw ToncenterError.invalidResponse(
                "Response does not contain expected data, or address does not match"
            )
        }

        return .init(
            balance: account.balance,
            status: {
                let status: Contract.State.Status
                switch account.status {
                case .active:
                    guard let data = account.data_boc, let code = account.code_boc
                    else { return .uninitialized }
                    status = .active(code: code, data: data)
                case .frozen:
                    guard let hash = account.frozen_hash
                    else { return .uninitialized }
                    status = .frozen(hash: Data(hash))
                case .uninitialized:
                    status = .uninitialized
                case .nonexistent:
                    status = .nonexistent
                }
                return status
            }(),
            lastHash: {
                if let hash = account.last_transaction_hash { .init(hash) }
                else { nil }
            }(),
            lastLogicalTime: {
                if let rawLogicalTime = account.last_transaction_lt,
                   let logicalTime = Int64(rawLogicalTime)
                { .init(logicalTime) }
                else { nil }
            }()
        )
    }

    public func send(boc: BOC, in network: NetworkKind) async throws {
        struct Request: Encodable {
            let boc: BOC
        }

        var request = request("/runGetMethod", network: network)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(Request(boc: boc))

        let (data, response) = try await session.data(for: request)
        try check(response)

        struct Response: Decodable {
            let message_hash: Data
        }

        let _ = try JSONDecoder().decode(Response.self, from: data)
    }

    public func run(
        _ method: String,
        arguments: Tuple,
        on: InternalAddress,
        in network: NetworkKind
    ) async throws -> Tuple {
        struct Request: Encodable {
            let address: InternalAddress
            let method: String
            let stack: [StackElement]
        }

        var request = request("/runGetMethod", network: network)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(Request(
            address: on,
            method: method,
            stack: arguments.rawValue.map({ .init(from: $0) })
        ))

        let (data, response) = try await session.data(for: request)
        try check(response)

        struct Response: Decodable {
            let exit_code: Int
            let stack: [StackElement]
        }

        let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
        guard decodedResponse.exit_code == 0
        else {
            throw ToncenterError.invalidResponse("Nonzero exit code: \(decodedResponse.exit_code)")
        }

        return .init(rawValue: decodedResponse.stack.map({ .init(from: $0) }))
    }
}
