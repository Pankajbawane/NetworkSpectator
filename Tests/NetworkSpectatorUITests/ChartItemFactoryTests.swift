//
//  ChartItemFactoryTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectatorCore
@testable import NetworkSpectatorUI

// MARK: - ChartItemFactory Tests
@Suite("ChartItemFactory Tests")
struct ChartItemFactoryTests {

    // MARK: - Helpers

    private func makeItem(
        url: String = "https://example.com/api",
        method: String = "GET",
        statusCode: Int = 200
    ) -> LogItem {
        LogItem(url: url, method: method, statusCode: statusCode)
    }

    // MARK: - Empty Input

    @Test("Empty items returns empty result")
    func testEmptyItems() {
        let result = ChartParameter.build(items: [], key: \.method)
        #expect(result.isEmpty)
    }

    // MARK: - Single Item

    @Test("Single item returns one ChartParameter with count 1")
    func testSingleItem() {
        let items = [makeItem(method: "GET")]
        let result = ChartParameter.build(items: items, key: \.method)

        #expect(result.count == 1)
        #expect(result[0].value == "GET")
        #expect(result[0].count == 1)
    }

    // MARK: - Grouping

    @Test("Items are grouped by key function")
    func testGrouping() {
        let items = [
            makeItem(method: "GET"),
            makeItem(method: "GET"),
            makeItem(method: "POST"),
            makeItem(method: "DELETE")
        ]
        let result = ChartParameter.build(items: items, key: \.method)

        #expect(result.count == 3)

        let get = result.first { $0.value == "GET" }
        let post = result.first { $0.value == "POST" }
        let delete = result.first { $0.value == "DELETE" }

        #expect(get?.count == 2)
        #expect(post?.count == 1)
        #expect(delete?.count == 1)
    }

    // MARK: - Sorting

    @Test("Results are sorted by stringValue")
    func testSortedByStringValue() {
        let items = [
            makeItem(method: "POST"),
            makeItem(method: "GET"),
            makeItem(method: "DELETE")
        ]
        let result = ChartParameter.build(items: items, key: \.method)

        #expect(result[0].stringValue == "DELETE")
        #expect(result[1].stringValue == "GET")
        #expect(result[2].stringValue == "POST")
    }

    // MARK: - Custom Key Function

    @Test("Works with closure key function")
    func testClosureKeyFunction() {
        let items = [
            makeItem(statusCode: 200),
            makeItem(statusCode: 200),
            makeItem(statusCode: 404)
        ]
        let result = ChartParameter.build(items: items, key: { "\($0.statusCode)" })

        #expect(result.count == 2)
        let code200 = result.first { $0.stringValue == "200" }
        let code404 = result.first { $0.stringValue == "404" }
        #expect(code200?.count == 2)
        #expect(code404?.count == 1)
    }

    // MARK: - Grouping by Host

    @Test("Grouping by host works correctly")
    func testGroupByHost() {
        let items = [
            makeItem(url: "https://example.com/api"),
            makeItem(url: "https://example.com/other"),
            makeItem(url: "https://test.com/data")
        ]
        let result = ChartParameter.build(items: items, key: \.host)

        #expect(result.count == 2)
        let example = result.first { $0.value == "example.com" }
        let test = result.first { $0.value == "test.com" }
        #expect(example?.count == 2)
        #expect(test?.count == 1)
    }

    // MARK: - ChartParameter Properties

    @Test("ChartParameter stringValue matches value description")
    func testChartParameterStringValue() {
        let param = ChartParameter(value: "GET", count: 5)
        #expect(param.stringValue == "GET")
        #expect(param.id == "GET")
        #expect(param.count == 5)
    }

    @Test("ChartParameter with integer value converts to string")
    func testChartParameterIntValue() {
        let param = ChartParameter(value: 200, count: 3)
        #expect(param.stringValue == "200")
        #expect(param.id == 200)
    }
}
