//
//  LogBasicDetailsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI
import NetworkSpectatorCore

struct LogBasicDetailsView: View {
    private let viewModel: LogBasicDetailsViewModel

    init(item: LogItem) {
        viewModel = LogBasicDetailsViewModel(item: item)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.isLoading {
                    loadingView()
                } else {
                    ForEach(viewModel.details) { row in
                        rowItem(row)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func rowItem(_ row: LogBasicDetailsViewModel.DetailRow) -> some View {
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
                .font(.system(.body, design: .monospaced))
                .foregroundColor(valueColor(for: row))
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
            Text("Waiting for response from server...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func valueColor(for row: LogBasicDetailsViewModel.DetailRow) -> Color {
        switch row.role {
        case .standard:
            return .primary
        case .error:
            return .red
        }
    }
}
