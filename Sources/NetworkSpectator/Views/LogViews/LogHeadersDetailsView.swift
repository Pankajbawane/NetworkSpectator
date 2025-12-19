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
        VStack(alignment: .leading, spacing: 20) {
            headerSection(
                title: "Request Headers",
                icon: "arrow.up.doc",
                headers: item.headers,
                accentColor: .blue
            )
            headerSection(
                title: "Response Headers",
                icon: "arrow.down.doc",
                headers: item.responseHeaders,
                accentColor: .green
            )
            Spacer()
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func headerSection(title: String, icon: String, headers: String?, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if let headers = headers, !headers.isEmpty {
                    Text("\(headerCount(headers)) headers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            if let headers = headers, !headers.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text(headers)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
                .contextMenu {
                    Button(action: {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = headers
                        #elseif canImport(AppKit)
                        NSPasteboard.general.setString(headers, forType: .string)
                        #endif
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
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

    private func headerCount(_ headers: String) -> Int {
        headers.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
}
