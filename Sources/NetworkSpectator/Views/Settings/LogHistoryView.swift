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
    @State var showDeleteAllAlert = false
    
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
                        Text(historyToggle ? "History is enabled" : "Enable history")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(historyToggle ? .green : .primary)
                        Spacer()
                    }
                }
                #if os(macOS)
                .toggleStyle(SwitchToggleStyle())
                #endif
                if !logs.isEmpty {
                    HStack {
                        Text("Items: \(logs.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospaced(true)
                        
                        Text("Size: \(totalSize)")
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
                } else if logs.isEmpty {
                    emptyState(icon: "exclamationmark.arrow.trianglehead.counterclockwise.rotate.90",
                               title: "No history",
                               message: "Historical logs will be stored when History is enabled. You can view stored logs here.")
                } else {
                    listView
                }
            } header: {
                if !logs.isEmpty {
                    HStack {
                        Spacer()
                        Text("Swipe right to left to delete")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .toolbar {
            if !logs.isEmpty {
                ToolbarItem {
                    Button("Delete all") {
                        showDeleteAllAlert.toggle()
                    }
                    .tint(.red)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 5)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle("Log History")
        .navigationDestination(for: LogHistoryRoute.self) { route in
            let items = storage.retrieve(forKey: route.key)
            
            RootContentView(
                logItems: items,
                isHistoricLogs: true,
                title: route.title
            )
        }
        .alert("Delete all", isPresented: $showDeleteAllAlert) {
            Button("Delete", role: .destructive) {
                storage.clearAll()
                logs = storage.listKeys()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete all historical logs?\nThis action cannot be undone.")
        }
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
        let timestamp = (runningKey ?? "").split(separator: "|").first ?? "-"
        let firstTimestamp = logs.first?.startTimestamp ?? ""
        if !logs.isEmpty, timestamp == firstTimestamp {
            // Current session logs will always be on top.
            logs[0].isCurrentSession = true
        }
        
        await MainActor.run {
            self.logs = logs
            self.totalSize = totalSizeFormatted
            loading = false
        }
    }
    
    var listView: some View {
        ForEach(logs, id: \.key) { log in
            Group {
                if log.isCurrentSession {
                    listItemRow(log)
                } else {
                    NavigationLink(value: LogHistoryRoute(key: log.key,
                                                          title: log.shortTitle,
                                                          isLiveSession: log.isCurrentSession)) {
                        listItemRow(log)
                    }
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if !log.isCurrentSession {
                    Button(role: .destructive) {
                        storage.delete(forKey: log.key)
                        logs.removeAll { $0.key == log.key }
                        totalSize = formatBytes(logs.reduce(0) { $0 + $1.size })
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }
    
    @ViewBuilder
    private func listItemRow(_ log: HistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            
            if log.isCurrentSession {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    
                    Text(log.shortTitle + " (Current Session)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label(log.formattedTitle, systemImage: "clock")
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
    }
    
    private func formatBytes(_ byteCount: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useBytes]
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(byteCount))
    }
}

// MARK: - Navigation
extension LogHistoryView {
    struct LogHistoryRoute: Hashable {
        let key: String
        let title: String
        let isLiveSession: Bool
    }
}
