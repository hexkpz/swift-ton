//
//  Created by Anton Spivak
//

import Fundamentals
import FundamentalsExtensions

// MARK: - SendingTransactionResponse

public struct SendingTransactionResponse: HostApplicationResponse {
    // MARK: Lifecycle

    public init(id: String, result: Result<BOC, ConnectError>) {
        self.id = id
        self.result = result
    }

    // MARK: Public

    public typealias Success = BOC

    public var id: String
    public let result: Result<BOC, ConnectError>
}

// MARK: Sendable

extension SendingTransactionResponse: Sendable {}

// MARK: SendingTransactionResponse.Error

public extension SendingTransactionResponse {
    struct Error: ConnectErrorConvertible, Sendable {
        // MARK: Lifecycle

        private init(code: ConnectError.Code, message: String?) {
            self.code = code
            self.message = message
        }

        // MARK: Public

        public let code: ConnectError.Code
        public let message: String?
    }
}

public extension SendingTransactionResponse.Error {
    static func unknown(
        _ message: String? = nil
    ) -> Self { .init(code: .unknown, message: message) }

    static func badRequest(
        _ message: String? = nil
    ) -> Self { .init(code: .badRequest, message: message) }

    static func unknownWebApplication(
        _ message: String? = nil
    ) -> Self { .init(code: .unknownWebApplication, message: message) }

    static func userDeclined(
        _ message: String? = nil
    ) -> Self { .init(code: .userDeclined, message: message) }

    static func unsupportedMethod(
        _ message: String? = nil
    ) -> Self { .init(code: .unsupportedMethod, message: message) }
}
