//
//  LogMetricsViewModel.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 04/07/26.
//

import Foundation
import SwiftUI

struct LogMetricsViewModel {
    private static let unavailableValue = "Unavailable"
    
    let metrics: NetworkLogMetrics?
    let summaryTiles: [SummaryTile]
    let transactions: [Transaction]

    init(item: LogItem) {
        metrics = item.metrics
        summaryTiles = Self.makeSummaryTiles(for: item)
        transactions = Self.makeTransactionsLatestFirst(from: item.metrics?.transactions ?? [])
    }

    private static func makeSummaryTiles(for item: LogItem) -> [SummaryTile] {
        let metrics = item.metrics
        let transactions = metrics?.transactions ?? []
        let requestBytes = transactions.compactMap(\.countOfRequestBodyBytesSent).reduce(0, +)
        let responseBytes = transactions.compactMap(\.countOfResponseBodyBytesReceived).reduce(0, +)
        
        let redirectionsValue = metrics.map { "\($0.redirectCount)" } ?? unavailableValue
        let sentValue = metrics == nil ? unavailableValue : formatBytes(requestBytes)
        let receivedValue = metrics == nil ? unavailableValue : formatBytes(responseBytes)
        let transactionsValue = metrics == nil ? unavailableValue : "\(transactions.count)"

        return [
            SummaryTile(title: "Redirections", value: redirectionsValue, icon: "arrow.triangle.branch"),
            SummaryTile(title: "Total time", value: formatDuration(item.responseTime), icon: "timer"),
            SummaryTile(title: "Sent", value: sentValue, icon: "arrow.up"),
            SummaryTile(title: "Received", value: receivedValue, icon: "arrow.down"),
            SummaryTile(title: "Transactions", value: transactionsValue, icon: "arrow.trianglehead.swap")
        ]
    }

    private static func makeTransactionsLatestFirst(from transactions: [NetworkTransaction]) -> [Transaction] {
        transactions.reversed().enumerated().map { offset, transaction in
            Transaction(index: transactions.count - offset,
                        metric: transaction,
                        timeline: makeTimeline(for: transaction),
                        transferRows: makeTransferRows(for: transaction),
                        connectionRows: makeConnectionRows(for: transaction),
                        tlsRows: makeTLSRows(for: transaction))
        }
    }


    private static func makeTimeline(for metric: NetworkTransaction) -> Timeline {
        let phases = makeTimelinePhases(for: metric)
        let total = timelineTotal(for: metric, phases: phases)
        return Timeline(phases: phases, total: total, formattedTotal: formatDuration(total))
    }

    private static func makeTimelinePhases(for metric: NetworkTransaction) -> [TimelinePhase] {
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

    private static func timelineTotal(for metric: NetworkTransaction, phases: [TimelinePhase]) -> TimeInterval {
        if let fetchStartDate = metric.fetchStartDate,
           let responseEndDate = metric.responseEndDate {
            return max(responseEndDate.timeIntervalSince(fetchStartDate), 0)
        }
        return phases.map { $0.offset + $0.duration }.max() ?? 0
    }

    private static func makeTransferRows(for metric: NetworkTransaction) -> [MetricRow] {
        [
            MetricRow(title: "Request headers sent", value: formatBytes(metric.countOfRequestHeaderBytesSent)),
            MetricRow(title: "Request body sent", value: formatBytes(metric.countOfRequestBodyBytesSent)),
            MetricRow(title: "Request body before encoding", value: formatBytes(metric.countOfRequestBodyBytesBeforeEncoding)),
            MetricRow(title: "Response headers received", value: formatBytes(metric.countOfResponseHeaderBytesReceived)),
            MetricRow(title: "Response body received", value: formatBytes(metric.countOfResponseBodyBytesReceived)),
            MetricRow(title: "Response body after decoding", value: formatBytes(metric.countOfResponseBodyBytesAfterDecoding))
        ]
    }

    private static func makeConnectionRows(for metric: NetworkTransaction) -> [MetricRow] {
        [
            MetricRow(title: "Protocol", value: metric.networkProtocolName ?? unavailableValue),
            MetricRow(title: "Remote address", value: endpoint(address: metric.remoteAddress, port: metric.remotePort)),
            MetricRow(title: "Local address", value: endpoint(address: metric.localAddress, port: metric.localPort)),
            MetricRow(title: "DNS protocol", value: metric.domainResolutionProtocol?.formatted ?? unavailableValue),
            MetricRow(title: "Reused connection", value: formatBool(metric.isReusedConnection)),
            MetricRow(title: "Proxy connection", value: formatBool(metric.isProxyConnection)),
            MetricRow(title: "Cellular", value: formatBool(metric.isCellular)),
            MetricRow(title: "Expensive", value: formatBool(metric.isExpensive)),
            MetricRow(title: "Constrained", value: formatBool(metric.isConstrained)),
            MetricRow(title: "Multipath", value: formatBool(metric.isMultipath))
        ]
    }

    private static func makeTLSRows(for metric: NetworkTransaction) -> [MetricRow]? {
        guard metric.secureConnectionStartDate != nil ||
              metric.negotiatedTLSProtocolVersion != nil ||
              metric.negotiatedTLSCipherSuite != nil else {
            return nil
        }

        return [
            MetricRow(title: "TLS version", value: metric.negotiatedTLSProtocolVersion?.formatted ?? unavailableValue),
            MetricRow(title: "Cipher suite", value: formatTLSCipherSuite(metric.negotiatedTLSCipherSuite))
        ]
    }

    private static func endpoint(address: String?, port: Int?) -> String {
        guard let address, !address.isEmpty else { return unavailableValue }
        guard let port else { return address }
        return "\(address):\(port)"
    }

    private static func formatDuration(_ interval: TimeInterval?) -> String {
        guard let interval else { return unavailableValue }
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
        guard let bytes else { return unavailableValue }
        return formatBytes(bytes)
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    private static func formatBool(_ value: Bool?) -> String {
        guard let value else { return unavailableValue }
        return value ? "Yes" : "No"
    }

    private static func formatTLSCipherSuite(_ value: TLSCipherSuite?) -> String {
        guard let value else { return unavailableValue }
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
             metric: NetworkTransaction,
             timeline: Timeline,
             transferRows: [MetricRow],
             connectionRows: [MetricRow],
             tlsRows: [MetricRow]?) {
            id = index
            self.index = index
            subtitle = Self.subtitle(for: metric)
            if let resourceFetchType = metric.resourceFetchType {
                fetchType = resourceFetchType.formatted
            } else {
                fetchType = LogMetricsViewModel.unavailableValue
            }
            icon = metric.resourceFetchType?.icon ?? ResourceFetchType.unknown.icon
            color = Self.color(for: metric.resourceFetchType)
            self.timeline = timeline
            self.transferRows = transferRows
            self.connectionRows = connectionRows
            self.tlsRows = tlsRows
        }

        private static func subtitle(for metric: NetworkTransaction) -> String {
            let protocolName = metric.networkProtocolName ?? "unknown protocol"
            let endpoint = LogMetricsViewModel.endpoint(address: metric.remoteAddress, port: metric.remotePort)
            return endpoint == LogMetricsViewModel.unavailableValue ? protocolName : "\(protocolName) • \(endpoint)"
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
