//
//  LogMetricsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 02/07/26.
//

import SwiftUI

struct LogMetricsView: View {
    private let viewModel: LogMetricsViewModel
    
    init(item: LogItem) {
        viewModel = LogMetricsViewModel(item: item)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.metrics == nil {
                    emptyState(icon: "timer",
                               title: "No Metrics Available",
                               message: "URLSession has not reported detailed timing metrics for this request.")
                } else {
                    summarySection
                    
                    ForEach(viewModel.transactions) { transaction in
                        transactionSection(transaction)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Summary", icon: "speedometer", color: .blue)

            LazyVGrid(columns: summaryColumns, spacing: 10) {
                ForEach(viewModel.summaryTiles) { tile in
                    summaryTile(tile)
                }
            }
        }
    }

    private func transactionSection(_ transaction: LogMetricsViewModel.Transaction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            transactionHeader(transaction)

            metricGroup(title: "Timeline", icon: "timer", color: .blue) {
                waterfallTimeline(for: transaction.timeline)
            }

            metricGroup(title: "Transfer", icon: "arrow.up.arrow.down", color: .green) {
                metricTable(transaction.transferRows)
            }

            metricGroup(title: "Connection", icon: "network", color: .orange) {
                metricTable(transaction.connectionRows)
            }

            if let tlsRows = transaction.tlsRows {
                metricGroup(title: "TLS", icon: "lock.shield", color: .purple) {
                    metricTable(tlsRows)
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private func transactionHeader(_ transaction: LogMetricsViewModel.Transaction) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Transaction \(transaction.index)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(transaction.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: transaction.icon)
                    .font(.subheadline)
                    .foregroundColor(transaction.color)
                    .frame(width: 18)
                Text(transaction.fetchType)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(transaction.color.opacity(0.15))
            .cornerRadius(8)
        }
    }

    private func metricGroup<Content: View>(title: String,
                                            icon: String,
                                            color: Color,
                                            @ViewBuilder rows: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: title, icon: icon, color: color)
            rows()
        }
    }

    private func waterfallTimeline(for timeline: LogMetricsViewModel.Timeline) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if timeline.phases.isEmpty || timeline.total <= 0 {
                timingUnavailableView
            } else {
                VStack(spacing: 10) {
                    ForEach(timeline.phases) { phase in
                        timelinePhaseRow(phase, total: timeline.total)
                    }
                }
            }

            HStack {
                Text("Transaction total")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Text(timeline.formattedTotal)
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
            }
        }
        .padding(10)
        .metricTableStyle()
    }

    private var timingUnavailableView: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundColor(.secondary.opacity(0.5))
            Text("Timing phases unavailable")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }

    private func timelinePhaseRow(_ phase: LogMetricsViewModel.TimelinePhase, total: TimeInterval) -> some View {
        HStack(spacing: 8) {
            Text(phase.title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 64, alignment: .leading)

            Text(phase.formattedDuration)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 58, alignment: .trailing)
                .textSelection(.enabled)

            GeometryReader { geometry in
                let width = geometry.size.width
                let barWidth = max(3, width * phase.duration / total)
                let offset = min(max(0, width * phase.offset / total), max(0, width - barWidth))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.08))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(phase.color)
                        .frame(width: barWidth, height: 8)
                        .offset(x: offset)
                        .accessibilityLabel("\(phase.title), starts at \(phase.formattedOffset), lasts \(phase.formattedDuration)")
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 14)
        }
    }

    private func metricTable(_ rows: [LogMetricsViewModel.MetricRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                metricRow(row)

                if index < rows.count - 1 {
                    divider()
                }
            }
        }
        .metricTableStyle()
    }

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }

    private func summaryTile(_ tile: LogMetricsViewModel.SummaryTile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: tile.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(tile.title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(tile.value)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(Color.secondary.opacity(0.12))
        .cornerRadius(8)
    }

    private func metricRow(_ row: LogMetricsViewModel.MetricRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(row.title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(row.isProminent ? .semibold : .regular)
                .foregroundColor(row.isProminent ? .primary : .secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func divider() -> some View {
        Divider()
            .padding(.leading, 10)
    }

    private var summaryColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 130), spacing: 10)]
    }
}

private extension View {
    func metricTableStyle() -> some View {
        background(Color.secondary.opacity(0.08))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
            )
    }
}
