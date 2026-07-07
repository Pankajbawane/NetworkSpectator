//
//  InsightsDataSource.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/03/26.
//

import Foundation
import NetworkSpectatorCore

// MARK: - Compute Insights Datasource
struct InsightsDataSource: Sendable {
    let totalRequests: Int
    let networkSuccessCount: Int
    let networkFailureCount: Int
    let networkSuccessRate: Double
    let networkFailureRate: Double
    let httpSuccessCount: Int
    let httpErrorCount: Int
    let httpSuccessRate: Double
    let httpErrorRate: Double
    let errorCount: Int
    let avgResponseTime: Double
    let minResponseTime: Double
    let maxResponseTime: Double
    let medianResponseTime: Double

    let statusCodes: [ChartParameter<String>]
    let httpMethods: [ChartParameter<String>]
    let hosts: [ChartParameter<String>]
    let statusCategories: [ChartParameter<String>]
    let errorsByHost: [ChartParameter<String>]
    let mockedHosts: [ChartParameter<String>]
    let hasMockedRequests: Bool

    let endpointStats: [EndpointStat]
    let hostResponseTimes: [HostTimeStat]

    struct EndpointStat: Identifiable, Sendable {
        let method: String
        let path: String
        let avgTime: Double
        let count: Int
        var id: String { "\(method) \(path)" }
    }

    struct HostTimeStat: Identifiable, Sendable {
        let host: String
        let avgTime: Double
        let count: Int
        var id: String { host }
    }

    static func compute(from data: [LogItem]) -> InsightsDataSource {
        let totalRequests = data.count
        let completedItems = data.filter { !$0.isLoading && $0.responseTime > 0 }
        let networkStats = makeNetworkStats(from: data)
        let httpStats = makeHTTPStats(from: data)
        let responseTimeStats = makeResponseTimeStats(from: completedItems)
        let errors = data.filter(\.isError)
        let mockedItems = data.filter(\.isMocked)

        return InsightsDataSource(
            totalRequests: totalRequests,
            networkSuccessCount: networkStats.successCount,
            networkFailureCount: networkStats.failureCount,
            networkSuccessRate: rate(part: networkStats.successCount, total: totalRequests),
            networkFailureRate: rate(part: networkStats.failureCount, total: totalRequests),
            httpSuccessCount: httpStats.successCount,
            httpErrorCount: httpStats.errorCount,
            httpSuccessRate: rate(part: httpStats.successCount, total: httpStats.totalCount),
            httpErrorRate: rate(part: httpStats.errorCount, total: httpStats.totalCount),
            errorCount: errors.count,
            avgResponseTime: responseTimeStats.average,
            minResponseTime: responseTimeStats.minimum,
            maxResponseTime: responseTimeStats.maximum,
            medianResponseTime: responseTimeStats.median,
            statusCodes: ChartParameter.build(items: data, key: { "\($0.statusCode)" }),
            httpMethods: ChartParameter.build(items: data, key: \.method),
            hosts: ChartParameter.build(items: data, key: \.host),
            statusCategories: ChartParameter.build(items: data, key: \.statusCategory),
            errorsByHost: ChartParameter.build(items: errors, key: \.host),
            mockedHosts: ChartParameter.build(items: mockedItems, key: \.host),
            hasMockedRequests: !mockedItems.isEmpty,
            endpointStats: makeEndpointStats(from: completedItems),
            hostResponseTimes: makeHostResponseTimes(from: completedItems)
        )
    }

    private static func makeNetworkStats(from items: [LogItem]) -> (successCount: Int, failureCount: Int) {
        let failureCount = items.filter { $0.errorDescription != nil }.count
        let successCount = items.filter { $0.errorDescription == nil && !$0.isLoading }.count
        return (successCount, failureCount)
    }

    private static func makeHTTPStats(from items: [LogItem]) -> (successCount: Int, errorCount: Int, totalCount: Int) {
        let successCount = items.filter { $0.errorDescription == nil && (200..<300).contains($0.statusCode) }.count
        let errorCount = items.filter { (400..<600).contains($0.statusCode) }.count
        return (successCount, errorCount, successCount + errorCount)
    }

    private static func makeResponseTimeStats(from completedItems: [LogItem]) -> (average: Double,
                                                                                 minimum: Double,
                                                                                 maximum: Double,
                                                                                 median: Double) {
        let times = completedItems.map(\.responseTime)
        return (
            average: times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count),
            minimum: times.min() ?? 0,
            maximum: times.max() ?? 0,
            median: median(times)
        )
    }

    private static func makeEndpointStats(from completedItems: [LogItem]) -> [EndpointStat] {
        let groupedItems = Dictionary(grouping: completedItems) { item in
            "\(item.method) \(normalizedPath(for: item))"
        }

        return groupedItems.compactMap { _, items in
            guard let firstItem = items.first else { return nil }
            let averageTime = averageResponseTime(for: items)
            return EndpointStat(
                method: firstItem.method,
                path: normalizedPath(for: firstItem),
                avgTime: averageTime,
                count: items.count
            )
        }
        .sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.id < $1.id
        }
    }

    private static func makeHostResponseTimes(from completedItems: [LogItem]) -> [HostTimeStat] {
        Dictionary(grouping: completedItems, by: \.host)
            .map { host, items in
                HostTimeStat(host: host,
                             avgTime: averageResponseTime(for: items),
                             count: items.count)
            }
            .sorted {
                if $0.count != $1.count { return $0.count > $1.count }
                return $0.host < $1.host
            }
    }

    private static func normalizedPath(for item: LogItem) -> String {
        item.path.isEmpty ? "/" : item.path
    }

    private static func averageResponseTime(for items: [LogItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        return items.map(\.responseTime).reduce(0, +) / Double(items.count)
    }

    private static func rate(part: Int, total: Int) -> Double {
        total == 0 ? 0 : Double(part) / Double(total) * 100
    }

    private static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let count = sorted.count
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        }
        return sorted[count / 2]
    }
}
