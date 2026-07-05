//
//  LogListView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 10/03/26.
//

import SwiftUI
import NetworkSpectatorCore
import NetworkSpectatorLogging
import NetworkSpectatorExport

struct LogListView: View {
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

    var body: some View {
        let dataSource = LogListDataSource(logItems: logItems,
                                               searchText: searchText,
                                               selectedMethods: selectedMethods,
                                               selectedStatusCodes: selectedStatusCodes)

        ZStack {
            if dataSource.filteredItems.isEmpty {
                EmptyStateView(
                    isSearchActive: dataSource.isSearchActive,
                    searchText: dataSource.normalizedSearchText
                )
            } else {
                logListView(dataSource: dataSource)
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
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { toolbarContent(dataSource: dataSource) }
        .alert("Export failed", isPresented: $showAlert, actions: {
            Button("OK") {
                showAlert = false
            }
        })
        .alert("Clear All Requests", isPresented: $showClearAlert) {
            Button("Clear", role: .destructive) {
                Task { await NetworkLogMonitor.shared.clear() }
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
                availableMethods: dataSource.availableMethods
            )
        }
    }

    // MARK: - Subviews

    private func logListView(dataSource: LogListDataSource) -> some View {
        List {
            if dataSource.hasActiveFilters {
                Section {
                    FilterChipsView(
                        selectedMethods: $selectedMethods,
                        selectedStatusCategories: $selectedStatusCodes
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section {
                ForEach(dataSource.filteredItems) { item in
                    NavigationLink(value: NavigationRoute.logDetail(item, isHistoricLogs: isHistoricLogs)) {
                        LogListItemView(item: item)
                    }
                    .listRowBackground(rowBackgroundColor(item))
                }
            } header: {
                HStack {
                    Text(dataSource.requestCountText)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
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

    @ToolbarContentBuilder
    private func toolbarContent(dataSource: LogListDataSource) -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            filterButton(dataSource: dataSource)

            if isHistoricLogs {
                NavigationLink(value: NavigationRoute.insights(logItems)) {
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

            exportButton(dataSource: dataSource)

            if !isHistoricLogs {
                NavigationLink(value: NavigationRoute.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Tools")
            }
        }
    }

    private func filterButton(dataSource: LogListDataSource) -> some View {
        Button {
            showFilterSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if dataSource.hasActiveFilters {
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

    private func exportButton(dataSource: LogListDataSource) -> some View {
        Button {
            export(dataSource.exportItems)
        } label: {
            if isExporting {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .accessibilityLabel("Export requests")
        .disabled(isExporting || dataSource.exportItems.isEmpty)
    }

    private func export(_ items: [LogItem]) {
        isExporting = true
        Task {
            do {
                let url = try await ExportManager.csv(items).exporter.export()
                exportItem = ShareExportedItem(data: url)
            } catch {
                showAlert = true
            }
            isExporting = false
        }
    }

    private func rowBackgroundColor(_ item: LogItem) -> Color {
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
extension LogListView {
    enum NavigationRoute: Hashable {
        case logDetail(LogItem, isHistoricLogs: Bool)
        case settings
        case insights([LogItem])
    }
}
