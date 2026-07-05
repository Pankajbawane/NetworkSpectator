//
//  LogBasicDetailsViewModel.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 04/07/26.
//

import Foundation
import NetworkSpectatorCore

struct LogBasicDetailsViewModel {
    let isLoading: Bool
    let details: [DetailRow]

    init(item: LogItem) {
        isLoading = item.finishTime == nil
        details = Self.makeDetails(for: item)
    }

    private static func makeDetails(for item: LogItem) -> [DetailRow] {
        var rows: [DetailRow] = [
            DetailRow(title: "HTTP Method", value: item.method.uppercased(), icon: "arrow.left.arrow.right"),
            DetailRow(title: "URL", value: item.url, icon: "link"),
            DetailRow(title: "Start time", value: formatDate(item.startTime), icon: "clock")
        ]

        guard let finishTime = item.finishTime else {
            return rows
        }

        rows.append(DetailRow(title: "End time", value: formatDate(finishTime), icon: "clock.fill"))
        rows.append(DetailRow(title: "Response time", value: formatResponseTime(item.responseTime), icon: "timer"))

        if let mimetype = item.mimetype {
            rows.append(DetailRow(title: "Mime type", value: mimetype, icon: "doc.text"))
        }

        if let textEncoding = item.textEncodingName {
            rows.append(DetailRow(title: "Text encoding", value: textEncoding, icon: "textformat"))
        }

        if item.statusCode != 0 {
            rows.append(DetailRow(title: "Status code", value: "\(item.statusCode)", icon: "number"))
        }

        if let errorDescription = item.errorLocalizedDescription {
            rows.append(DetailRow(title: "Error occurred",
                                  value: errorDescription,
                                  icon: "exclamationmark.triangle.fill",
                                  role: .error))
        }

        return rows
    }

    private static func formatDate(_ date: Date) -> String {
        date.formatted(date: .numeric, time: .standard)
    }

    private static func formatResponseTime(_ responseTime: TimeInterval) -> String {
        String(format: "%.4fs", responseTime)
    }

    struct DetailRow: Identifiable {
        enum Role {
            case standard
            case error
        }

        var id: String { title }
        let title: String
        let value: String
        let icon: String?
        let role: Role

        init(title: String, value: String, icon: String? = nil, role: Role = .standard) {
            self.title = title
            self.value = value
            self.icon = icon
            self.role = role
        }
    }
}
