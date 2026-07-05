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
                "Domain/Network/Capture/NetworkInterceptor.swift",
                "Domain/Network/Capture/NetworkURLProtocol.swift",
                "Domain/Network/Capture/URLSessionConfiguration+Extension.swift",
                "Domain/Network/Capture/NetworkItemLogger.swift",
                "Domain/ConsoleLogging/DebugPrint.swift",
                "Domain/Persistence/StorageManager.swift",
                "Domain/Rules/MatchRule.swift",
                "Entities/HTTPMethod.swift",
                "Entities/HTTPResponse.swift",
                "Entities/LogItem.swift",
                "Entities/MimeType.swift",
                "Entities/NetworkLogMetrics.swift",
            ]
        ),
        .target(
            name: "NetworkSpectatorMocking",
            dependencies: ["NetworkSpectatorCore"],
            path: "Sources/NetworkSpectator",
            sources: [
                "Domain/Rules/Mock/Mock.swift",
                "Domain/Rules/Mock/MockServer.swift",
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
                "Domain/Export/CSVExporter.swift",
                "Domain/Export/ExportManager.swift",
                "Domain/Export/PostmanExporter.swift",
                "Domain/Export/TextExporter.swift",
                "Domain/Network/Logging/NetworkLogContainer.swift",
                "Domain/Network/Logging/NetworkLogItemLogger.swift",
                "Domain/Network/Logging/NetworkLogMonitor.swift",
                "Domain/Network/Logging/NetworkLogStore.swift",
                "Domain/Persistence/EmptyStorage.swift",
                "Domain/Persistence/LogHistoryManager.swift",
                "Domain/Persistence/LogHistoryStorage.swift",
                "Domain/Persistence/PreferenceStorage.swift",
                "Domain/Rules/Exclusion/LoggingExclusionManager.swift",
                "Domain/Rules/Exclusion/LoggingExclusionRule.swift",
                "Entities/HistoryItem.swift",
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
                "Presentation/Insights",
                "Presentation/LogDetails",
                "Presentation/LogList",
                "Presentation/Root",
                "Presentation/Settings",
                "Presentation/ShareActivity",
                "Presentation/Shared",
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
