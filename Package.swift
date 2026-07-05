// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NetworkSpectator",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "NetworkSpectator",
            targets: ["NetworkSpectator"]
        ),
        .library(
            name: "NetworkSpectatorCore",
            targets: ["NetworkSpectatorCore"]
        ),
        .library(
            name: "NetworkSpectatorMocking",
            targets: ["NetworkSpectatorMocking"]
        ),
        .library(
            name: "NetworkSpectatorLogging",
            targets: ["NetworkSpectatorLogging"]
        ),
        .library(
            name: "NetworkSpectatorUI",
            targets: ["NetworkSpectatorUI"]
        ),
    ],
    targets: [
        .target(
            name: "NetworkSpectatorCore",
            path: "Sources/NetworkSpectator",
            sources: [
                "Domain"
            ]
        ),
        .target(
            name: "NetworkSpectatorMocking",
            dependencies: [
                "NetworkSpectatorCore",
            ],
            path: "Sources/NetworkSpectator",
            sources: [
                "Mocking"
            ]
        ),
        .target(
            name: "NetworkSpectatorLogging",
            dependencies: [
                "NetworkSpectatorCore",
                "NetworkSpectatorMocking",
            ],
            path: "Sources/NetworkSpectator",
            sources: [
                "Logging"
            ]
        ),
        .target(
            name: "NetworkSpectatorUI",
            dependencies: [
                "NetworkSpectatorCore",
                "NetworkSpectatorMocking",
                "NetworkSpectatorLogging",
            ],
            path: "Sources/NetworkSpectator",
            sources: [
                "Presentation"
            ]
        ),
        .target(
            name: "NetworkSpectator",
            dependencies: [
                "NetworkSpectatorCore",
                "NetworkSpectatorMocking",
                "NetworkSpectatorLogging",
                "NetworkSpectatorUI",
            ],
            path: "Sources/NetworkSpectator",
            sources: [
                "NetworkSpectator.swift",
            ]
        ),
        .testTarget(
            name: "NetworkSpectatorTests",
            dependencies: [
                "NetworkSpectator",
                "NetworkSpectatorCore",
                "NetworkSpectatorMocking",
                "NetworkSpectatorLogging",
                "NetworkSpectatorUI",
            ]
        ),
    ]
)
