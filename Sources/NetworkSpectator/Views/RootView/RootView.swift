//
//  RootView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct RootView: View {
    @ObservedObject private var store = NetworkLogContainer.shared
    @State private var exportItem: ShareExportedItem?
    @State private var showAlert: Bool = false
    @State private var navigationPath = NavigationPath()
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isExporting = false
    @State private var selectedMethods: Set<String> = []
    @State private var selectedStatusCategories: Set<String> = []
    @State private var selectedStatusCodes: Set<String> = []
    @State private var showFilterSheet = false

    var items: [LogItem] {
        var filtered = store.items

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

        // Apply status category filter
        if !selectedStatusCategories.isEmpty {
            filtered = filtered.filter { item in
                selectedStatusCategories.contains(item.statusCategory)
            }
        }

        return filtered
    }

    var availableMethods: [String] {
        Array(Set(store.items.map { $0.method.uppercased() })).sorted()
    }

    var hasActiveFilters: Bool {
        !selectedMethods.isEmpty || !selectedStatusCategories.isEmpty
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                if items.isEmpty {
                    EmptyStateView(
                        isSearchActive: !searchText.isEmpty || hasActiveFilters,
                        searchText: searchText
                    )
                } else {
                    List {
                        // Filter chips section
                        if hasActiveFilters {
                            Section {
                                FilterChipsView(
                                    selectedMethods: $selectedMethods,
                                    selectedStatusCategories: $selectedStatusCategories
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }

                        // Requests list
                        Section {
                            ForEach(items) { item in
                                NavigationLink {
                                    // Find the binding for this specific item in the store
                                    if let index = store.items.firstIndex(where: { $0.id == item.id }) {
                                        LogDetailsContainerView(item: $store.items[index])
                                    }
                                } label: {
                                    LogListItemView(item: item)
                                }
                                .listRowBackground(rowBackgroundColor(item))
                            }
                        } header: {
                            if !items.isEmpty {
                                HStack {
                                    Text("\(items.count) Request\(items.count == 1 ? "" : "s")")
                                        .font(.caption)
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
            }
            #if os(iOS)
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search by URL")
            #endif
            #if os(macOS)
            .searchable(text: $searchText, placement: .automatic, prompt: "Search by URL")
            #endif
            .navigationTitle("Requests")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                /*
                #if os(iOS)
                // Leading items - iOS only
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    // Request count badge
                    if !store.items.isEmpty {
                        Text("\(store.items.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                #endif
                 */

                // Trailing items
                ToolbarItemGroup(placement: .automatic) {
                    /*
                    #if os(macOS)
                    // Request count badge for macOS
                    if !store.items.isEmpty {
                        Text("\(store.items.count) requests")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    #endif
                     */

                    // Filter button
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
                    .disabled(store.items.isEmpty)

                    // Analytics button
                    Button {
                        navigationPath.append(NavigationItem.analytics)
                    } label: {
                        Image(systemName: "chart.bar.xaxis.ascending")
                    }
                    .accessibilityLabel("View analytics")
                    .disabled(store.items.isEmpty)

                    // Export button
                    Button {
                        isExporting = true
                        Task {
                            do {
                                let url = try await ExportManager.csv(store.items).exporter.export()
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
                    .disabled(isExporting || store.items.isEmpty)

                    // Clear button
                    Button {
                        store.clear()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Clear all requests")
                    .disabled(store.items.isEmpty)

                    // Settings button
                    Button {
                        navigationPath.append(NavigationItem.settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .alert("Export failed", isPresented: $showAlert, actions: {
                Button("Ok") {
                    showAlert = false
                }
            })
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
            .navigationDestination(for: NavigationItem.self) { navigation in
                switch navigation {
                case .analytics:
                    AnalyticsDashboardView(data: store.items)
                case .settings:
                    SettingsView()
                }
            }
        }
    }
    
    func rowBackgroundColor(_ item: LogItem) -> Color {
        // Priority: Error > Loading > Status code based
        if item.errorDescription != nil {
            return Color.red.opacity(0.08)
        }

        if item.isLoading {
            return Color.blue.opacity(0.05)
        }
        
        return .clear

        // Status code based coloring
        switch item.statusCode {
        case 200..<300:
            return Color.green.opacity(0.03)
        case 300..<400:
            return Color.yellow.opacity(0.05)
        case 400..<500:
            return Color.orange.opacity(0.05)
        case 500..<600:
            return Color.red.opacity(0.08)
        default:
            return Color.clear
        }
    }
}

extension RootView {
    enum NavigationItem: String {
        case analytics
        case settings
    }
}

#Preview {
    RootView()
}

