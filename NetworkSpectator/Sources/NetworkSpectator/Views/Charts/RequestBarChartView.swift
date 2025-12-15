//
//  RequestBarChartView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/12/25.
//

import SwiftUI
import Charts

struct RequestBarChartView: View {
    let logs: [LogItem]

    private struct TimeBucket: Identifiable {
        let id: Date
        let count: Int
    }

    private enum TimeGranularity {
        case second, minute, hour, day

        func floor(_ date: Date) -> Date {
            let calendar = Calendar.current
            let components: Set<Calendar.Component>

            switch self {
            case .second: components = [.year, .month, .day, .hour, .minute, .second]
            case .minute: components = [.year, .month, .day, .hour, .minute]
            case .hour: components = [.year, .month, .day, .hour]
            case .day: components = [.year, .month, .day]
            }

            return calendar.date(from: calendar.dateComponents(components, from: date)) ?? date
        }

        func next(_ date: Date) -> Date {
            let calendar = Calendar.current
            let component: Calendar.Component

            switch self {
            case .second: component = .second
            case .minute: component = .minute
            case .hour: component = .hour
            case .day: component = .day
            }

            return calendar.date(byAdding: component, value: 1, to: date) ?? date
        }

        static func choose(for span: TimeInterval) -> TimeGranularity {
            switch span {
            case ..<300: return .second
            case ..<7200: return .minute
            case ..<172800: return .hour
            default: return .day
            }
        }
    }

    private func chartData() async -> ([TimeBucket], ClosedRange<Date>) {
        guard !logs.isEmpty else {
            let now = Date()
            return ([], now.addingTimeInterval(-60)...now)
        }

        guard let minTime = logs.first?.startTime,
              let maxTime = logs.last?.startTime else {
            let now = Date()
            return ([], now.addingTimeInterval(-60)...now)
        }

        let now = Date()
        let domain = minTime...max(maxTime, now)
        let span = domain.upperBound.timeIntervalSince(domain.lowerBound)
        let granularity = TimeGranularity.choose(for: span)

        var counts: [Date: Int] = [:]
        for timestamp in logs.map(\.startTime) {
            let bucket = granularity.floor(timestamp)
            counts[bucket, default: 0] += 1
        }

        var buckets: [TimeBucket] = []
        var current = granularity.floor(minTime)

        while current <= domain.upperBound {
            buckets.append(TimeBucket(id: current, count: counts[current] ?? 0))
            current = granularity.next(current)
        }

        return (buckets, domain)
    }
    
    @State private var data: ([TimeBucket], ClosedRange<Date>)?

    var body: some View {

        VStack {
            if data == nil {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Requests")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical)
            } else {
                Chart(data?.0 ?? []) { bucket in
                    BarMark(
                        x: .value("Time", bucket.id),
                        y: .value("Requests", bucket.count)
                    )
                    .foregroundStyle(.blue)
                }
                .chartXScale(domain: data!.1)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .padding(.vertical)
            }
        }.task {
            data = await chartData()
        }
    }
}

#Preview("Requests Over Time Chart") {
    let now = Date()
    var items: [LogItem] = []
    // Generate sample logs within the last 10 minutes
    for i in 0..<120 {
        let secondsBack = TimeInterval(Int.random(in: 0..<600))
        let start = now.addingTimeInterval(-secondsBack)
        items.append(LogItem(startTime: start, url: "https://example.com/\(i)"))
    }
    return RequestBarChartView(logs: items)
        .frame(height: 260)
        .padding()
}
