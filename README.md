# swift-ton

A Swift-based toolkit for working with [The Open Network (TON)](https://ton.org). This library provides comprehensive utilities for constructing and decoding TON cells, managing addresses (both internal and friendly formats), creating and manipulating credentials (including mnemonic derivation), interacting with smart contracts (including Wallet contracts), working with Jettons (TON’s fungible token standard), and resolving DNS entries on-chain.

![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20Linux-blue)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)

> [!CAUTION]
> Currently is not well-tested version.

### Highlights

- ✅ **BOC, Cell, TVM Primitives & Types**  
  - Work directly with Bits, Cells, and Bag-of-Cells (BOC) serialization/de-serialization.
- ✅ **Wallet Contracts** (v3r2, v4r2, v5r1)  
  - Type-safe external calls for common wallet operations (e.g., transfers, custom calls).
- ✅ **Credentials**  
  - Mnemonic-based (_TON/BIP39_) key generation, Ed25519 signing, and public key derivation.
- 🟡 **DNS Contract** (read-only)  
  - Resolve `.ton` domains on-chain (lookup wallet addresses, smart contract addresses).
- ✅ **Jetton Contracts** (TEP-0074)  
  - Transferring, and burning Jetton tokens via typed contract interface.
- 🟡 **ABI-based Contract Calls**  
  - Strongly-typed method invocation (`Contract.Method`) with `encode`/`decode`.
- 🟡 **Utilities**  
  - Misc. helpers for `CurrencyValue`, `BitStorage`, `CellEncodable`/`CellDecodable` protocols.

### Supported Platforms

- ✅ Linux
- ✅ iOS 13.2+
- ✅ macOS 10.15+
- ✅ tvOS 13.2+
- ✅ watchOS 6.1+

---

## Table of Contents

- [Installation](#installation)
- [Usage Overview](#usage-overview)
  - [Encoding & Decoding Cells](#encoding--decoding-cells)
  - [Working with BOC (Bag-of-Cells)](#working-with-boc-bag-of-cells)
  - [Addresses](#addresses)
- [Smart Contracts](#smart-contracts)
  - [Wallets](#wallets)
  - [DNS](#dns)
  - [Jettons](#jettons)
- [Contributing](#contributing)
- [License](#license)
- [Contact & Support](#contact--support)

---

## Installation

In your **Package.swift**, add:

```swift
dependencies: [
  .package(url: "https://github.com/hexkpz/swift-ton.git", from: "0.1.0")
]
```

## Usage Overview

### Encoding & Decoding Cells

#### Encoding

```swift
// Direct BitStorage & Children

// Build a cell with 3 bits (1,0,1) and a single empty child.
let bits = BitStorage([true, false, true]) // 3 bits: 1,0,1
let cell = try Cell(.ordinary, storage: bits, children: [Cell()])
print("\(desribing: cell)")

// DSL via String Interpolation

// Compose bits / integers / sub-cells inline:
let cell: Cell = "101001\(true)00\(UInt32(1), truncatingToBitWidth: 34)\(children)"
print("\(desribing: cell2)")

// DSL via Result Builder

let cell = try Cell {
    true                         // single bit
    "1101"                       // string => bits
    BitStorage("1001001")        // more bits
    UInt32(42)                   // integer => bits
    try Cell { false }           // child cell containing single `false`
}
print("\(desribing: cell)")

// Using `CellEncodable`

struct Item: CellEncodable {
    let id: UInt32
    let value: UInt32
    let optionalValue: UInt32?

    func encode(to container: inout CellEncodingContainer) throws {
        try container.encode(id)
        try container.encode(value, truncatingToBitWidth: 8)
        try container.encodeIfPresent(optionalValue)
    }
}

let cell = try Cell(Item(id: 0xDEAD_BEEF, value: 42, optionalValue: nil))
print("\(desribing: cell)")
```

#### Decoding

```swift
// Block-Based API

let result: Bool = try cell.decode { container in
    try container.decode(Bool.self)
}
print("Decoded flag: \(result)")

// Using `CellDecodable`

struct Item: CellDecodable {
    let id: UInt32

    init(from container: inout CellDecodingContainer) throws {
        self.id = try container.decode(UInt32.self)
    }
}

let item = try cell.decode(Item.self)
print("Decoded ID: \(item.id)")
```

### Working with BOC (Bag-of-Cells)

```swift
// Encode a root cell into a BOC:

let cell: Cell = try Cell { true; "01" }
let boc = try BOC(cell)
print("BOC hex: \(boc.hexadecimalString)")

// Decode a BOC string into cells:

if let boc = try? BOC("<hexadecimalString>") {
    print("Decoded cells count: \(boc.cells)")
}
```

### Addresses

```swift
let internalAddrress = InternalAddress(workchain: .basic, hash: my32ByteHash)
print(internalAddrress.description) // e.g. "0:FFEEDD..."

let friendly = FriendlyAddress(internalAddrress, options: [.bounceable], format: .base64url)
print(friendly.description) // base64url string
```

## Smart Contracts

### Wallets

```swift
let networkProvider = ToncenterNetworkProvider()

let credentials = Credentials.generate()
let wallet: any WalletContract = try WalletV3R2(credentials: credentials)

let action = try wallet.transfer(
    to: "UQCd3ASamrfErTV4K6iG5r0o3O_hl7K_9SghU0oELKF-s00i",
    10.0,
    comment: "Hello TON!",
    signedBy: credentials
)

try await networkProvider.execute(action)
print("Transfer sent!")

let publicKey = try await wallet.getPublicKey(using: networkProvider)
print("On-chain public key: \(onChainPubKey.hexadecimalString)")
```

### DNS

```swift
let rootDNSAddress: FriendlyAddress = "Ef_lZ1T4NCb2mwkme9h2rJfESCE0W34ma9lWp7-_uY3zXDvq"
let dns = DNSContract(address: .init(rootDNSAddress))

let networkProvider = ToncenterNetworkProvider()
let walletAddress = try await dns.recursivelyResolveWalletAddress("spivak.ton", using: networkProvider)

print("Resolved wallet: \(walletAddress)")
```

### Jettons

```swift
let networkProvider = ToncenterNetworkProvider()

let userWalletAddress0: FriendlyAddress = "UQCd3ASamrfErTV4K6iG5r0o3O_hl7K_9SghU0oELKF-s00i"
let userWalletAddress1: FriendlyAddress = "UQDYzZmfsrGzhObKJUw4gzdeIxEai3jAFbiGKGwxvxHinf4K"

let usdtJettonAddress: FriendlyAddress = "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs"
let jetton = Jetton.MinterContract(address: .init(usdtJettonAddress))

let userJettonWallet0 = try await jetton.wallet(for: .init(userWalletAddress0), using: networkProvider)
        
let userWallet0 = WalletV3R2(address: .init(userWalletAddress0))
try await userWallet0.update(using: networkProvider)
        
let actions = try userWallet0.send(
    to: userJettonWallet0,
    .transfer(to: .init(userWalletAddress1), amount: .init(rawValue: 10_000_000), excessesResponseAddress: userWallet0.address),
    signedBy: credentials
)

try await networkProvider.execute(actions)

print("Sent 10 USDT to \(userWalletAddress1)")
```
---

## Contributing

We welcome all PRs—especially tests. If you have a fix, feature request, or question:

1. Fork this repo.
2. Make a branch.
3. Submit a pull request.

We appreciate issues describing bugs or proposing changes before major work.

## License

This library is distributed under the MIT License.
There is no warranty or guarantee; it’s UNSTABLE — use at your own risk, and we need your help testing!

## Contact & Support

- Post an issue or pull request if you encounter problems.
- hexkpz@gmail.com
