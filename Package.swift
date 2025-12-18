// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "NetworkSpectator",
    platforms: [
        .iOS(.v17),
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
