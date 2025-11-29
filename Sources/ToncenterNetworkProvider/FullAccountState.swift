//
//  Created by Anton Spivak
//

import Fundamentals
import FundamentalsExtensions

// MARK: - FullAccountState

struct FullAccountState {
    let account_state_hash: Data?
    let frozen_hash: Data?

    let address: InternalAddress
    let balance: CurrencyValue

    let code_boc: Cell?
    let code_hash: Data?

    let data_boc: Cell?
    let data_hash: Data?

    let last_transaction_hash: Data?
    let last_transaction_lt: String?

    let status: AccountStatus
}

// MARK: Decodable

extension FullAccountState: Decodable {}

// MARK: Sendable

extension FullAccountState: Sendable {}

// MARK: FullAccountState.AccountStatus

extension FullAccountState {
    enum AccountStatus: String {
        case active
        case frozen
        case uninitialized = "uninit"
        case nonexistent = "nonexist"
    }
}

// MARK: - FullAccountState.AccountStatus + Decodable

extension FullAccountState.AccountStatus: Decodable {}

// MARK: - FullAccountState.AccountStatus + Sendable

extension FullAccountState.AccountStatus: Sendable {}
