//
//  InsightsDataSourceTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectatorCore
@testable import NetworkSpectatorUI

// MARK: - InsightsDataSource Tests
@Suite("InsightsDataSource Tests")
struct InsightsDataSourceTests {

    // MARK: - Helpers

    private func makeItem(
        url: String = "https://example.com/api/users",
        method: String = "GET",
        statusCode: Int = 200,
        responseTime: TimeInterval = 0.5,
        isLoading: Bool = false,
        errorDescription: String? = nil,
        mockId: UUID? = nil
    ) -> LogItem {
        LogItem(
            url: url,
            method: method,
            statusCode: statusCode,
            errorDescription: errorDescription,
            responseTime: responseTime,
            isLoading: isLoading,
            mockId: mockId
        )
    }

    // MARK: - Empty Data

    @Test("Compute with empty data returns all zeros")
    func testComputeEmptyData() {
        let result = InsightsDataSource.compute(from: [])

        #expect(result.totalRequests == 0)
        #expect(result.networkSuccessCount == 0)
        #expect(result.networkFailureCount == 0)
        #expect(result.networkSuccessRate == 0)
        #expect(result.networkFailureRate == 0)
        #expect(result.httpSuccessCount == 0)
        #expect(result.httpErrorCount == 0)
        #expect(result.httpSuccessRate == 0)
        #expect(result.httpErrorRate == 0)
        #expect(result.errorCount == 0)
        #expect(result.avgResponseTime == 0)
        #expect(result.minResponseTime == 0)
        #expect(result.maxResponseTime == 0)
        #expect(result.medianResponseTime == 0)
        #expect(result.statusCodes.isEmpty)
        #expect(result.httpMethods.isEmpty)
        #expect(result.hosts.isEmpty)
        #expect(result.statusCategories.isEmpty)
        #expect(result.errorsByHost.isEmpty)
        #expect(result.mockedHosts.isEmpty)
        #expect(result.hasMockedRequests == false)
        #expect(result.endpointStats.isEmpty)
        #expect(result.hostResponseTimes.isEmpty)
    }

    // MARK: - Total Requests

    @Test("Total requests count matches input count")
    func testTotalRequests() {
        let items = [
            makeItem(),
            makeItem(url: "https://example.com/api/posts"),
            makeItem(url: "https://other.com/data")
        ]
        let result = InsightsDataSource.compute(from: items)
        #expect(result.totalRequests == 3)
    }

    // MARK: - Network Success/Failure

    @Test("Network success counts completed requests without errors")
    func testNetworkSuccessCount() {
        let items = [
            makeItem(statusCode: 200),
            makeItem(statusCode: 404), // no errorDescription, not loading -> success
            makeItem(statusCode: 200, errorDescription: "timeout"), // has error -> failure
            makeItem(statusCode: 200, isLoading: true) // loading -> neither
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.networkSuccessCount == 2)
        #expect(result.networkFailureCount == 1)
    }

    @Test("Network success rate is calculated as percentage")
    func testNetworkSuccessRate() {
        let items = [
            makeItem(statusCode: 200),
            makeItem(statusCode: 200, errorDescription: "error")
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.networkSuccessRate == 50.0)
        #expect(result.networkFailureRate == 50.0)
    }

    // MARK: - HTTP Success/Error

    @Test("HTTP success counts 2xx without errors")
    func testHTTPSuccessCount() {
        let items = [
            makeItem(statusCode: 200),
            makeItem(statusCode: 201),
            makeItem(statusCode: 404),
            makeItem(statusCode: 500)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.httpSuccessCount == 2)
        #expect(result.httpErrorCount == 2)
    }

    @Test("HTTP success rate is percentage of success / (success + error)")
    func testHTTPSuccessRate() {
        let items = [
            makeItem(statusCode: 200),
            makeItem(statusCode: 200),
            makeItem(statusCode: 404),
            makeItem(statusCode: 500)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.httpSuccessRate == 50.0)
        #expect(result.httpErrorRate == 50.0)
    }

    @Test("HTTP rates are zero when no HTTP success or error items exist")
    func testHTTPRatesZeroWhenNoHTTPItems() {
        // Status code 0, no error -> not counted in httpSuccess or httpError
        let items = [makeItem(statusCode: 0)]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.httpSuccessRate == 0)
        #expect(result.httpErrorRate == 0)
    }

    @Test("HTTP redirects are not counted as errors")
    func testHTTPRedirectsAreNotErrors() {
        let items = [
            makeItem(statusCode: 200),
            makeItem(statusCode: 302),
            makeItem(statusCode: 404)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.httpSuccessCount == 1)
        #expect(result.httpErrorCount == 1)
        #expect(result.httpSuccessRate == 50.0)
        #expect(result.httpErrorRate == 50.0)
    }

    // MARK: - Error Count

    @Test("Error count includes 4xx, 5xx, and items with errorDescription")
    func testErrorCount() {
        let items = [
            makeItem(statusCode: 200),
            makeItem(statusCode: 404),
            makeItem(statusCode: 500),
            makeItem(statusCode: 200, errorDescription: "network error")
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.errorCount == 3)
    }

    // MARK: - Response Time Statistics

    @Test("Response time statistics for single item")
    func testResponseTimeSingleItem() {
        let items = [makeItem(responseTime: 1.5)]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.avgResponseTime == 1.5)
        #expect(result.minResponseTime == 1.5)
        #expect(result.maxResponseTime == 1.5)
        #expect(result.medianResponseTime == 1.5)
    }

    @Test("Response time statistics for multiple items")
    func testResponseTimeMultipleItems() {
        let items = [
            makeItem(responseTime: 1.0),
            makeItem(responseTime: 2.0),
            makeItem(responseTime: 3.0)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.avgResponseTime == 2.0)
        #expect(result.minResponseTime == 1.0)
        #expect(result.maxResponseTime == 3.0)
        #expect(result.medianResponseTime == 2.0)
    }

    @Test("Median with even number of items averages two middle values")
    func testMedianEvenCount() {
        let items = [
            makeItem(responseTime: 1.0),
            makeItem(responseTime: 2.0),
            makeItem(responseTime: 3.0),
            makeItem(responseTime: 4.0)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.medianResponseTime == 2.5)
    }

    @Test("Loading items are excluded from response time calculations")
    func testLoadingExcludedFromResponseTimes() {
        let items = [
            makeItem(responseTime: 2.0),
            makeItem(responseTime: 0, isLoading: true)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.avgResponseTime == 2.0)
        #expect(result.minResponseTime == 2.0)
        #expect(result.maxResponseTime == 2.0)
    }

    // MARK: - Status Code Breakdown

    @Test("Status codes are grouped correctly")
    func testStatusCodeBreakdown() {
        let items = [
            makeItem(statusCode: 200),
            makeItem(statusCode: 200),
            makeItem(statusCode: 404)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.statusCodes.count == 2)
        let code200 = result.statusCodes.first { $0.stringValue == "200" }
        let code404 = result.statusCodes.first { $0.stringValue == "404" }
        #expect(code200?.count == 2)
        #expect(code404?.count == 1)
    }

    // MARK: - HTTP Methods Breakdown

    @Test("HTTP methods are grouped correctly")
    func testHTTPMethodBreakdown() {
        let items = [
            makeItem(method: "GET"),
            makeItem(method: "GET"),
            makeItem(method: "POST")
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.httpMethods.count == 2)
        let getMethod = result.httpMethods.first { $0.stringValue == "GET" }
        let postMethod = result.httpMethods.first { $0.stringValue == "POST" }
        #expect(getMethod?.count == 2)
        #expect(postMethod?.count == 1)
    }

    // MARK: - Hosts Breakdown

    @Test("Hosts are grouped correctly")
    func testHostsBreakdown() {
        let items = [
            makeItem(url: "https://example.com/api/1"),
            makeItem(url: "https://example.com/api/2"),
            makeItem(url: "https://other.com/data")
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.hosts.count == 2)
        let exampleHost = result.hosts.first { $0.stringValue == "example.com" }
        let otherHost = result.hosts.first { $0.stringValue == "other.com" }
        #expect(exampleHost?.count == 2)
        #expect(otherHost?.count == 1)
    }

    // MARK: - Errors by Host

    @Test("Errors are grouped by host")
    func testErrorsByHost() {
        let items = [
            makeItem(url: "https://example.com/api", statusCode: 404),
            makeItem(url: "https://example.com/api", statusCode: 500),
            makeItem(url: "https://other.com/data", statusCode: 200)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.errorsByHost.count == 1)
        let exampleErrors = result.errorsByHost.first { $0.stringValue == "example.com" }
        #expect(exampleErrors?.count == 2)
    }

    // MARK: - Mocked Requests

    @Test("Mocked requests are detected and grouped by host")
    func testMockedRequests() {
        let mockId = UUID()
        let items = [
            makeItem(url: "https://example.com/api", mockId: mockId),
            makeItem(url: "https://example.com/other", mockId: mockId),
            makeItem(url: "https://other.com/data")
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.hasMockedRequests == true)
        #expect(result.mockedHosts.count == 1)
        let mockedHost = result.mockedHosts.first { $0.stringValue == "example.com" }
        #expect(mockedHost?.count == 2)
    }

    @Test("No mocked requests sets hasMockedRequests to false")
    func testNoMockedRequests() {
        let items = [makeItem()]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.hasMockedRequests == false)
        #expect(result.mockedHosts.isEmpty)
    }

    // MARK: - Endpoint Stats

    @Test("Endpoint stats group by method and path")
    func testEndpointStats() {
        let items = [
            makeItem(url: "https://example.com/api/users", method: "GET", responseTime: 1.0),
            makeItem(url: "https://example.com/api/users", method: "GET", responseTime: 3.0),
            makeItem(url: "https://example.com/api/posts", method: "POST", responseTime: 2.0)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.endpointStats.count == 2)
        let getUsersStat = result.endpointStats.first { $0.method == "GET" && $0.path == "/api/users" }
        #expect(getUsersStat?.count == 2)
        #expect(getUsersStat?.avgTime == 2.0)
    }

    @Test("Endpoint stats use / for empty path")
    func testEndpointStatsEmptyPath() {
        let items = [makeItem(url: "https://example.com", responseTime: 1.0)]
        let result = InsightsDataSource.compute(from: items)

        let stat = result.endpointStats.first
        #expect(stat?.path == "/")
    }

    // MARK: - Host Response Times

    @Test("Host response times group by host with average")
    func testHostResponseTimes() {
        let items = [
            makeItem(url: "https://example.com/api", responseTime: 1.0),
            makeItem(url: "https://example.com/other", responseTime: 3.0),
            makeItem(url: "https://other.com/data", responseTime: 2.0)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.hostResponseTimes.count == 2)
        let exampleTime = result.hostResponseTimes.first { $0.host == "example.com" }
        #expect(exampleTime?.avgTime == 2.0)
        #expect(exampleTime?.count == 2)
    }

    // MARK: - All Errors Scenario

    @Test("All error items computes correct rates")
    func testAllErrors() {
        let items = [
            makeItem(statusCode: 500),
            makeItem(statusCode: 404)
        ]
        let result = InsightsDataSource.compute(from: items)

        #expect(result.httpErrorCount == 2)
        #expect(result.httpSuccessCount == 0)
        #expect(result.httpErrorRate == 100.0)
        #expect(result.httpSuccessRate == 0)
        #expect(result.errorCount == 2)
    }

    // MARK: - Status Categories

    @Test("Status categories are grouped correctly")
    func testStatusCategories() {
        let items = [
            makeItem(statusCode: 200),
            makeItem(statusCode: 201),
            makeItem(statusCode: 404),
            makeItem(statusCode: 500)
        ]
        let result = InsightsDataSource.compute(from: items)

        let success = result.statusCategories.first { $0.stringValue == "Success" }
        let clientError = result.statusCategories.first { $0.stringValue == "Client Error" }
        let serverError = result.statusCategories.first { $0.stringValue == "Server Error" }

        #expect(success?.count == 2)
        #expect(clientError?.count == 1)
        #expect(serverError?.count == 1)
    }
}
