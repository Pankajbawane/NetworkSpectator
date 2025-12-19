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
            mocksSection
            skipLoggingSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
        .onAppear {
            loadData()
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    loadData()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
            }
        }
        .sheet(isPresented: $showAddMockSheet) {
            AddRuleItemView(isMock: true, title: "Add Mock")
                .onDisappear {
                    loadData()
                }
        }
        .sheet(isPresented: $showAddSkipSheet) {
            AddRuleItemView(isMock: false, title: "Skip Logging")
                .onDisappear {
                    loadData()
                }
        }
    }

    // MARK: - Mocks Section

    private var mocksSection: some View {
        Section {
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
        } header: {
            sectionHeader(
                title: "Mock Responses",
                icon: "rectangle.stack.fill",
                count: mocks.count,
                addAction: { showAddMockSheet = true }
            )
        } footer: {
            if !mocks.isEmpty {
                Text("Swipe left to delete a mock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func mockItemRow(_ item: Item) -> some View {
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

    // MARK: - Skip Logging Section

    private var skipLoggingSection: some View {
        Section {
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
        } header: {
            sectionHeader(
                title: "Skip Logging Rules",
                icon: "eye.slash.fill",
                count: skipLogging.count,
                addAction: { showAddSkipSheet = true }
            )
        } footer: {
            if !skipLogging.isEmpty {
                Text("Swipe left to delete a skip rule")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func skipLoggingItemRow(_ item: Item) -> some View {
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

    // MARK: - Helper Views

    private func sectionHeader(
        title: String,
        icon: String,
        count: Int,
        addAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Label {
                HStack(spacing: 6) {
                    Text(title)
                    if count > 0 {
                        Text("(\(count))")
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: icon)
            }
            .font(.subheadline.weight(.semibold))

            Spacer()

            Button(action: addAction) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(title)")
        }
        .textCase(nil)
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

    // MARK: - Data Management

    private func loadData() {
        withAnimation {
            mocks = MockServer.shared.mocks.map { Item(mock: $0) }
            skipLogging = SkipRequestForLoggingHandler.shared.skipRequests.map(Item.init(skipRequest:))
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

    private func deleteSkipLogging(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let id = skipLogging[index].id
        withAnimation {
            skipLogging.remove(atOffsets: indexSet)
        }
        SkipRequestForLoggingHandler.shared.remove(id: id)
    }
}
