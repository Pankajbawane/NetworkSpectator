//
//  LogResponseDetailsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogResponseDetailsView: View {

    @Binding var item: LogItem

    private var isLoading: Bool {
        item.finishTime == nil
    }

    private var hasError: Bool {
        item.errorDescription != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                loadingView()
            } else if hasError {
                errorView()
            } else if item.responseBody.isEmpty {
                emptyStateView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    responseMetadata()
                    responseBodyView()
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func responseBodyView() -> some View {
        ResponseBodyLineView(responseBody: item.responseBody)
            .frame(minHeight: 200)
            .padding(12)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(8)
            .contextMenu {
                Button(action: {
            #if canImport(UIKit)
                    UIPasteboard.general.string = item.responseBody
            #elseif canImport(AppKit)
                    NSPasteboard.general.setString(item.responseBody, forType: .string)
            #endif
                }) {
                    Label("Copy Full Response", systemImage: "doc.on.doc")
                }
            }
    }

    @ViewBuilder
    private func responseMetadata() -> some View {
        HStack(spacing: 12) {
            if item.statusCode != 0 {
                Label("\(item.statusCode)", systemImage: "number.circle.fill")
                    .font(.caption)
                    .foregroundColor(statusCodeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusCodeColor.opacity(0.15))
                    .cornerRadius(8)
            }

            if let mimetype = item.mimetype {
                Label(mimetype, systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray).opacity(0.15))
                    .cornerRadius(8)
            }

            Spacer()

            Text("\(byteCountFormatted)")
                .font(.caption2)
                .foregroundColor(.secondary)
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

    private var byteCountFormatted: String {
        let bytes = item.responseBody.utf8.count
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }

    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            Text("Waiting for response...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private func errorView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.7))
            Text("Request Failed")
                .font(.headline)
                .foregroundColor(.primary)
            if let errorDesc = item.errorDescription {
                Text(errorDesc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Response Body")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("This response doesn't contain a body")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
