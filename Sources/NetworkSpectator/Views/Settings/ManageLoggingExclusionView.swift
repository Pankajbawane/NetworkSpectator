//
//  ManageLoggingExclusionView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 27/02/26.
//

import SwiftUI

struct ManageLoggingExclusionView: View {

    @State private var rules: [LoggingExclusionRule] = []
    @State private var showAddRuleSheet = false
    @State private var itemBeingUpdated: AddRuleItem?

    var onDataChanged: (() -> Void)?

    var body: some View {
        List {
            if rules.isEmpty {
                    emptyState(
                        icon: "text.badge.minus",
                        title: "No Exclusion Rules",
                        message: "Add rules to exclude certain requests from being logged"
                    )
            } else {
                ForEach(rules) { item in
                    exclusionItemRow(item)
                }
                .onDelete { indexSet in
                    deleteExclusion(at: indexSet)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Logging Exclusion Rules")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddRuleSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Exclusion Rule")
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showAddRuleSheet) {
            AddRuleItemView(isMock: false, title: "Logging Exclusion")
                .onDisappear {
                    loadData()
                }
        }
        .sheet(item: $itemBeingUpdated) { item in
            AddRuleItemView(isMock: false, title: "Edit Exclusion Rule", item: item) {
                loadData()
            }.onDisappear {
                loadData()
            }
        }
    }

    private func exclusionItemRow(_ item: LoggingExclusionRule) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.rule.ruleName)
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
            if let item = LoggingExclusionManager.shared.rules.first(where: { $0.id == item.id }),
               let ruleItem = AddRuleItem(exclusion: item) {
                itemBeingUpdated = ruleItem
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                if let index = rules.firstIndex(where: { $0.id == item.id }) {
                    deleteExclusion(at: IndexSet(integer: index))
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func loadData() {
        withAnimation {
            rules = LoggingExclusionManager.shared.rules.map { $0 }
        }
        onDataChanged?()
    }

    private func deleteExclusion(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let id = rules[index].id
        withAnimation {
            rules.remove(atOffsets: indexSet)
        }
        LoggingExclusionManager.shared.remove(id: id)
        onDataChanged?()
    }
}
