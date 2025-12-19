//
//  RootView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct ExportItem: Identifiable {
    let id: UUID = UUID()
    let data: Any
}

struct RootView: View {
    @ObservedObject private var store = NetworkLogManager.shared
    @State private var exportItem: ExportItem?
    @State private var showAlert: Bool = false
    @State private var navigationPath = NavigationPath()
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isExporting = false

    var items: [LogItem] {
        if searchText.isEmpty {
            return store.items
        } else {
            return store.items.filter { item in
                item.url.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(items) { item in
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
            .listStyle(.plain)
            #if os(iOS)
            .searchable(text: $searchText,
                        isPresented: $isSearching,
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
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        navigationPath.append(NavigationItem.settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        navigationPath.append(NavigationItem.analytics)
                    } label: {
                        Image(systemName: "chart.bar.xaxis.ascending")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        store.clear()
                    } label: {
                        Image(systemName: "clear")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        isExporting = true
                        Task {
                            do {
                                let url = try await ExportManager.csv(store.items).exporter.export()
                                exportItem = ExportItem(data: url)
                            } catch {
                                showAlert = true
                            }
                            isExporting = false
                        }
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .alert("Export failed", isPresented: $showAlert, actions: {
                Button("Ok") {
                    showAlert = false
                }
            })
            .popover(item: $exportItem) { item in
                ActivityView(item: item.data)
            }
            .loadingOverlay(isPresented: isExporting, text: "Preparing CSV")
            .navigationDestination(for: NavigationItem.self) { navigation in
                switch navigation {
                case .analytics:
                    AnalyticsDashboardView(data: store.items)
                case .settings:
                    SettingsView()
                    //Text("Settings navigation")
                }
            }
        }
    }
    
    func rowBackgroundColor(_ item: LogItem) -> Color {
        (item.errorDescription != nil) ? Color.red.opacity(0.1)
        : (item.isLoading ? Color.yellow.opacity(0.1) : Color.clear)
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

