//
//  AnalyticsDashboardView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 07/12/25.
//

import SwiftUI
import Charts

// MARK: - Insights View
struct AnalyticsDashboardView: View {
    let items: [LogItem]

    private enum Tab: String, CaseIterable {
        case overview = "Overview"
        case statusCodes = "Status Codes"
        case methods = "Methods"
        case hosts = "Hosts"
        case performance = "Performance"
    }

    @State private var selectedTab: Tab = .overview
    @State private var insightsData: InsightsDataSource?

    // MARK: - Body

    var body: some View {
        Group {
            if items.isEmpty {
                emptyState(
                    icon: "chart.bar.doc.horizontal",
                    title: "No Analytics Data",
                    message: "Start monitoring network requests to see analytics."
                )
            } else if let insightsData {
                ScrollView {
                    VStack(spacing: 20) {
                        summaryCardsView(insightsData)
                        tabPickerView
                        selectedTabContent(insightsData)
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Analyzing requests…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Insights")
        .task(id: items.count) {
            let items = items
            let result = await Task.detached {
                InsightsDataSource.compute(from: items)
            }.value
            insightsData = result
        }
    }

    // MARK: - Summary Cards

    private func summaryCardsView(_ data: InsightsDataSource) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(
                title: "Total Requests",
                value: "\(data.totalRequests)",
                icon: "rectangle.stack",
                color: .blue
            )
            summaryCard(
                title: "Avg Response",
                value: formatDuration(data.avgResponseTime),
                icon: "timer",
                color: .purple
            )
            summaryCard(
                title: "Network Success",
                value: String(format: "%.1f%%", data.networkSuccessRate),
                subtitle: "\(data.networkSuccessCount) of \(data.totalRequests)",
                icon: "network",
                color: .green
            )
            summaryCard(
                title: "Network Failure",
                value: String(format: "%.1f%%", data.networkFailureRate),
                subtitle: "\(data.networkFailureCount) of \(data.totalRequests)",
                icon: "network.slash",
                color: .red
            )
            summaryCard(
                title: "HTTP Success",
                value: String(format: "%.1f%%", data.httpSuccessRate),
                subtitle: "\(data.httpSuccessCount) of \(data.httpSuccessCount + data.httpErrorCount)",
                icon: "checkmark.circle",
                color: .mint
            )
            summaryCard(
                title: "HTTP Error",
                value: String(format: "%.1f%%", data.httpErrorRate),
                subtitle: "\(data.httpErrorCount) of \(data.httpSuccessCount + data.httpErrorCount)",
                icon: "xmark.circle",
                color: .orange
            )
        }
    }

    private func summaryCard(title: String,
                             value: String,
                             subtitle: String? = nil,
                             icon: String,
                             color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(macOS)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        #else
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        #endif
    }

    // MARK: - Tab Picker

    private var tabPickerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                            )
                            .foregroundStyle(selectedTab == tab ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            #if os(macOS)
            .background(
                Capsule()
                    .fill(Color(.controlBackgroundColor))
            )
            #else
            .background(
                Capsule()
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            #endif
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func selectedTabContent(_ data: InsightsDataSource) -> some View {
        switch selectedTab {
        case .overview:
            overviewTab(data)
        case .statusCodes:
            statusCodesTab(data)
        case .methods:
            methodsTab(data)
        case .hosts:
            hostsTab(data)
        case .performance:
            performanceTab(data)
        }
    }

    // MARK: - Overview Tab

    private func overviewTab(_ data: InsightsDataSource) -> some View {
        VStack(spacing: 20) {
            sectionContainer(title: "Request Timeline", icon: "chart.line.uptrend.xyaxis") {
                RequestBarChartView(logs: items)
            }

            sectionContainer(title: "Top Hosts", icon: "server.rack") {
                breakdownList(
                    items: Array(data.hosts.sorted { $0.count > $1.count }.prefix(5)),
                    total: data.totalRequests,
                    colorProvider: { _ in .blue }
                )
            }
        }
    }

    // MARK: - Status Codes Tab

    private func statusCodesTab(_ data: InsightsDataSource) -> some View {
        VStack(spacing: 20) {
            sectionContainer(title: "Status Code Chart", icon: "chart.bar.fill") {
                StatusCodeChartView(data: data.statusCodes)
            }

            sectionContainer(title: "Status Code Breakdown", icon: "list.bullet") {
                breakdownList(
                    items: data.statusCodes.sorted { $0.count > $1.count },
                    total: data.totalRequests,
                    colorProvider: { item in
                        StatusCodeColor.color(for: Int(item.stringValue) ?? 0)
                    }
                )
            }

            sectionContainer(title: "By Category", icon: "tray.full.fill") {
                breakdownList(
                    items: data.statusCategories.sorted { $0.count > $1.count },
                    total: data.totalRequests,
                    colorProvider: { item in
                        switch item.stringValue {
                        case "Success": return .green
                        case "Client Error": return .red
                        case "Server Error": return .orange
                        case "Redirection": return .yellow
                        case "Informational": return .brown
                        default: return .gray
                        }
                    }
                )
            }
        }
    }

    // MARK: - Methods Tab

    private func methodsTab(_ data: InsightsDataSource) -> some View {
        VStack(spacing: 20) {
            sectionContainer(title: "HTTP Method Chart", icon: "chart.bar.fill") {
                HTTPMethodsChartView(data: data.httpMethods)
            }

            sectionContainer(title: "HTTP Method Breakdown", icon: "list.bullet") {
                breakdownList(
                    items: data.httpMethods.sorted { $0.count > $1.count },
                    total: data.totalRequests,
                    colorProvider: { item in
                        HTTPMethodColor.color(for: item.stringValue)
                    }
                )
            }
        }
    }

    // MARK: - Hosts Tab

    private func hostsTab(_ data: InsightsDataSource) -> some View {
        VStack(spacing: 20) {
            sectionContainer(title: "Hosts Chart", icon: "chart.bar.fill") {
                HostsChartView(data: data.hosts)
            }

            sectionContainer(title: "Host Breakdown", icon: "list.bullet") {
                breakdownList(
                    items: data.hosts.sorted { $0.count > $1.count },
                    total: data.totalRequests,
                    colorProvider: { _ in .blue }
                )
            }

            sectionContainer(title: "Errors by Host", icon: "exclamationmark.triangle.fill") {
                if data.errorsByHost.isEmpty {
                    Label("No errors recorded", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    breakdownList(
                        items: data.errorsByHost.sorted { $0.count > $1.count },
                        total: data.errorCount,
                        colorProvider: { _ in .red }
                    )
                }
            }
        }
    }

    // MARK: - Performance Tab

    private func performanceTab(_ data: InsightsDataSource) -> some View {
        VStack(spacing: 20) {
            performanceSummaryCards(data)

            sectionContainer(title: "Slowest Endpoints (Avg)", icon: "tortoise.fill") {
                endpointAverageList(stats: data.endpointStats, sortOrder: .slowest)
            }

            sectionContainer(title: "Fastest Endpoints (Avg)", icon: "hare.fill") {
                endpointAverageList(stats: data.endpointStats, sortOrder: .fastest)
            }

            sectionContainer(title: "Response Time by Host", icon: "chart.bar.fill") {
                responseTimeByHostList(data.hostResponseTimes)
            }

            if data.hasMockedRequests {
                sectionContainer(title: "Mocked Requests", icon: "theatermasks.fill") {
                    breakdownList(
                        items: data.mockedHosts.sorted { $0.count > $1.count },
                        total: data.mockedHosts.reduce(0) { $0 + $1.count },
                        colorProvider: { _ in .purple }
                    )
                }
            }
        }
    }

    private func performanceSummaryCards(_ data: InsightsDataSource) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            miniStatCard(title: "Fastest", value: formatDuration(data.minResponseTime), color: .green)
            miniStatCard(title: "Median", value: formatDuration(data.medianResponseTime), color: .blue)
            miniStatCard(title: "Slowest", value: formatDuration(data.maxResponseTime), color: .red)
        }
    }

    private func miniStatCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
#if os(macOS)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        )
#else
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
        )
#endif
    }

    // MARK: - Endpoint Average List

    private enum EndpointSortOrder {
        case slowest, fastest
    }

    private func endpointAverageList(stats: [InsightsDataSource.EndpointStat], sortOrder: EndpointSortOrder) -> some View {
        let sorted: [InsightsDataSource.EndpointStat] = switch sortOrder {
        case .slowest:
            Array(stats.sorted { $0.avgTime > $1.avgTime }.prefix(5))
        case .fastest:
            Array(stats.sorted { $0.avgTime < $1.avgTime }.prefix(5))
        }

        return VStack(spacing: 0) {
            if sorted.isEmpty {
                Text("No completed requests")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, stat in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        Text(stat.method)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(HTTPMethodColor.color(for: stat.method))
                            .frame(width: 44, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.path)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text("\(stat.count) call\(stat.count == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(formatDuration(stat.avgTime))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(responseTimeColor(stat.avgTime))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    if index < sorted.count - 1 {
                        Divider().padding(.leading, 40)
                    }
                }
            }
        }
    }

    // MARK: - Response Time by Host

    private func responseTimeByHostList(_ hostStats: [InsightsDataSource.HostTimeStat]) -> some View {
        let sorted = hostStats.sorted { $0.avgTime > $1.avgTime }

        return VStack(spacing: 0) {
            if sorted.isEmpty {
                Text("No completed requests")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, stat in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.host)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text("\(stat.count) request\(stat.count == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("avg \(formatDuration(stat.avgTime))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(responseTimeColor(stat.avgTime))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    if index < sorted.count - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
        }
    }

    // MARK: - Reusable Components

    private func sectionContainer<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .font(.subheadline)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
#if os(macOS)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
#else
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
#endif
    }

    private func breakdownList(
        items: [ChartParameter<String>],
        total: Int,
        colorProvider: @escaping (ChartParameter<String>) -> Color
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let percentage = total > 0 ? Double(item.count) / Double(total) * 100 : 0

                HStack(spacing: 10) {
                    Circle()
                        .fill(colorProvider(item))
                        .frame(width: 10, height: 10)

                    Text(item.stringValue == "0" ? "NA" : item.stringValue)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Text("\(item.count)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    Text(String(format: "%.1f%%", percentage))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .frame(width: 56, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)

                if index < items.count - 1 {
                    Divider().padding(.leading, 24)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Double) -> String {
        if seconds < 0.001 {
            return String(format: "%.0f µs", seconds * 1_000_000)
        } else if seconds < 1 {
            return String(format: "%.0f ms", seconds * 1000)
        } else {
            return String(format: "%.2f s", seconds)
        }
    }

    private func responseTimeColor(_ seconds: Double) -> Color {
        if seconds < 2.0 { return .green }
        if seconds < 3.0 { return .yellow }
        if seconds < 5.0 { return .orange }
        return .red
    }
}
