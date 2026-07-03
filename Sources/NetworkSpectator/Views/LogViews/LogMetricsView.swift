//
//  LogMetricsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 02/07/26.
//

import SwiftUI

struct LogMetricsView: View {
    let item: LogItem
    private let viewModel: LogMetricsViewModel
    
    init(item: LogItem) {
        self.item = item
        viewModel = LogMetricsViewModel(item: item)
    }

    var body: some View {
        ScrollView(.vertical) {
            if viewModel.metrics.isEmpty {
                emptyState(icon: "timer",
                           title: "No Metrics Available",
                           message: "URLSession has not reported timing metrics for this request yet.")
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    summarySection

                    ForEach(viewModel.transactions) { transaction in
                        transactionSection(transaction)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
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
            Image(systemName: transaction.icon)
                .font(.subheadline)
                .foregroundColor(transaction.color)
                .frame(width: 18)

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

            Text(transaction.fetchType)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(transaction.color)
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
            ForEach(rows) { row in
                metricRow(row)

                if row.id != rows.last?.id {
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

private struct LogMetricsViewModel {
    let metrics: [NetworkLogMetrics]
    let summaryTiles: [SummaryTile]
    let transactions: [Transaction]

    init(item: LogItem) {
        metrics = item.metrics
        summaryTiles = Self.makeSummaryTiles(for: item)
        transactions = Self.makeTransactions(from: item.metrics)
    }

    private static func makeSummaryTiles(for item: LogItem) -> [SummaryTile] {
        let metrics = item.metrics
        let totalDuration = Self.totalDuration(for: item)
        let requestBytes = metrics.compactMap(\.countOfRequestBodyBytesSent).reduce(0, +)
        let responseBytes = metrics.compactMap(\.countOfResponseBodyBytesReceived).reduce(0, +)

        return [
            SummaryTile(title: "Transactions", value: "\(metrics.count)", icon: "arrow.triangle.branch"),
            SummaryTile(title: "Total time", value: formatDuration(totalDuration), icon: "timer"),
            SummaryTile(title: "Sent", value: formatBytes(requestBytes), icon: "arrow.up"),
            SummaryTile(title: "Received", value: formatBytes(responseBytes), icon: "arrow.down")
        ]
    }

    private static func makeTransactions(from metrics: [NetworkLogMetrics]) -> [Transaction] {
        metrics.reversed().enumerated().map { offset, metric in
            Transaction(index: metrics.count - offset,
                        metric: metric,
                        timeline: makeTimeline(for: metric),
                        transferRows: makeTransferRows(for: metric),
                        connectionRows: makeConnectionRows(for: metric),
                        tlsRows: makeTLSRows(for: metric))
        }
    }

    private static func totalDuration(for item: LogItem) -> TimeInterval? {
        let metrics = item.metrics
        guard let start = metrics.compactMap(\.fetchStartDate).min(),
              let end = metrics.compactMap(\.responseEndDate).max() else {
            return item.finishTime.map { $0.timeIntervalSince(item.startTime) }
        }
        return end.timeIntervalSince(start)
    }

    private static func makeTimeline(for metric: NetworkLogMetrics) -> Timeline {
        let phases = makeTimelinePhases(for: metric)
        let total = timelineTotal(for: metric, phases: phases)
        return Timeline(phases: phases, total: total, formattedTotal: formatDuration(total))
    }

    private static func makeTimelinePhases(for metric: NetworkLogMetrics) -> [TimelinePhase] {
        var phases = [TimelinePhase]()
        let baseDate = metric.fetchStartDate

        appendPhase("DNS", color: .teal, start: metric.domainLookupStartDate, end: metric.domainLookupEndDate, baseDate: baseDate, to: &phases)
        appendPhase("TCP", color: .blue, start: metric.connectStartDate, end: metric.secureConnectionStartDate ?? metric.connectEndDate, baseDate: baseDate, to: &phases)
        appendPhase("TLS", color: .purple, start: metric.secureConnectionStartDate, end: metric.secureConnectionEndDate, baseDate: baseDate, to: &phases)
        appendPhase("Request", color: .orange, start: metric.requestStartDate, end: metric.requestEndDate, baseDate: baseDate, to: &phases)
        appendPhase("Waiting", color: .pink, start: metric.requestEndDate, end: metric.responseStartDate, baseDate: baseDate, to: &phases)
        appendPhase("Download", color: .green, start: metric.responseStartDate, end: metric.responseEndDate, baseDate: baseDate, to: &phases)

        return phases
    }

    private static func appendPhase(_ title: String,
                                    color: Color,
                                    start: Date?,
                                    end: Date?,
                                    baseDate: Date?,
                                    to phases: inout [TimelinePhase]) {
        guard let start, let end else { return }
        let duration = end.timeIntervalSince(start)
        guard duration > 0 else { return }

        let fallbackOffset = phases.reduce(0) { $0 + $1.duration }
        let offset = baseDate.map { max(0, start.timeIntervalSince($0)) } ?? fallbackOffset
        phases.append(TimelinePhase(title: title,
                                    offset: offset,
                                    duration: duration,
                                    formattedOffset: formatDuration(offset),
                                    formattedDuration: formatDuration(duration),
                                    color: color))
    }

    private static func timelineTotal(for metric: NetworkLogMetrics, phases: [TimelinePhase]) -> TimeInterval {
        if let fetchStartDate = metric.fetchStartDate,
           let responseEndDate = metric.responseEndDate {
            return max(responseEndDate.timeIntervalSince(fetchStartDate), 0)
        }
        return phases.map { $0.offset + $0.duration }.max() ?? 0
    }

    private static func makeTransferRows(for metric: NetworkLogMetrics) -> [MetricRow] {
        [
            MetricRow(title: "Request headers sent", value: formatBytes(metric.countOfRequestHeaderBytesSent)),
            MetricRow(title: "Request body sent", value: formatBytes(metric.countOfRequestBodyBytesSent)),
            MetricRow(title: "Request body before encoding", value: formatBytes(metric.countOfRequestBodyBytesBeforeEncoding)),
            MetricRow(title: "Response headers received", value: formatBytes(metric.countOfResponseHeaderBytesReceived)),
            MetricRow(title: "Response body received", value: formatBytes(metric.countOfResponseBodyBytesReceived)),
            MetricRow(title: "Response body after decoding", value: formatBytes(metric.countOfResponseBodyBytesAfterDecoding))
        ]
    }

    private static func makeConnectionRows(for metric: NetworkLogMetrics) -> [MetricRow] {
        [
            MetricRow(title: "Protocol", value: metric.networkProtocolName ?? "Unavailable"),
            MetricRow(title: "Remote address", value: endpoint(address: metric.remoteAddress, port: metric.remotePort)),
            MetricRow(title: "Local address", value: endpoint(address: metric.localAddress, port: metric.localPort)),
            MetricRow(title: "DNS protocol", value: metric.domainResolutionProtocol?.formatted ?? "Unavailable"),
            MetricRow(title: "Reused connection", value: formatBool(metric.isReusedConnection)),
            MetricRow(title: "Proxy connection", value: formatBool(metric.isProxyConnection)),
            MetricRow(title: "Cellular", value: formatBool(metric.isCellular)),
            MetricRow(title: "Expensive", value: formatBool(metric.isExpensive)),
            MetricRow(title: "Constrained", value: formatBool(metric.isConstrained)),
            MetricRow(title: "Multipath", value: formatBool(metric.isMultipath))
        ]
    }

    private static func makeTLSRows(for metric: NetworkLogMetrics) -> [MetricRow]? {
        guard metric.secureConnectionStartDate != nil ||
              metric.negotiatedTLSProtocolVersion != nil ||
              metric.negotiatedTLSCipherSuite != nil else {
            return nil
        }

        return [
            MetricRow(title: "TLS version", value: metric.negotiatedTLSProtocolVersion?.formatted ?? "Unavailable"),
            MetricRow(title: "Cipher suite", value: formatTLSCipherSuite(metric.negotiatedTLSCipherSuite))
        ]
    }

    private static func endpoint(address: String?, port: Int?) -> String {
        guard let address, !address.isEmpty else { return "Unavailable" }
        guard let port else { return address }
        return "\(address):\(port)"
    }

    private static func formatDuration(_ interval: TimeInterval?) -> String {
        guard let interval else { return "Unavailable" }
        let milliseconds = interval * 1_000
        if milliseconds < 1 {
            return String(format: "%.2f ms", milliseconds)
        } else if milliseconds < 1_000 {
            return String(format: "%.1f ms", milliseconds)
        } else {
            return String(format: "%.3f s", interval)
        }
    }

    private static func formatBytes(_ bytes: Int64?) -> String {
        guard let bytes else { return "Unavailable" }
        return formatBytes(bytes)
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    private static func formatBool(_ value: Bool?) -> String {
        guard let value else { return "Unavailable" }
        return value ? "Yes" : "No"
    }

    private static func formatTLSCipherSuite(_ value: TLSCipherSuite?) -> String {
        guard let value else { return "Unavailable" }
        return String(describing: value)
            .replacingOccurrences(of: "_", with: " ")
    }

    struct SummaryTile: Identifiable {
        var id: String { title }
        let title: String
        let value: String
        let icon: String
    }

    struct Transaction: Identifiable {
        let id: Int
        let index: Int
        let subtitle: String
        let fetchType: String
        let icon: String
        let color: Color
        let timeline: Timeline
        let transferRows: [MetricRow]
        let connectionRows: [MetricRow]
        let tlsRows: [MetricRow]?

        init(index: Int,
             metric: NetworkLogMetrics,
             timeline: Timeline,
             transferRows: [MetricRow],
             connectionRows: [MetricRow],
             tlsRows: [MetricRow]?) {
            id = index
            self.index = index
            subtitle = Self.subtitle(for: metric)
            fetchType = metric.resourceFetchType?.formatted ?? "Unavailable"
            icon = metric.resourceFetchType?.icon ?? ResourceFetchType.unknown.icon
            color = Self.color(for: metric.resourceFetchType)
            self.timeline = timeline
            self.transferRows = transferRows
            self.connectionRows = connectionRows
            self.tlsRows = tlsRows
        }

        private static func subtitle(for metric: NetworkLogMetrics) -> String {
            let protocolName = metric.networkProtocolName ?? "unknown protocol"
            let endpoint = LogMetricsViewModel.endpoint(address: metric.remoteAddress, port: metric.remotePort)
            return endpoint == "Unavailable" ? protocolName : "\(protocolName) • \(endpoint)"
        }

        private static func color(for type: ResourceFetchType?) -> Color {
            switch type {
            case .networkLoad: return .blue
            case .serverPush: return .purple
            case .localCache: return .green
            case .unknown, nil: return .secondary
            }
        }
    }

    struct Timeline {
        let phases: [TimelinePhase]
        let total: TimeInterval
        let formattedTotal: String
    }

    struct TimelinePhase: Identifiable {
        var id: String { title }
        let title: String
        let offset: TimeInterval
        let duration: TimeInterval
        let formattedOffset: String
        let formattedDuration: String
        let color: Color
    }

    struct MetricRow: Identifiable {
        var id: String { title }
        let title: String
        let value: String
        let isProminent: Bool

        init(title: String, value: String, isProminent: Bool = false) {
            self.title = title
            self.value = value
            self.isProminent = isProminent
        }
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
