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
