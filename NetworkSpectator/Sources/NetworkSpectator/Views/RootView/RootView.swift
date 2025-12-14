//
//  RootView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

struct ExportItem: Identifiable {
    let id: UUID
    let data: Any
}

import SwiftUI

struct RootView: View {
    @ObservedObject private var store = NetworkLogManager.shared
    @State private var exportItem: ExportItem?
    @State private var navigationPath = NavigationPath()
    @State private var searchText = ""
    @State private var isSearching = false

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
            // TO DO: update search items.
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
            .navigationDestination(for: String.self,
                                   destination: analyticsNavigationDestination)
            .toolbar {
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        navigationPath.append("analytics")
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
                        Task {
                            do {
                                let url = await try ExportManager.csv(store.items).exporter.export()
                                exportItem = ExportItem(id: UUID(), data: url)
                            } catch {
                                
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export")
                }
            }
            .sheet(item: $exportItem) { item in
                ActivityView(item: item.data)
            }
        }
    }
    
    func rowBackgroundColor(_ item: LogItem) -> Color {
        (item.errorDescription != nil) ? Color.red.opacity(0.1)
        : (item.isLoading ? Color.yellow.opacity(0.1) : Color.clear)
    }

    @ViewBuilder
    private func analyticsNavigationDestination(_ path: String) -> some View {
        if path == "analytics" {
            AnalyticsDashboardView(data: store.items)
        } else if path == "showExport" {
            //let exportedCSV = ExportManager.csv(store.items).exporter.export()
            //ActivityView(item: exportedCSV)
        }
    }

    @ViewBuilder
    private func exportSheet() -> some View {
//        ExportOptionsView(url: exportURL) { type in
//            
//        } onCancel: {
//            
//        }
    }
}

extension RootView {
    enum Navigation: Hashable {
        case analytics
        case export
        case clear
    }
}

#Preview {
    RootView()
}
