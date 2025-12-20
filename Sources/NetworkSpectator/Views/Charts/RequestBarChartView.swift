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
        
        var displayTime: String {
            id.formatted(date: .abbreviated, time: .standard)
        }
    }

    private enum TimeGranularity {
        case second, fiveSeconds, tenSeconds, thirtySeconds
        case minute, fiveMinutes, fifteenMinutes, thirtyMinutes
        case hour

        private static let calendar = Calendar.current

        var interval: TimeInterval {
            switch self {
            case .second: return 1
            case .fiveSeconds: return 5
            case .tenSeconds: return 10
            case .thirtySeconds: return 30
            case .minute: return 60
            case .fiveMinutes: return 300
            case .fifteenMinutes: return 900
            case .thirtyMinutes: return 1800
            case .hour: return 3600
            }
        }

        func floor(_ date: Date) -> Date {
            let components: Set<Calendar.Component>

            switch self {
            case .second, .fiveSeconds, .tenSeconds, .thirtySeconds:
                components = [.year, .month, .day, .hour, .minute, .second]
            case .minute, .fiveMinutes, .fifteenMinutes, .thirtyMinutes:
                components = [.year, .month, .day, .hour, .minute]
            case .hour:
                components = [.year, .month, .day, .hour]
            }

            let floored = Self.calendar.date(from: Self.calendar.dateComponents(components, from: date)) ?? date

            // For multi-unit granularities, round down to the nearest multiple
            switch self {
            case .fiveSeconds, .tenSeconds, .thirtySeconds:
                let seconds = Self.calendar.component(.second, from: floored)
                let roundedSeconds = (seconds / Int(interval)) * Int(interval)
                return Self.calendar.date(bySetting: .second, value: roundedSeconds, of: floored) ?? floored

            case .fiveMinutes, .fifteenMinutes, .thirtyMinutes:
                let minutes = Self.calendar.component(.minute, from: floored)
                let roundedMinutes = (minutes / Int(interval / 60)) * Int(interval / 60)
                return Self.calendar.date(bySetting: .minute, value: roundedMinutes, of: floored) ?? floored

            default:
                return floored
            }
        }

        func next(_ date: Date) -> Date {
            return date.addingTimeInterval(interval)
        }

        static func choose(for span: TimeInterval, targetBuckets: Int = 20) -> TimeGranularity {
            let granularities: [TimeGranularity] = [
                .second, .fiveSeconds, .tenSeconds, .thirtySeconds,
                .minute, .fiveMinutes, .fifteenMinutes, .thirtyMinutes,
                .hour
            ]

            // Find the granularity that gives us closest to target bucket count
            for granularity in granularities {
                let bucketCount = span / granularity.interval
                if bucketCount <= Double(targetBuckets) {
                    return granularity
                }
            }

            return .hour
        }
    }

    private func chartData() -> ([TimeBucket], ClosedRange<Date>, TimeGranularity)? {
        guard !logs.isEmpty else { return nil }

        let times = logs.map(\.startTime)
        guard let minTime = times.min() else { return nil }
        guard let maxTime = times.max() else { return nil }

        // Add small padding to ensure all data points are visible
        let padding = max((maxTime.timeIntervalSince(minTime)) * 0.02, 1.0)
        let paddedMinTime = minTime.addingTimeInterval(-padding)
        let paddedMaxTime = maxTime.addingTimeInterval(padding)

        let domain = paddedMinTime...paddedMaxTime
        let span = domain.upperBound.timeIntervalSince(domain.lowerBound)
        let granularity = TimeGranularity.choose(for: span, targetBuckets: 20)

        var counts: [Date: Int] = [:]
        for timestamp in times {
            let bucket = granularity.floor(timestamp)
            counts[bucket, default: 0] += 1
        }

        // Only include buckets with counts > 0 for better visibility
        let buckets = counts.map { TimeBucket(id: $0.key, count: $0.value) }
            .sorted(by: { $0.id < $1.id })

        return (buckets, domain, granularity)
    }
    
    var body: some View {
        let data = chartData()

        VStack {
            if let (buckets, domain, granularity) = data {
                let maxCount = buckets.map(\.count).max() ?? 1
                let yDomain = 0...max(maxCount, 1)

                // Calculate appropriate axis mark count based on granularity
                let axisMarkCount = min(Int(domain.upperBound.timeIntervalSince(domain.lowerBound) / granularity.interval), 10)

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
                    AxisMarks(values: .automatic(desiredCount: max(axisMarkCount, 4)))
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
