//
//  LogBasicDetailsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogBasicDetailsView: View {
    @Binding var item: LogItem

    struct DetailRow: Identifiable {
        var id: String { title }
        let title: String
        let value: String
        let icon: String?
        let valueColor: Color?

        init(title: String, value: String, icon: String? = nil, valueColor: Color? = nil) {
            self.title = title
            self.value = value
            self.icon = icon
            self.valueColor = valueColor
        }
    }

    private var details: [DetailRow] {
        var rows: [DetailRow] = [
            .init(title: "HTTP Method", value: item.method.uppercased(), icon: "arrow.left.arrow.right"),
            .init(title: "URL", value: item.url, icon: "link"),
            .init(title: "Start time", value: item.startTime.formatted(date: .numeric, time: .standard), icon: "clock")
        ]
        if let finishTime = item.finishTime {
            rows.append(.init(title: "End time", value: finishTime.formatted(date: .numeric, time: .standard), icon: "clock.fill"))
            rows.append(.init(title: "Response time", value: String(format: "%.4fs", item.responseTime), icon: "timer"))
            if let mimetype = item.mimetype {
                rows.append(.init(title: "Mime type", value: mimetype, icon: "doc.text"))
            }
            if let textEncoding = item.textEncodingName {
                rows.append(.init(title: "Text encoding", value: textEncoding, icon: "textformat"))
            }
            if item.statusCode != 0 {
                rows.append(.init(title: "Status code", value: "\(item.statusCode)", icon: "number"))
            }
            if let errorDesc = item.errorDescription {
                rows.append(.init(title: "Error occurred", value: errorDesc, icon: "exclamationmark.triangle.fill", valueColor: .red))
            }
        }
        return rows
    }

    private var methodColor: Color {
        switch item.method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .primary
        }
    }

    private var statusCodeColor: Color {
        let code = item.statusCode
        switch code {
        case 200..<300: return .green
        case 300..<400: return .orange
        case 400..<500: return .red
        case 500..<600: return .purple
        default: return .primary
        }
    }

    private var responseTimeColor: Color {
        let time = item.responseTime
        if time < 2.0 { return .primary }
        else if time < 4.0 { return .orange }
        else { return .red }
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 12) {
                if item.finishTime == nil {
                    loadingView()
                } else {
                    ForEach(details) { row in
                        rowItem(row)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func rowItem(_ row: DetailRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon = row.icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 14)
                }
                Text(row.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                copyable(value: row.value, size: .caption)
            }

            Text(row.value)
                .textSelection(.enabled)
                .font(.system(.body, design: row.title == "URL" ? .monospaced : .default))
                .foregroundColor(row.valueColor ?? .primary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            Text("Loading request details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
