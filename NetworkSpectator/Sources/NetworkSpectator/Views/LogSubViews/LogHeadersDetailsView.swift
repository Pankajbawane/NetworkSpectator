//
//  HeadersDetailsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogHeadersDetailsView: View {
    @Binding var item: LogItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection(title: "Request Headers", headers: item.headers)
            headerSection(title: "Response Headers", headers: item.responseHeaders)
            Spacer()
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func headerSection(title: String, headers: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(6)
            .background(Color(.systemGray5))
            .cornerRadius(6)

            if let headers = headers, !headers.isEmpty {
                ScrollView(.horizontal) {
                    Text(headers)
                        .font(.caption)
                        .textSelection(.enabled)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                        .contextMenu {
                            Button("Copy", action: {
                                UIPasteboard.general.string = headers
                            })
                        }
                }
            } else {
                Text("No headers")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 4)
            }
        }
    }
}
