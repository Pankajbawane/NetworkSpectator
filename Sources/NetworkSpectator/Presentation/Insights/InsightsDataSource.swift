//
//  InsightsData.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/03/26.
//

import Foundation

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
        let total = data.count
        let completed = data.filter { !$0.isLoading && $0.responseTime > 0 }
        let times = completed.map(\.responseTime)

        // Network-level
        let netFailure = data.filter { $0.errorDescription != nil }.count
        let netSuccess = data.filter { $0.errorDescription == nil && !$0.isLoading }.count

        // HTTP-level
        let httpSuccess = data.filter { $0.errorDescription == nil && (200..<300).contains($0.statusCode) }.count
        let httpError = data.filter { (300..<600).contains($0.statusCode) }.count
        let errCount = data.filter(\.isError).count
        let httpSuccessAndErrorCount = httpSuccess + httpError
        let httpSuccessRate = httpSuccessAndErrorCount == 0 ? 0 : Double(httpSuccess) / Double(httpSuccess + httpError) * 100
        let httpErrorRate = httpSuccessAndErrorCount == 0 ? 0 : Double(httpError) / Double(httpSuccess + httpError) * 100

        // Response times
        let avg = times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
        let minT = times.min() ?? 0
        let maxT = times.max() ?? 0
        let med = Self.median(times)

        // Breakdowns
        let statusCodes = ChartItemFactory.get(items: data, key: { "\($0.statusCode)" })
        let httpMethods = ChartItemFactory.get(items: data, key: \.method)
        let hosts = ChartItemFactory.get(items: data, key: \.host)
        let categories = ChartItemFactory.get(items: data, key: \.statusCategory)
        let errors = data.filter(\.isError)
        let errByHost = ChartItemFactory.get(items: errors, key: \.host)

        // Mocked
        let mocked = data.filter(\.isMocked)
        let mockedHosts = ChartItemFactory.get(items: mocked, key: \.host)

        // Endpoint stats
        let grouped = Dictionary(grouping: completed) { item in
            "\(item.method) \(item.path.isEmpty ? "/" : item.path)"
        }
        let epStats = grouped.map { (_, items) -> EndpointStat in
            let epAvg = items.map(\.responseTime).reduce(0, +) / Double(items.count)
            return EndpointStat(
                method: items[0].method,
                path: items[0].path.isEmpty ? "/" : items[0].path,
                avgTime: epAvg,
                count: items.count
            )
        }

        // Host response times
        let hostGrouped = Dictionary(grouping: completed, by: \.host)
        let hostTimes = hostGrouped.map { (host, items) -> HostTimeStat in
            let hostAvg = items.map(\.responseTime).reduce(0, +) / Double(items.count)
            return HostTimeStat(host: host, avgTime: hostAvg, count: items.count)
        }

        return InsightsDataSource(
            totalRequests: total,
            networkSuccessCount: netSuccess,
            networkFailureCount: netFailure,
            networkSuccessRate: total > 0 ? Double(netSuccess) / Double(total) * 100 : 0,
            networkFailureRate: total > 0 ? Double(netFailure) / Double(total) * 100 : 0,
            httpSuccessCount: httpSuccess,
            httpErrorCount: httpError,
            httpSuccessRate: httpSuccessRate,
            httpErrorRate: httpErrorRate,
            errorCount: errCount,
            avgResponseTime: avg,
            minResponseTime: minT,
            maxResponseTime: maxT,
            medianResponseTime: med,
            statusCodes: statusCodes,
            httpMethods: httpMethods,
            hosts: hosts,
            statusCategories: categories,
            errorsByHost: errByHost,
            mockedHosts: mockedHosts,
            hasMockedRequests: !mocked.isEmpty,
            endpointStats: epStats,
            hostResponseTimes: hostTimes
        )
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
