//
//  RootContentView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 10/03/26.
//

import SwiftUI

struct RootContentView: View {
    @State private var exportItem: ShareExportedItem?
    @State private var showAlert: Bool = false
    @State private var searchText = ""
    @State private var isExporting = false
    @State private var selectedMethods: Set<String> = []
    @State private var selectedStatusCodes: Set<String> = []
    @State private var showFilterSheet = false
    @State private var showClearAlert = false

    let logItems: [LogItem]
    let title: String
    let isHistoricLogs: Bool

    init(logItems: [LogItem],
         isHistoricLogs: Bool = false,
         title: String = "NetworkSpectator") {
        self.logItems = logItems
        self.isHistoricLogs = isHistoricLogs
        self.title = title
    }

    var items: [LogItem] {
        var filtered: [LogItem] = logItems

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.url.localizedCaseInsensitiveContains(searchText) ||
                item.host.localizedCaseInsensitiveContains(searchText) ||
                item.method.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply method filter
        if !selectedMethods.isEmpty {
            filtered = filtered.filter { item in
                selectedMethods.contains(item.method.uppercased())
            }
        }

        // Apply status code range filter
        if !selectedStatusCodes.isEmpty {
            filtered = filtered.filter { item in
                selectedStatusCodes.contains(item.statusCodeRange)
            }
        }

        return filtered
    }

    var availableMethods: [String] {
        Array(Set(logItems.map { $0.method.uppercased() })).sorted()
    }

    var hasActiveFilters: Bool {
        !selectedMethods.isEmpty || !selectedStatusCodes.isEmpty
    }

    var body: some View {
        ZStack {
            if items.isEmpty {
                EmptyStateView(
                    isSearchActive: !searchText.isEmpty || hasActiveFilters,
                    searchText: searchText
                )
            } else {
                logListView
            }
        }
        #if os(iOS)
        .searchable(text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: "Search by URL")
        #endif
        #if os(macOS)
        .searchable(text: $searchText, placement: .automatic, prompt: "Search by URL")
        #endif
        .navigationDestination(for: RootContentRoute.self) { route in
            destinationView(for: route)
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { toolbarContent }
        .alert("Export failed", isPresented: $showAlert, actions: {
            Button("Ok") {
                showAlert = false
            }
        })
        .alert("Clear All Requests", isPresented: $showClearAlert) {
            Button("Clear", role: .destructive) {
                NetworkLogContainer.shared.clear()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to clear all logged requests?\nLogs are stored when history is enabled and can be viewed later.")
        }
        #if canImport(UIKit)
        .popover(item: $exportItem) { item in
            ShareActivityView(item: item.data)
        }
        #elseif canImport(AppKit)
        .macOSShareSheet(item: $exportItem) { item in
            item.data
        }
        #endif
        .loadingOverlay(isPresented: isExporting, text: "Preparing CSV")
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(
                selectedMethods: $selectedMethods,
                selectedStatusCodeCategory: $selectedStatusCodes,
                availableMethods: availableMethods
            )
        }
    }

    // MARK: - Subviews

    private var logListView: some View {
        List {
            // Filter chips section
            if hasActiveFilters {
                Section {
                    FilterChipsView(
                        selectedMethods: $selectedMethods,
                        selectedStatusCategories: $selectedStatusCodes
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Requests list
            Section {
                ForEach(items) { item in
                    NavigationLink(value: RootContentRoute.logDetail(item, isHistoricLogs: isHistoricLogs)) {
                        LogListItemView(item: item)
                    }
                    .listRowBackground(rowBackgroundColor(item))
                }
            } header: {
                if !items.isEmpty {
                    HStack {
                        Text("\(items.count) Request\(items.count == 1 ? "" : "s")")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        #if os(macOS)
        .listStyle(.inset)
        #endif
    }

    @ViewBuilder
    private func destinationView(for route: RootContentRoute) -> some View {
        switch route {
        case .logDetail(let item, let isHistoric):
            LogDetailsContainerView(initialItem: item, isHistoricLogs: isHistoric)
        case .settings:
            SettingsView()
        case .insights(let data):
            AnalyticsDashboardView(items: data)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            filterButton

            if isHistoricLogs {
                NavigationLink(value: RootContentRoute.insights(logItems)) {
                    Image(systemName: "chart.bar.xaxis.ascending")
                }
                .accessibilityLabel("Insights")
                .disabled(logItems.isEmpty)
            }

            if !isHistoricLogs {
                Button {
                    showClearAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Clear all requests")
                .disabled(logItems.isEmpty)
            }

            exportButton

            if !isHistoricLogs {
                NavigationLink(value: RootContentRoute.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Tools")
            }
        }
    }

    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if hasActiveFilters {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -4)
                }
            }
        }
        .accessibilityLabel("Filter requests")
        .disabled(logItems.isEmpty)
    }

    private var exportButton: some View {
        Button {
            isExporting = true
            Task {
                do {
                    let url = try await ExportManager.csv(logItems).exporter.export()
                    exportItem = ShareExportedItem(data: url)
                } catch {
                    showAlert = true
                }
                isExporting = false
            }
        } label: {
            if isExporting {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .accessibilityLabel("Export requests")
        .disabled(isExporting || logItems.isEmpty)
    }

    func rowBackgroundColor(_ item: LogItem) -> Color {
        // Priority: Error > Loading > Status code based
        if item.errorDescription != nil {
            return Color.red.opacity(0.08)
        }

        if item.isLoading {
            return Color.yellow.opacity(0.1)
        }

        return .clear
    }
}

// MARK: - Navigation
extension RootContentView {
    enum RootContentRoute: Hashable {
        case logDetail(LogItem, isHistoricLogs: Bool)
        case settings
        case insights([LogItem])
    }
}
