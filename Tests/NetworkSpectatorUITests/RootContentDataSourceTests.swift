//
//  RootContentDataSourceTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 04/07/26.
//

import Testing
@testable import NetworkSpectatorCore
@testable import NetworkSpectatorUI

@Suite("RootContentDataSource Tests")
struct RootContentDataSourceTests {

    @Test("Available methods are unique uppercase values sorted alphabetically")
    func availableMethodsAreUniqueAndSorted() {
        let dataSource = LogListDataSource(logItems: [
            makeItem(method: "post"),
            makeItem(method: "GET"),
            makeItem(method: "get")
        ], searchText: "", selectedMethods: [], selectedStatusCodes: [])

        #expect(dataSource.availableMethods == ["GET", "POST"])
    }

    @Test("Search text is trimmed before filtering and empty-state display")
    func searchTextIsTrimmedBeforeFiltering() {
        let dataSource = LogListDataSource(logItems: [
            makeItem(url: "https://api.example.com/users", method: "GET"),
            makeItem(url: "https://cdn.example.com/assets", method: "GET")
        ], searchText: "  users  ", selectedMethods: [], selectedStatusCodes: [])

        #expect(dataSource.normalizedSearchText == "users")
        #expect(dataSource.isSearchActive)
        #expect(dataSource.filteredItems.map(\.url) == ["https://api.example.com/users"])
    }

    @Test("Whitespace-only search does not activate search filtering")
    func whitespaceOnlySearchIsIgnored() {
        let items = [
            makeItem(url: "https://api.example.com/users"),
            makeItem(url: "https://cdn.example.com/assets")
        ]
        let dataSource = LogListDataSource(logItems: items,
                                               searchText: "   ",
                                               selectedMethods: [],
                                               selectedStatusCodes: [])

        #expect(dataSource.normalizedSearchText.isEmpty)
        #expect(!dataSource.isSearchActive)
        #expect(dataSource.filteredItems == items)
    }

    @Test("Method and status filters are applied together")
    func methodAndStatusFiltersAreAppliedTogether() {
        let getSuccess = makeItem(url: "https://example.com/success", method: "GET", statusCode: 200)
        let getFailure = makeItem(url: "https://example.com/failure", method: "GET", statusCode: 500)
        let postSuccess = makeItem(url: "https://example.com/create", method: "POST", statusCode: 201)

        let dataSource = LogListDataSource(logItems: [getSuccess, getFailure, postSuccess],
                                               searchText: "",
                                               selectedMethods: ["GET"],
                                               selectedStatusCodes: ["200..<300"])

        #expect(dataSource.hasActiveFilters)
        #expect(dataSource.isSearchActive)
        #expect(dataSource.filteredItems == [getSuccess])
    }

    @Test("Request count text and export items use filtered items")
    func requestCountTextAndExportItemsUseFilteredItems() {
        let first = makeItem(url: "https://example.com/users", method: "GET")
        let second = makeItem(url: "https://example.com/orders", method: "POST")

        let dataSource = LogListDataSource(logItems: [first, second],
                                               searchText: "users",
                                               selectedMethods: [],
                                               selectedStatusCodes: [])

        #expect(dataSource.requestCountText == "1 Request")
        #expect(dataSource.exportItems == [first])
    }

    private func makeItem(url: String = "https://example.com/api",
                          method: String = "GET",
                          statusCode: Int = 200) -> LogItem {
        LogItem(url: url, method: method, statusCode: statusCode)
    }
}
