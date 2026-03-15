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
            case .fiveSeconds, .tenSeconds, .thirtySeconds, .fiveMinutes:
                let seconds = Self.calendar.component(.second, from: floored)
                let roundedSeconds = (seconds / Int(interval)) * Int(interval)
                return Self.calendar.date(bySetting: .second, value: roundedSeconds, of: floored) ?? floored

            case .fifteenMinutes, .thirtyMinutes:
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

            return .fiveSeconds
        }
    }

    private func chartData() -> ([TimeBucket], ClosedRange<Date>, TimeGranularity)? {
        guard !logs.isEmpty else { return nil }

        let times = logs.map(\.startTime)
        guard let minTime = times.min(), let maxTime = times.max() else { return nil }

        let span = maxTime.timeIntervalSince(minTime)
        let granularity = TimeGranularity.second

        var counts: [Date: Int] = [:]
        for timestamp in times {
            let bucket = granularity.floor(timestamp)
            counts[bucket, default: 0] += 1
        }

        let buckets = counts.map { TimeBucket(id: $0.key, count: $0.value) }
            .sorted(by: { $0.id < $1.id })

        guard let first = buckets.first?.id, let last = buckets.last?.id else { return nil }
        let domain = first...last

        return (buckets, domain, granularity)
    }
    
    var body: some View {
        let data = chartData()

        VStack {
            if let (buckets, domain, granularity) = data {
                let maxCount = buckets.map(\.count).max() ?? 1
                let yDomain = 0...max(maxCount, 1)

                // Generate uniformly spaced tick dates across the domain
                let tickDates: [Date] = {
                    var dates: [Date] = []
                    var current = domain.lowerBound
                    while current <= domain.upperBound {
                        dates.append(current)
                        current = granularity.next(current)
                    }
                    return dates
                }()
                
                let labelledDates = Set(tickDates.enumerated().compactMap { index, date in
                    let offset: Int = max(tickDates.count / 15, 1)
                    return index % offset == 0 ? date : nil
                })

            Chart(buckets) { bucket in
                    LineMark(
                        x: .value("Time", bucket.id),
                        y: .value("Requests", bucket.count)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Time", bucket.id),
                        y: .value("Requests", bucket.count)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    PointMark(
                        x: .value("Time", bucket.id),
                        y: .value("Requests", bucket.count)
                    )
                    .symbolSize(20)
                    .foregroundStyle(.blue)
                }
                .chartXScale(domain: domain)
                .chartYScale(domain: yDomain)
                .chartXAxis {
                    AxisMarks(values: tickDates) { value in
                        if let date = value.as(Date.self), domain.lowerBound == date {
                            AxisValueLabel(collisionResolution: .greedy)
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        } else if let date = value.as(Date.self), labelledDates.contains(date) {
                            AxisGridLine()
                            AxisValueLabel(collisionResolution: .greedy)
                        }
                    }
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

