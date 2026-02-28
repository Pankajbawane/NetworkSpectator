//
//  LogHeadersDetailsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogHeadersDetailsView: View {
    @Binding var item: LogItem

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 20) {
                headerSection(
                    title: "Request Headers",
                    icon: "arrow.up.doc",
                    headers: item.headers,
                    headersInString: item.requestHeadersPrettyPrinted,
                    accentColor: .blue
                )
                headerSection(
                    title: "Response Headers",
                    icon: "arrow.down.doc",
                    headers: item.responseHeaders,
                    headersInString: item.responseHeadersPrettyPrinted,
                    accentColor: .green
                )
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func headerSection(title: String,
                               icon: String,
                               headers: [String: String],
                               headersInString: String,
                               accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if !headers.isEmpty {
                    Text("\(headers.count) headers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                    
                    copyable(value: headersInString)
                }
            }

            if !headers.isEmpty {
                headersTable(headers: headers)
                    .contextMenu {
                        Button(action: {
                            let text = headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                            #if canImport(UIKit)
                            UIPasteboard.general.string = text
                            #elseif canImport(AppKit)
                            NSPasteboard.general.setString(text, forType: .string)
                            #endif
                        }) {
                            Label("Copy All", systemImage: "doc.on.doc")
                        }
                    }
            } else {
                HStack {
                    Image(systemName: "tray")
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No headers available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private func headersTable(headers: [String: String]) -> some View {
        let sortedHeaders = headers.sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }

        VStack(spacing: 0) {
            tableHeaderRow
            Divider()
            ForEach(Array(sortedHeaders.enumerated()), id: \.offset) { index, header in
                headerRow(key: header.key, value: header.value, isAlternate: index % 2 != 0)
                if index < sortedHeaders.count - 1 {
                    Divider()
                }
            }
        }
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private var tableHeaderRow: some View {
        HStack(spacing: 0) {
            Text("Key")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            Divider()

            Text("Value")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .background(Color.secondary.opacity(0.15))
    }

    @ViewBuilder
    private func headerRow(key: String, value: String, isAlternate: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .textSelection(.enabled)

            Divider()

            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .textSelection(.enabled)
        }
        .background(isAlternate ? Color.secondary.opacity(0.05) : Color.clear)
    }
}
