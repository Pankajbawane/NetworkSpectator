//
//  LogHistoryView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 03/03/26.
//

import SwiftUI

struct LogHistoryView: View {
    
    let storage: LogHistoryStorage
    let preference: PreferenceStorage
    @State var logs: [HistoryItem] = []
    @State var presentSheet: Bool = false
    @State var historyToggle: Bool
    @State var loading: Bool = true
    @State var totalSize: String = ""
    
    init() {
        storage = LogHistoryStorage()
        preference = PreferenceStorage(preference: .history)
        historyToggle = preference.retrieve(true)
    }
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: $historyToggle) {
                    HStack {
                        Text("History is \(historyToggle ? "enabled" : "disabled")")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(historyToggle ? .green : .red)
                        Spacer()
                    }
                }
                #if os(macOS)
                .toggleStyle(SwitchToggleStyle())
                #endif
                if !totalSize.isEmpty {
                    HStack {
                        Text("Total size: \(totalSize)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospaced(true)
                    }
                }
            }
            
            Section {
                if loading {
                    HStack {
                        Spacer()
                        ProgressView("Loading...")
                        Spacer()
                    }
                } else {
                    listView
                }
            }
        }
        .toolbar {
            if !logs.isEmpty {
                ToolbarItem {
                    Button("Delete all") {
                        storage.clearAll()
                        logs = storage.listKeys()
                    }
                    .tint(.red)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 5)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle(Text("Log History"))
        .onChange(of: historyToggle) { toggle in
            // Change history logging preference.
            preference.save(toggle)
            Task {
                if toggle {
                    await LogHistoryManager.shared.startObserving()
                } else {
                    await LogHistoryManager.shared.finalizeAndStopObserving()
                }
            }
        }
        .task {
            loading = true
            await loadData()
        }
    }
    
    func loadData() async {
        var logs = storage.listKeys()
        let totalSize = logs.reduce(0) { $0 + $1.size }
        let totalSizeFormatted = formatBytes(totalSize)
        let runningKey = await LogHistoryManager.shared.currentSessionKey()
        let timestamp = (runningKey ?? "").split(separator: " - ").first ?? "-"
        let firstTimestamp = (logs.first?.timestamp ?? "").split(separator: " - ").first ?? "+"
        if !logs.isEmpty, timestamp == firstTimestamp {
            logs[0].isCurrentSession = true
        }
        
        await MainActor.run {
            self.logs = logs
            self.totalSize = totalSizeFormatted
            loading = false
        }
    }
    
    @ViewBuilder
    var listView: some View {
        ForEach(logs, id: \.key) { log in
            NavigationLink {
                let items = storage.retrieve(forKey: log.key)
                RootContentView(logItems: items, isHistoricLogs: true, title: log.key)
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    
                    if log.isCurrentSession {
                        HStack {
                            ProgressView()
                                .frame(width: 20, height: 20)
                            Text("Current Session")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Label(log.timestamp, systemImage: "clock")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    
                    HStack(spacing: 8) {
                        Label(log.count, systemImage: "square.stack.3d.up.fill")
                        
                        Label("Size: " + formatBytes(log.size), systemImage: "arrow.down.circle")
                        
                        Spacer()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 5)
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }
    
    private func formatBytes(_ byteCount: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useBytes]
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(byteCount))
    }
}
