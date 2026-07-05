//
//  LogListDataSource.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 04/07/26.
//

import Foundation

struct LogListDataSource {
    let filteredItems: [LogItem]
    let availableMethods: [String]
    let hasActiveFilters: Bool
    let normalizedSearchText: String

    var isSearchActive: Bool {
        !normalizedSearchText.isEmpty || hasActiveFilters
    }

    var requestCountText: String {
        "\(filteredItems.count) Request\(filteredItems.count == 1 ? "" : "s")"
    }

    var exportItems: [LogItem] {
        filteredItems
    }

    init(logItems: [LogItem],
         searchText: String,
         selectedMethods: Set<String>,
         selectedStatusCodes: Set<String>) {
        normalizedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        hasActiveFilters = !selectedMethods.isEmpty || !selectedStatusCodes.isEmpty
        availableMethods = Self.makeAvailableMethods(from: logItems)
        filteredItems = Self.makeFilteredItems(from: logItems,
                                               searchText: normalizedSearchText,
                                               selectedMethods: selectedMethods,
                                               selectedStatusCodes: selectedStatusCodes)
    }

    private static func makeAvailableMethods(from logItems: [LogItem]) -> [String] {
        Array(Set(logItems.map { $0.method.uppercased() })).sorted()
    }

    private static func makeFilteredItems(from logItems: [LogItem],
                                          searchText: String,
                                          selectedMethods: Set<String>,
                                          selectedStatusCodes: Set<String>) -> [LogItem] {
        var filtered = logItems

        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.url.localizedCaseInsensitiveContains(searchText) ||
                item.host.localizedCaseInsensitiveContains(searchText) ||
                item.method.localizedCaseInsensitiveContains(searchText)
            }
        }

        if !selectedMethods.isEmpty {
            filtered = filtered.filter { item in
                selectedMethods.contains(item.method.uppercased())
            }
        }

        if !selectedStatusCodes.isEmpty {
            filtered = filtered.filter { item in
                selectedStatusCodes.contains(item.statusCodeRange)
            }
        }

        return filtered
    }
}
