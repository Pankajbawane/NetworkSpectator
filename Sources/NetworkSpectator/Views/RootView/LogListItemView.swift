//
//  LogListItemView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogListItemView: View {

    let item: LogItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // HTTP Method Badge
            HTTPMethodBadge(method: item.method)

            VStack(alignment: .leading, spacing: 6) {
                // URL with host highlighted
                HStack(spacing: 4) {
                    Text(item.host)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    if !item.path.isEmpty && item.path != "/" {
                        Text(item.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Status Code Badge
                    if !item.isLoading {
                        StatusCodeBadge(statusCode: item.statusCode)
                    }
                }

                // Timing and metadata
                HStack(spacing: 5) {
                    Label {
                        Text(item.startTime.formatted(date: .omitted, time: .standard))
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    if !item.isLoading {
                        Label {
                            Text("\(item.responseTime, specifier: "%.2f")s")
                        } icon: {
                            Image(systemName: "timer")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }

                    // Show request/response size if available
                    if !item.requestBody.isEmpty {
                        Label {
                            Text(formatBytes(item.requestBody.count))
                        } icon: {
                            Image(systemName: "arrow.up.circle.fill")
                        }
                        .font(.caption2)
                    }

                    if !item.responseBody.isEmpty && !item.isLoading {
                        Label {
                            Text(formatBytes(item.responseBody.count))
                        } icon: {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        .font(.caption2)
                    }

                    Spacer()
                }

                // Error display
                if let error = item.errorLocalizedDescription {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(error)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.red)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            // Loading indicator
            if item.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Helper Methods

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var accessibilityLabel: String {
        var label = "\(item.method) request to \(item.host)"
        if !item.isLoading {
            label += ", status \(item.statusCode)"
            label += ", response time \(item.responseTime) seconds"
        } else {
            label += ", loading"
        }
        if let error = item.errorLocalizedDescription {
            label += ", error: \(error)"
        }
        return label
    }
}

// MARK: - HTTP Method Badge

struct HTTPMethodBadge: View {
    let method: String

    var body: some View {
        Text(method.isEmpty ? "?" : method)
            .font(Font.system(size: 8, weight: .semibold, design: .default))
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(methodColor)
            .cornerRadius(4)
            .frame(minWidth: 44)
    }

    private var methodColor: Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .indigo
        case "PUT": return .orange
        case "PATCH": return .purple
        case "DELETE": return .red
        case "HEAD": return .gray
        case "OPTIONS": return .brown
        default: return .secondary
        }
    }
}

// MARK: - Status Code Badge

struct StatusCodeBadge: View {
    let statusCode: Int

    var body: some View {
        if statusCode > 0 {
            Text("\(statusCode)")
                .font(Font.system(size: 8, weight: .semibold, design: .default))
                .fontWeight(.semibold)
                .foregroundStyle(statusTextColor)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(statusBackgroundColor)
                .cornerRadius(4)
        }
    }

    private var statusTextColor: Color {
        switch statusCode {
        case 200..<300: return .white
        case 300..<400: return .primary
        case 400..<500: return .white
        case 500..<600: return .white
        default: return .primary
        }
    }

    private var statusBackgroundColor: Color {
        switch statusCode {
        case 200..<300: return .green
        case 300..<400: return .yellow.opacity(0.3)
        case 400..<500: return .orange
        case 500..<600: return .red
        default: return .gray.opacity(0.2)
        }
    }
}
