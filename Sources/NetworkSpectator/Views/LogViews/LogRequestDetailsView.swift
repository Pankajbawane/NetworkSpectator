//
//  LogRequestDetailsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogRequestDetailsView: View {

    @Binding var item: LogItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if item.requestBody.isEmpty {
                emptyStateView()
            } else {
                ScrollView(.vertical) {
                    Text(item.requestBody)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                        .contextMenu {
                            Button(action: {
                                #if canImport(UIKit)
                                UIPasteboard.general.string = item.requestBody
                                #elseif canImport(AppKit)
                                NSPasteboard.general.setString(item.requestBody, forType: .string)
                                #endif
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                        .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Request Body")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("This request doesn't contain a body")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
