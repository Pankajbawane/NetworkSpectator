//
//  LogDetailsContainerView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogDetailsContainerView: View {
    @Binding var item: LogItem

    // Stronger typing for picker selection
    enum DetailsTab: String, CaseIterable, Identifiable {
        case basic = "Basic"
        case request = "Request"
        case headers = "Headers"
        case response = "Response"
        var id: String { rawValue }
    }

    @State private var selected: DetailsTab = .basic
    @State private var showAlert = false
    @State private var exportItem: ShareExportedItem?
    @State private var isExporting: Bool = false
    @State private var showExportFormatPicker = false
    @State private var showAddMockSheet = false
    @State private var showAddSkipSheet = false

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
        return tabs
    }

    var body: some View {
        VStack(spacing: 0) {
            // For mocked response, show the info.
            if item.isMocked {
                HStack {
                    Image(systemName: "info.circle")
                    Text("Mocked response. Use the Mock button to update or disable.")
                        .font(.caption)
                    Spacer()
                }
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
            let rule = AddRuleItem(id: item.id,
                                   text: item.url,
                                   statusCode: "\(item.statusCode)",
                                   rule: .url,
                                   isMock: true)
            return AddRuleItemView(isMock: true, title: item.isMocked ? "Update Mock" : "Add Mock", item: rule)
        }
        .sheet(isPresented: $showAddSkipSheet) {
            let rule = AddRuleItem(id: item.id,
                                   text: item.url,
                                   rule: .url,
                                   isMock: false)
            AddRuleItemView(isMock: false, title: "Skip Logging", item: rule)
        }
        .toolbar {
            
            ToolbarItemGroup(placement: .automatic) {
                // CTA to register mock.
                Button(action: { showAddMockSheet = true }) {
                    Label("Mock", systemImage: "shuffle")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(7)
                }
                .tint(item.isMocked ? .green : .primary)
                .accessibilityLabel("Mock")
                
                // CTA to ignore requests from logging.
                Button(action: { showAddSkipSheet = true }) {
                    Label("Skip Log", systemImage: "eye.slash")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(7)
                }
                .accessibilityLabel("Skip Logging")
                
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
            LogBasicDetailsView(item: $item)
        case .request:
            LogRequestDetailsView(item: $item)
        case .headers:
            LogHeadersDetailsView(item: $item)
        case .response:
            LogResponseDetailsView(item: $item)
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
