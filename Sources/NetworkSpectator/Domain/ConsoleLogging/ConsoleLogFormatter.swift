//
//  ConsoleLogFormatter.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 07/07/26.
//

import Foundation

struct ConsoleLogFormatter: Sendable {
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
