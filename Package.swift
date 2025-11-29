// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ton",
    platforms: [
        .macOS("10.15"),
        .iOS("13.2"),
        .watchOS("6.1"),
        .tvOS("13.2"),
    ],
    products: [
        .library(name: "TON", targets: ["TON"]),

        .library(name: "Contracts", targets: ["Contracts"]),
        .library(name: "Credentials", targets: ["Credentials"]),

        .library(name: "Fundamentals", targets: ["Fundamentals"]),
        .library(name: "FundamentalsExtensions", targets: ["FundamentalsExtensions"]),

        .library(name: "ConnectProtocol", targets: ["ConnectProtocol"]),
        .library(name: "ToncenterNetworkProvider", targets: ["ToncenterNetworkProvider"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.1"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.10.0"),

        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.5.1"),
        .package(url: "https://github.com/hexkpz/swift-bip.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "TON",
            dependencies: [
                .byName(name: "Fundamentals"),
                .byName(name: "Contracts"),
                .byName(name: "Credentials"),
                .byName(name: "ConnectProtocol"),
            ],
            path: "Sources/TON"
        ),
        .target(
            name: "ConnectProtocol",
            dependencies: [
                .byName(name: "Fundamentals"),
                .byName(name: "FundamentalsExtensions"),
                .byName(name: "Contracts"),
                .byName(name: "Credentials"),
            ],
            path: "Sources/ConnectProtocol"
        ),
        .target(
            name: "Contracts",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "BigInt", package: "BigInt"),
                .byName(name: "Fundamentals"),
                .byName(name: "Credentials"),
            ],
            path: "Sources/Contracts"
        ),
        .testTarget(
            name: "ContractsTests",
            dependencies: [
                .byName(name: "Contracts"),
            ],
            path: "Sources/ContractsTests"
        ),
        .target(
            name: "Credentials",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "BIP", package: "swift-bip"),
            ],
            path: "Sources/Credentials"
        ),
        .testTarget(
            name: "CredentialsTests",
            dependencies: [
                .byName(name: "Credentials"),
                .byName(name: "Contracts"),
            ],
            path: "Sources/CredentialsTests"
        ),
        .target(
            name: "Fundamentals",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "BigInt", package: "BigInt"),
            ],
            path: "Sources/Fundamentals"
        ),
        .testTarget(
            name: "FundamentalsTests",
            dependencies: [
                .byName(name: "Fundamentals"),
            ],
            path: "Sources/FundamentalsTests"
        ),
        .target(
            name: "FundamentalsExtensions",
            dependencies: [
                .byName(name: "Fundamentals"),
            ],
            path: "Sources/FundamentalsExtensions"
        ),
        .target(
            name: "ToncenterNetworkProvider",
            dependencies: [
                .byName(name: "Fundamentals"),
                .byName(name: "FundamentalsExtensions"),
            ],
            path: "Sources/ToncenterNetworkProvider"
        ),
    ]
)
