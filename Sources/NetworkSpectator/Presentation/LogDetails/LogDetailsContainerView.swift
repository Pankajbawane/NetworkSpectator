//
//  LogDetailsContainerView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI
import NetworkSpectatorCore
import NetworkSpectatorLogging

struct LogDetailsContainerView: View {
    let initialItem: LogItem
    let isHistoricLogs: Bool

    @ObservedObject private var store = NetworkLogContainer.shared

    /// For live sessions, return the latest version from the store.
    /// For historic logs, return the snapshot passed in.
    private var item: LogItem {
        if !isHistoricLogs, let latestItem = store.latestItem(for: initialItem.id) {
            return latestItem
        }
        return initialItem
    }
    
    init(initialItem: LogItem, isHistoricLogs: Bool) {
        self.initialItem = initialItem
        self.isHistoricLogs = isHistoricLogs
    }

    // Stronger typing for picker selection
    enum DetailsTab: String, CaseIterable, Identifiable {
        case basic = "Overview"
        case request = "Request"
        case headers = "Headers"
        case response = "Response"
        case metrics = "Metrics"
        var id: String { rawValue }
    }

    @State private var selected: DetailsTab = .basic
    @State private var showAlert = false
    @State private var showAlertRuleAdded = false
    @State private var exportItem: ShareExportedItem?
    @State private var isExporting: Bool = false
    @State private var showExportFormatPicker = false
    @State private var showAddMockSheet = false
    @State private var showAddExclusionSheet = false

    enum ExportFormat: String, CaseIterable, Identifiable {
        case text = "Text"
        case csv = "CSV"
        case postmanCollection = "Postman Collection"
        var id: String { rawValue }
    }

    // Filtered picker options depending on item content
    private var availableTabs: [DetailsTab] {
        var tabs: [DetailsTab] = [.basic]
        if !item.requestBody.isEmpty {
            tabs.append(.request)
        }
        tabs.append(contentsOf: [.headers, .response])
        tabs.append(.metrics)
        return tabs
    }

    var body: some View {
        VStack(spacing: 0) {
            // For mocked response, show the info.
            if item.isMocked {
                HStack {
                    Image(systemName: "info.circle")
                    Text(isHistoricLogs ? "This response was mocked." : "This response is mocked. Tap Mock to edit or disable the rule.")
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
            Picker("", selection: $selected) {
                ForEach(availableTabs) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)

            detailsView(for: selected)
                .padding(.top, 12)
                .transition(.opacity)
                .background(Color(.systemGray).opacity(0.2))
        }
        .navigationTitle("Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showAddMockSheet) {
            var ruleItem = AddRuleItem(id: UUID(),
                                       text: item.url,
                                       statusCode: "\(item.statusCode)",
                                       rule: .url,
                                       isMock: true)
            if let mockId = item.mockId {
                if let mock = MockServer.shared.mocks.first(where:  { $0.id == mockId }) {
                    if let item = AddRuleItem(mock: mock) {
                        ruleItem = item
                    }
                }
            }
            return AddRuleItemView(isMock: true, title: item.isMocked ? "Update Mock" : "Add Mock", item: ruleItem) {
                showAlertRuleAdded = true
            }
        }
        .sheet(isPresented: $showAddExclusionSheet) {
            var rule = AddRuleItem(id: item.id,
                                   text: item.url,
                                   rule: .url,
                                   isMock: false)
            let exclusion = LoggingExclusionManager.shared.rules.first(where:  { $0.id == item.id })
            if let exclusion, let item = AddRuleItem(exclusion: exclusion) {
                rule = item
            }
            
            return AddRuleItemView(isMock: false, title: "Exclude Logging", item: rule) {
                showAlertRuleAdded = true
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if !isHistoricLogs {
                    // CTA to register mock.
                    Button(action: { showAddMockSheet = true }) {
                        Label("Mock", systemImage: item.isMocked ? "theatermasks.fill" : "theatermasks")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(7)
                    }
                    .tint(item.isMocked ? .green : .primary)
                    .accessibilityLabel("Mock")
                    
                    // CTA to ignore requests from logging.
                    Button(action: { showAddExclusionSheet = true }) {
                        Label("Exclude Logging", systemImage: "text.badge.minus")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(7)
                    }
                    .accessibilityLabel("Exclude Logging")
                }
                
                Button(action: { showExportFormatPicker = true }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Export Log")
            }
        }
        .alert("Export Failed", isPresented: $showAlert, actions: {
            Button("OK") {
                showAlert = false
            }
        }, message: {
            Text("Unable to export the log. Please try again.")
        })
        .alert("Rules updated", isPresented: $showAlertRuleAdded, actions: {
            Button("OK") {
                showAlertRuleAdded = false
            }
        }, message: {
            Text("Rule updated successfully and will be applied from the next HTTP requests.")
        })
        .confirmationDialog("Select Export Format",
                            isPresented: $showExportFormatPicker,
                            titleVisibility: .visible) {
            ForEach(ExportFormat.allCases) { format in
                Button(format.rawValue) {
                    exportAction(format: format)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose a format to export this network log")
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
        .loadingOverlay(isPresented: isExporting, text: "Preparing export...")
    }

    // Extracted view builder for each tab
    @ViewBuilder
    private func detailsView(for tab: DetailsTab) -> some View {
        switch tab {
        case .basic:
            LogBasicDetailsView(item: item)
        case .request:
            LogRequestDetailsView(item: item)
        case .headers:
            LogHeadersDetailsView(item: item)
        case .response:
            LogResponseDetailsView(item: item)
        case .metrics:
            LogMetricsView(item: item)
        }
    }

    // Helper function for export
    private func exportAction(format: ExportFormat) {
        isExporting = true
        Task {
            do {
                let exportedURL: URL
                switch format {
                case .text:
                    exportedURL = try await ExportManager.txt(item).exporter.export()
                case .csv:
                    exportedURL = try await ExportManager.csv([item]).exporter.export()
                case .postmanCollection:
                    exportedURL = try await ExportManager.postman(item).exporter.export()
                }
                exportItem = ShareExportedItem(data: exportedURL)
            } catch {
                showAlert = true
            }
            isExporting = false
        }
    }
}
