//
//  SkipLoggingManagementView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 27/02/26.
//

import SwiftUI

struct SkipLoggingManagementView: View {

    @State private var skipLogging: [ManageRuleItem] = []
    @State private var showAddSkipSheet = false
    @State private var editingSkipItem: AddRuleItem?

    var body: some View {
        List {
            if skipLogging.isEmpty {
                emptyStateView(
                    icon: "eye.slash",
                    title: "No Skip Rules",
                    message: "Add rules to exclude certain requests from being logged"
                )
            } else {
                ForEach(skipLogging) { item in
                    skipLoggingItemRow(item)
                }
                .onDelete { indexSet in
                    deleteSkipLogging(at: indexSet)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Skip Logging Rules")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSkipSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Skip Rule")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    loadData()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showAddSkipSheet) {
            AddRuleItemView(isMock: false, title: "Skip Logging")
                .onDisappear {
                    loadData()
                }
        }
        .sheet(item: $editingSkipItem) { item in
            AddRuleItemView(isMock: false, title: "Edit Skip Rule", item: item) {
                loadData()
            }
        }
    }

    private func skipLoggingItemRow(_ item: ManageRuleItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "minus.circle.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.body)
                    .lineLimit(2)

                Text("Excluded from logs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if let skipRequest = SkipRequestForLoggingHandler.shared.skipRequests.first(where: { $0.id == item.id }),
               let ruleItem = AddRuleItem(skipRequest: skipRequest) {
                editingSkipItem = ruleItem
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                if let index = skipLogging.firstIndex(where: { $0.id == item.id }) {
                    deleteSkipLogging(at: IndexSet(integer: index))
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func loadData() {
        withAnimation {
            skipLogging = SkipRequestForLoggingHandler.shared.skipRequests.map(ManageRuleItem.init(skipRequest:))
        }
    }

    private func deleteSkipLogging(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let id = skipLogging[index].id
        withAnimation {
            skipLogging.remove(atOffsets: indexSet)
        }
        SkipRequestForLoggingHandler.shared.remove(id: id)
    }
}
