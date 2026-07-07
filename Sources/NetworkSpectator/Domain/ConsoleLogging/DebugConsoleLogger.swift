//
//  DebugConsoleLogger.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 08/12/25.
//

import Foundation

public struct ConsoleLoggingConfiguration: Sendable, Equatable {
    public static let `default` = ConsoleLoggingConfiguration()

    public let includesRequestHeaders: Bool
    public let includesResponseHeaders: Bool
    public let includesRequestBody: Bool
    public let includesResponseBody: Bool
    public let maximumBodyLength: Int
    public let maximumHeaderLength: Int

    public init(
        includesRequestHeaders: Bool = true,
        includesResponseHeaders: Bool = true,
        includesRequestBody: Bool = true,
        includesResponseBody: Bool = true,
        maximumBodyLength: Int = 20_000,
        maximumHeaderLength: Int = 8_000
    ) {
        self.includesRequestHeaders = includesRequestHeaders
        self.includesResponseHeaders = includesResponseHeaders
        self.includesRequestBody = includesRequestBody
        self.includesResponseBody = includesResponseBody
        self.maximumBodyLength = max(0, maximumBodyLength)
        self.maximumHeaderLength = max(0, maximumHeaderLength)
    }
}

package final class DebugConsoleLogger: @unchecked Sendable {
    package static let shared: DebugConsoleLogger = .init()

    private let lock = NSLock()
    private var isEnabled = false
    private var configuration: ConsoleLoggingConfiguration = .default

    package func update(_ isEnabled: Bool, configuration: ConsoleLoggingConfiguration = .default) {
        #if DEBUG
        withLock {
            self.isEnabled = isEnabled
            self.configuration = configuration
        }
        #else
        withLock {
            self.isEnabled = false
            self.configuration = configuration
        }
        #endif
    }

    package func updateConfiguration(_ configuration: ConsoleLoggingConfiguration) {
        withLock {
            self.configuration = configuration
        }
    }

    func log(_ logItem: LogItem) {
        #if DEBUG
        let state = snapshot()
        guard state.isEnabled else { return }

        let message = ConsoleLogFormatter(configuration: state.configuration).format(logItem)
        write(message)
        #endif
    }

    fileprivate func log(_ message: String) {
        #if DEBUG
        guard snapshot().isEnabled, !message.isEmpty else { return }
        write("[NetworkSpectator] \(message)")
        #endif
    }

    private func write(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        print(message)
    }

    private func snapshot() -> State {
        withLock {
            State(isEnabled: isEnabled, configuration: configuration)
        }
    }

    private func withLock<T>(_ work: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return work()
    }
}

package extension DebugConsoleLogger {
    static func log(_ logItem: LogItem) {
        shared.log(logItem)
    }

    static func log(_ message: String) {
        shared.log(message)
    }
}

private extension DebugConsoleLogger {
    struct State: Sendable {
        let isEnabled: Bool
        let configuration: ConsoleLoggingConfiguration
    }
}

private struct ConsoleLogFormatter: Sendable {
    private let configuration: ConsoleLoggingConfiguration

    init(configuration: ConsoleLoggingConfiguration) {
        self.configuration = configuration
    }

    func format(_ logItem: LogItem) -> String {
        var sections = [String]()
        sections.reserveCapacity(8)

        sections.append(separator(for: logItem))
        sections.append(line("Method", logItem.method))
        sections.append(line("URL", logItem.url))

        if logItem.isMocked {
            sections.append(line("Mocked", "true"))
        }

        if !logItem.isLoading {
            sections.append(line("Status", formattedStatus(for: logItem)))
            sections.append(line("Duration", formattedDuration(logItem.responseTime)))

            if let mimeType = logItem.mimetype, !mimeType.isEmpty {
                sections.append(line("MIME Type", mimeType))
            }

            if let error = formattedError(for: logItem) {
                sections.append(line("Error", error))
            }
        }

        appendSection(
            title: "Request Headers",
            value: logItem.requestHeadersPrettyPrinted,
            limit: configuration.maximumHeaderLength,
            isIncluded: configuration.includesRequestHeaders,
            to: &sections
        )
        appendSection(
            title: "Request Body",
            value: logItem.requestBody,
            limit: configuration.maximumBodyLength,
            isIncluded: configuration.includesRequestBody,
            to: &sections
        )

        if !logItem.isLoading {
            appendSection(
                title: "Response Headers",
                value: logItem.responseHeadersPrettyPrinted,
                limit: configuration.maximumHeaderLength,
                isIncluded: configuration.includesResponseHeaders,
                to: &sections
            )
            appendSection(
                title: "Response Body",
                value: logItem.responseBody,
                limit: configuration.maximumBodyLength,
                isIncluded: configuration.includesResponseBody,
                to: &sections
            )
        }

        sections.append(separatorEnd)
        return sections.joined(separator: "\n")
    }

    private func appendSection(
        title: String,
        value: String,
        limit: Int,
        isIncluded: Bool,
        to sections: inout [String]
    ) {
        guard isIncluded, !value.isEmpty else { return }
        sections.append("\n[\(title)]")
        sections.append(truncated(value.trimmingCharacters(in: .whitespacesAndNewlines), limit: limit))
    }

    private func separator(for logItem: LogItem) -> String {
        let state = logItem.isLoading ? "REQUEST STARTED" : "REQUEST FINISHED"
        return "==================== NetworkSpectator \(state) ===================="
    }

    private var separatorEnd: String {
        "========================== NetworkSpectator END =========================="
    }

    private func line(_ title: String, _ value: String) -> String {
        "[NetworkSpectator] \(title): \(value)"
    }

    private func formattedStatus(for logItem: LogItem) -> String {
        guard logItem.statusCode > 0 else { return "Unavailable" }
        return "\(logItem.statusCode) (\(logItem.statusCategory))"
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        String(format: "%.0f ms", interval * 1_000)
    }

    private func formattedError(for logItem: LogItem) -> String? {
        let error = logItem.errorLocalizedDescription ?? logItem.errorDescription
        guard let error, !error.isEmpty else { return nil }
        return error
    }

    private func truncated(_ value: String, limit: Int) -> String {
        guard limit > 0 else { return "[omitted]" }
        guard value.count > limit else { return value }

        let endIndex = value.index(value.startIndex, offsetBy: limit)
        let remainingCount = value.distance(from: endIndex, to: value.endIndex)
        return "\(value[..<endIndex])\n... [truncated \(remainingCount) characters]"
    }
}
