//
//  LogRequestDetailsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogRequestDetailsView: View {

    let item: LogItem
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 12) {
                if item.requestBody.isEmpty {
                    emptyState(icon: "doc.text",
                               title: "No Request Body",
                               message: "This request doesn't contain a body")
                } else {
                    requestMetadata()
                    
                    requestBodyView()
                        .textSelection(.enabled)
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
                }
            }.padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func requestMetadata() -> some View {
        HStack(spacing: 12) {
            Label("json", systemImage: "doc.text")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray).opacity(0.15))
                .cornerRadius(8)
            
            Spacer()
            
            Text("\(byteCountFormatted)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            copyable(value: item.requestBody)
        }
    }
    
    private func requestBodyView() -> some View {
        let background: Color = colorScheme == .dark ? Color.black.opacity(0.4) : .secondary.opacity(0.2)
        return JSONBodyLineView(responseBody: item.requestBody, mimetype: "application/json")
            .frame(minHeight: 200)
            .padding(12)
            .background(background)
            .cornerRadius(8)
    }
    
    private var byteCountFormatted: String {
        let bytes: Int = item.requestBodyRaw?.count ?? 0
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
