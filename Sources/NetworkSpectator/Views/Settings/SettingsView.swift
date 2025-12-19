//
//  SettingsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import SwiftUI

struct SettingsView: View {
    
    struct Item: Identifiable {
        let id: UUID
        let text: String
        
        init(id: UUID, text: String) {
            self.id = id
            self.text = text
        }
        
        init(mock: Mock) {
            id = mock.id
            text = mock.rules?.first?.ruleName ?? "Rule NA"
        }
        
        init(skipRequest: SkipRequestForLogging) {
            id = skipRequest.id
            text = skipRequest.rules.first?.ruleName ?? "Rule NA"
        }
    }
    
    @State private var mocks: [Item] = []
    @State private var skipLogging: [Item] = []

    @State private var showAddMockSheet = false
    @State private var showAddSkipSheet = false

    var body: some View {
        List {
            Section(header: sectionHeader(title: "Mocks", addAction: { showAddMockSheet = true })) {
                if mocks.isEmpty {
                    emptyRow(text: "No mocks added yet")
                }
                ForEach(mocks, id: \.id) { item in
                    Text(item.text)
                        .font(Font.caption.bold())
                }
                .onDelete { indexSet in
                    guard let index = indexSet.first else { return }
                    let id = mocks[index].id
                    mocks.remove(atOffsets: indexSet)
                    MockServer.shared.remove(id: id)
                }
            }
            
            Section(header: sectionHeader(title: "Skip Logging", addAction: { showAddSkipSheet = true })) {
                if skipLogging.isEmpty {
                    emptyRow(text: "No skip rules yet")
                }
                ForEach(skipLogging, id: \.id) { item in
                    Text(item.text)
                        .font(Font.caption.bold())
                }
                .onDelete { indexSet in
                    guard let index = indexSet.first else { return }
                    let id = skipLogging[index].id
                    skipLogging.remove(atOffsets: indexSet)
                    SkipRequestForLoggingHandler.shared.remove(id: id)
                }
            }
        }
        .onAppear {
            mocks = MockServer.shared.mocks.map { Item(mock: $0) }
            skipLogging = SkipRequestForLoggingHandler.shared.skipRequests.map(Item.init(skipRequest:))
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showAddMockSheet) {
            AddRuleItemView(isMock: true, title: "Add Mock")
        }
        .sheet(isPresented: $showAddSkipSheet) {
            AddRuleItemView(isMock: false, title: "Skip Logging")
        }
    }

    private func sectionHeader(title: String, addAction: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: addAction) {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(title)")
        }
    }

    @ViewBuilder
    private func emptyRow(text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
    }
}
