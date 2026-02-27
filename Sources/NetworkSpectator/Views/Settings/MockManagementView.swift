//
//  MockManagementView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 27/02/26.
//

import SwiftUI

struct MockManagementView: View {

    @State private var mocks: [ManageRuleItem] = []
    @State private var showAddMockSheet = false
    @State private var editingMockItem: AddRuleItem?

    var body: some View {
        List {
            if mocks.isEmpty {
                emptyStateView(
                    icon: "doc.text.image",
                    title: "No Mocks",
                    message: "Add a mock to intercept network requests and return custom responses"
                )
            } else {
                ForEach(mocks) { item in
                    mockItemRow(item)
                }
                .onDelete { indexSet in
                    deleteMock(at: indexSet)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Mock Responses")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddMockSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Mock")
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
        .sheet(isPresented: $showAddMockSheet) {
            AddRuleItemView(isMock: true, title: "Add Mock")
                .onDisappear {
                    loadData()
                }
        }
        .sheet(item: $editingMockItem) { item in
            AddRuleItemView(isMock: true, title: "Edit Mock", item: item) {
                loadData()
            }
        }
    }

    private func mockItemRow(_ item: ManageRuleItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.body)
                    .lineLimit(2)

                Text("Mock Response")
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
            if let mock = MockServer.shared.mocks.first(where: { $0.id == item.id }),
               let ruleItem = AddRuleItem(mock: mock) {
                editingMockItem = ruleItem
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                if let index = mocks.firstIndex(where: { $0.id == item.id }) {
                    deleteMock(at: IndexSet(integer: index))
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
            mocks = MockServer.shared.mocks.map { ManageRuleItem(mock: $0) }
        }
    }

    private func deleteMock(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let id = mocks[index].id
        withAnimation {
            mocks.remove(atOffsets: indexSet)
        }
        MockServer.shared.remove(id: id)
    }
}
