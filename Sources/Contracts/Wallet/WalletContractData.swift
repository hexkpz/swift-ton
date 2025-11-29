//
//  Created by Anton Spivak
//

import Fundamentals

/// A protocol defining the on-chain data layout for a wallet contract,
/// capturing essential state information required for building and signing
/// messages. Conforming types represent the minimal data needed to ensure
/// transaction uniqueness (via `seqno`) and message authorization (via `publicKey`).
public protocol WalletContractData {
    /// The sequence number (`seqno`) is a 32-bit unsigned integer that
    /// increments with each outgoing transaction from the wallet. It ensures
    /// that each transaction is unique and prevents replay attacks.
    ///
    /// - Note: Before sending a transaction, clients typically fetch the
    ///   current `seqno` from the blockchain to pass it into the signing logic.
    var seqno: UInt32 { get }

    /// The Ed25519 public key associated with this wallet’s key pair.
    /// Used to verify signatures on outgoing messages and to derive the
    /// wallet address if needed.
    ///
    /// - Note: This value must match the private key held in the client’s
    ///   `Credentials` for transaction signing to succeed.
    var publicKey: Data { get }
}
