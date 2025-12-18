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

    private let endTime = Date()

    private struct TimeBucket: Identifiable {
        let id: Date
        let count: Int
    }

    private enum TimeGranularity {
        case second, minute, hour, day

        private static let calendar = Calendar.current

        func floor(_ date: Date) -> Date {
            let components: Set<Calendar.Component>

            switch self {
            case .minute: components = [.year, .month, .day, .hour, .minute]
            case .hour: components = [.year, .month, .day, .hour]
            case .day: components = [.year, .month, .day]
            case .second:
                components = [.year, .month, .day, .hour, .minute, .second]
            }

            return Self.calendar.date(from: Self.calendar.dateComponents(components, from: date)) ?? date
        }

        func next(_ date: Date) -> Date {
            let component: Calendar.Component

            switch self {
            case .minute: component = .minute
            case .hour: component = .hour
            case .day: component = .day
            case .second:
                component = .second
            }

            return Self.calendar.date(byAdding: component, value: 1, to: date) ?? date
        }

        static func choose(for span: TimeInterval) -> TimeGranularity {
            switch span {
                case ..<120: return .second
            case ..<3600: return .minute
            case ..<86400: return .hour
            default: return .hour
            }
        }
    }

    private func chartData(endTime: Date) -> ([TimeBucket], ClosedRange<Date>)? {
        guard !logs.isEmpty else { return nil }

        let times = logs.map(\.startTime)
        guard let minTime = times.first else { return nil }

        let domain = minTime...endTime
        let span = domain.upperBound.timeIntervalSince(domain.lowerBound)
        let granularity = TimeGranularity.choose(for: span)

        var counts: [Date: Int] = [:]
        for timestamp in times {
            let bucket = granularity.floor(timestamp)
            counts[bucket, default: 0] += 1
        }

        // Only include buckets with counts > 0 for better visibility
        let buckets = counts.map { TimeBucket(id: $0.key, count: $0.value) }
            .sorted(by: { $0.id < $1.id })

        return (buckets, domain)
    }
    
    var body: some View {
        let data = chartData(endTime: endTime)

        VStack {
            if let (buckets, domain) = data {
                let maxCount = buckets.map(\.count).max() ?? 1
                let yDomain = 0...max(maxCount, 1)

                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("Time", bucket.id),
                        y: .value("Requests", bucket.count)
                    )
                    .foregroundStyle(.blue)
                }
                .chartXScale(domain: domain)
                .chartYScale(domain: yDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(minHeight: 200)
                .padding(.vertical)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Requests")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical)
            }
        }
        .padding()
    }
}
