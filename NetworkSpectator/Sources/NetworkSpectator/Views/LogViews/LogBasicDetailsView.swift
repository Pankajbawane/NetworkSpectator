//
//  Basic.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogBasicDetailsView: View {
    @Binding var item: LogItem

    // Represent a detail key/value pair
    struct DetailRow: Identifiable {
        var id: String { title }
        let title: String
        let value: String
    }

    // Gather displayable details
    private var details: [DetailRow] {
        var rows: [DetailRow] = [
            .init(title: "HTTP Method", value: item.method.uppercased()),
            .init(title: "URL", value: item.url),
            .init(title: "Start time", value: item.startTime.formatted(date: .numeric, time: .standard))
        ]
        if let finishTime = item.finishTime {
            rows.append(.init(title: "End time", value: finishTime.formatted(date: .numeric, time: .standard)))
            rows.append(.init(title: "Response time", value: String(format: "%.4fs", item.responseTime)))

            if let mimetype = item.mimetype {
                rows.append(.init(title: "Mime type", value: mimetype))
            }
            if let textEncoding = item.textEncodingName {
                rows.append(.init(title: "Text encoding", value: textEncoding))
            }
            if item.statusCode != 0 {
                rows.append(.init(title: "Status code", value: "\(item.statusCode)"))
            }
            if let errorDesc = item.errorDescription {
                rows.append(.init(title: "Error occurred", value: errorDesc))
            }
        }
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if item.finishTime == nil {
                loadingView()
            } else {
                ForEach(details) { row in
                    rowItem(row.title, row.value)
                }
            }
        }
        .padding(.horizontal)
    }

    private func rowItem(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(title + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .textSelection(.enabled)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
    }

    @ViewBuilder
    private func loadingView() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .padding(.trailing, 8)
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
