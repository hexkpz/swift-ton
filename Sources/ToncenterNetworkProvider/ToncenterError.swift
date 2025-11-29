//
//  Created by Anton Spivak
//

import Fundamentals

// MARK: - ToncenterError

public enum ToncenterError: Error {
    case invalidResponse(String)
}

// MARK: LocalizedError

extension ToncenterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidResponse(description): "Invalid response: '\(description)'"
        }
    }
}
