//
//  LogsLandingView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct RootView: View {
    @ObservedObject private var store = NetworkLogManager.shared
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var navigationPath = NavigationPath()
    @State private var searchText = ""
    @State private var isSearching = false

    var items: [Binding<LogItem>] {
        if searchText.isEmpty {
            return Array($store.items)
        } else {
            return $store.items.filter { item in
                item.wrappedValue.url.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(items, id: \.id) { item in
                NavigationLink {
                    LogDetailsLandingView(item: item)
                } label: {
                    LogListItemView(item: item)
                }
                .listRowBackground(rowBackgroundColor(item.wrappedValue))
            }
            .listStyle(.plain)
            .searchable(text: $searchText,
                        isPresented: $isSearching,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search by URL")
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
                        exportData()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export")
                }
            }
            .sheet(isPresented: $showExportSheet, content: exportSheet)
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
            exportSheet()
        }
    }

    private func exportData() {
        exportURL = ExportManager.csv(store.items).exporter.export()
        //showExportSheet = true
        navigationPath.append("showExport")
    }

    @ViewBuilder
    private func exportSheet() -> some View {
        ExportOptionsView(url: exportURL) { type in
            
        } onCancel: {
            
        }
    }
}

#Preview {
    RootView()
}
