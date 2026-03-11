//
//  LogHistoryView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 03/03/26.
//

import SwiftUI

struct LogHistoryView: View {
    
    let storage: LogHistoryStorage
    @State var logs: [HistoryItem]
    @State var presentSheet: Bool = false
    @State var historyToggle = false
    
    init() {
        storage = LogHistoryStorage()
        logs = storage.listKeys()
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
            }
            
            
            ForEach(logs, id: \.key) { log in
                NavigationLink {
                    let items = storage.retrieve(forKey: log.key)
                    RootContentView(logItems: items, isHistoricLogs: true, title: log.key)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Label(log.timestamp, systemImage: "clock")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
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
        }
    }
    
    private func formatBytes(_ byteCount: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useBytes]
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(byteCount))
    }
}
