import SwiftUI

struct AnalyticsDashboardView: View {
    let data: [LogItem]
    
    var statusCode: [ChartParameter<String>] {
        ChartItemFactory.get(items: data, key: { "\($0.statusCode)" })
    }
    
    var httpMethod: [ChartParameter<String>] {
        ChartItemFactory.get(items: data, key: \.method)
    }
    
    var hosts: [ChartParameter<String>] {
        ChartItemFactory.get(items: data, key: \.host)
    }
    
    private var totalRequests: Int {
        data.count
    }
    
    private var successRate: Double {
        guard !data.isEmpty else { return 0 }
        let successCount = data.filter { $0.statusCode >= 200 && $0.statusCode < 300 }.count
        return Double(successCount) / Double(data.count) * 100
    }

    var body: some View {
        if data.isEmpty {
            emptyState(
                    icon: "chart.bar.doc.horizontal",
                    title: "No Analytics Data",
                    message: "Start monitoring network requests to see analytics."
                )
            .navigationTitle("Insights")
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCardsView

                    chartSectionView(
                        title: "Status Codes",
                        icon: "checkmark.circle.fill",
                        barChart: StatusCodeChartView(data: statusCode),
                        pieChart: PieChartView(data: statusCode, title: "Status Code")
                    )

                    chartSectionView(
                        title: "HTTP Methods",
                        icon: "arrow.left.arrow.right",
                        barChart: HTTPMethodsChartView(data: httpMethod),
                        pieChart: PieChartView(data: httpMethod, title: "HTTP Methods")
                    )

                    chartSectionView(
                        title: "Hosts",
                        icon: "server.rack",
                        barChart: HostsChartView(data: hosts),
                        pieChart: PieChartView(data: hosts, title: "Hosts")
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.blue)
                                .font(.title3)
                            Text("Request Timeline")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)

                        RequestBarChartView(logs: data)
                        #if os(macOS)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.controlBackgroundColor))
                            )
                        #endif
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }
    
    private var summaryCardsView: some View {
        HStack(spacing: 16) {
            summaryCard(
                title: "Total Requests",
                value: "\(totalRequests)",
                icon: "network",
                color: .blue
            )

            summaryCard(
                title: "Success Rate",
                value: String(format: "%.1f%%", successRate),
                icon: "checkmark.circle",
                color: .green
            )

            summaryCard(
                title: "Unique Hosts",
                value: "\(hosts.count)",
                icon: "server.rack",
                color: .orange
            )
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
#if os(macOS)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.controlBackgroundColor))
    )
#endif
    }

    private func chartSectionView<BarChart: View, PieChart: View>(
        title: String,
        icon: String,
        barChart: BarChart,
        pieChart: PieChart
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                VStack {
                    barChart
                }
                .frame(maxWidth: .infinity)
#if os(macOS)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.controlBackgroundColor))
    )
#endif

                VStack {
                    pieChart
                }
                .frame(maxWidth: .infinity)
#if os(macOS)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.controlBackgroundColor))
    )
#endif
            }
        }
    }
}
