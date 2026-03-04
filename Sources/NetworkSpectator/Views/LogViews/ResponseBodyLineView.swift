//
//  ResponseBodyLineView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 20/02/26.
//

import SwiftUI

struct ResponseBodyLineView: View {
    let responseBody: String

    @State private var lines: [String] = []
    @State private var isProcessing = true
    @State private var isJSON = false

    var body: some View {
        Group {
            if isProcessing {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(Array(lines.enumerated()), id: \.offset) { index, line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
            }
        }
        .task {
            await processContent()
        }
    }

    private func processContent() async {
        // Process on background thread to avoid blocking UI
        let processedLines = await Task(priority: .userInitiated) {
            return (true, responseBody.components(separatedBy: .newlines))
        }.value

        isJSON = processedLines.0
        lines = processedLines.1
        isProcessing = false
    }
}
