//
//  LogsLandingView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject private var manager = NetworkLogManager.shared
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var navigationPath = NavigationPath()
    @State private var logItems: [LogItem] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            itemList
                .navigationTitle("Requests")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: String.self,
                                       destination: analyticsNavigationDestination)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Analytics") {
                            navigationPath.append("analytics")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            exportData()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Export")
                    }
                }
                .sheet(isPresented: $showExportSheet, content: exportSheet)
                //.fullScreenCover(isPresented: $showExportSheet, content: exportSheet)
                .task {
                    logItems = manager.items
                }
        }
    }

    private var itemList: some View {
        List($logItems, id: \.id) { item in
            NavigationLink {
                LogDetailsLandingView(item: item)
            } label: {
                LogListItemView(item: item)
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func analyticsNavigationDestination(_ path: String) -> some View {
        if path == "analytics" {
            AnalyticsDashboardView(data: manager.items)
        } else if path == "showExport" {
            exportSheet()
        }
    }

    private func exportData() {
        exportURL = ExportManager.csv(manager.items).exporter.export()
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
    ContentView()
}
