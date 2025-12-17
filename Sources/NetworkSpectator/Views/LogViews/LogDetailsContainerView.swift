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
    @State private var exportItem: ExportItem?
    @State private var isExporting: Bool = false

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
        VStack {
            Picker("", selection: $selected) {
                ForEach(availableTabs) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 8)

            ScrollView {
                detailsView(for: selected)
            }
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: exportAction) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export Log")
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
        .loadingOverlay(isPresented: isExporting, text: "Preparing")
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
    private func exportAction() {
        isExporting = true
        Task {
            do {
                let exportedURL = await try ExportManager.txt(item).exporter.export()
                exportItem = ExportItem(data: exportedURL)
            } catch {
                showAlert = true
            }
            isExporting = false
        }
    }
}
