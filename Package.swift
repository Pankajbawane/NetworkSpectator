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
    ],
    targets: [
        .target(
            name: "NetworkSpectator"
        ),
        .testTarget(
            name: "NetworkSpectatorTests",
            dependencies: ["NetworkSpectator"]
        ),
    ]
)
