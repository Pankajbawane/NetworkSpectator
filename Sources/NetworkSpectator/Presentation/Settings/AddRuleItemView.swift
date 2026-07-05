//
//  AddRuleItemView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import SwiftUI

struct AddRuleItemView: View {
    typealias Rule = AddRuleItem.Rule

    enum Focus: Hashable {
        case rule
        case response
        case statusCode
        case headers
        case none
    }

    let isMock: Bool
    let title: String
    let item: AddRuleItem?
    let onSave: (() -> Void)?

    private let methods: [HTTPMethod] = [.GET, .POST, .PUT, .DELETE, .PATCH]

    @Environment(\.dismiss) private var dismiss
    @State private var saveLocally: Bool = false
    @State private var text: String = ""
    @State private var response: String = ""
    @State private var statusCode: String = ""
    @State private var headers: String = ""
    @State private var rule: Rule = .url
    @State private var method: HTTPMethod = .GET
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var delay: String = ""
    @State private var showDeleteAlert: Bool = false
    @FocusState private var focus: Focus?

    init(isMock: Bool, title: String, item: AddRuleItem? = nil, onSave: (() -> Void)? = nil) {
        self.isMock = isMock
        self.title = title
        self.item = item
        self.onSave = onSave

        if let item {
            _method = State(initialValue: item.method)
            _text = State(initialValue: item.text)
            _response = State(initialValue: item.response)
            _statusCode = State(initialValue: item.statusCode)
            _headers = State(initialValue: item.headers)
            _delay = State(initialValue: item.delay)
            _rule = State(initialValue: item.rule)
            _saveLocally = State(initialValue: item.saveLocally)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                methodSection
                ruleSection
                criteriaSection

                if isMock {
                    mockResponseSection
                }

                saveLocallySection
                deleteSection
            }
            #if os(macOS)
            .formStyle(.grouped)
            .padding(20)
            #endif
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .toolbar { toolbarContent }
        }
    }

    private var methodSection: some View {
        Section {
            Picker("Method", selection: $method) {
                ForEach(methods) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            #if os(iOS)
            .pickerStyle(.menu)
            #else
            .pickerStyle(.inline)
            #endif
        } header: {
            Text("HTTP Method")
        } footer: {
            Text("Select HTTP Method")
                .font(.caption)
        }
    }

    private var ruleSection: some View {
        Section {
            Picker("Rule Type", selection: $rule) {
                ForEach(Rule.allCases) { rule in
                    Text(rule.title).tag(rule)
                }
            }
            #if os(iOS)
            .pickerStyle(.menu)
            #else
            .pickerStyle(.inline)
            #endif
        } header: {
            Text("Match Rule")
        } footer: {
            Text(ruleDescription)
                .font(.caption)
        }
    }

    private var criteriaSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                #if os(iOS)
                Text("Criteria")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #endif
                TextEditor(text: $text)
                    .scrollDismissesKeyboard(.automatic)
                    .focused($focus, equals: .rule)
                    .font(.body)
                    .autocorrectionDisabled()
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    .frame(minHeight: 80)
                #else
                    .frame(minHeight: 60, maxHeight: 100)
                #endif
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isCriteriaEmpty ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            }
            .padding(.vertical, 4)
        } header: {
            Text("Rule Criteria")
        } footer: {
            Text("Enter the pattern to match")
                .font(.caption)
        }
    }

    private var mockResponseSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                responseBodyField
                Divider()
                statusCodeField
                Divider()
                headersField
                Divider()
                delayField
            }
            .padding(.vertical, 8)
        } header: {
            Text("Mock Response")
        } footer: {
            Text("Provide JSON response body, HTTP status code, and headers in key===value format")
                .font(.caption)
        }
    }

    private var responseBodyField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Response Body", systemImage: "doc.text")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            TextEditor(text: $response)
                .scrollDismissesKeyboard(.automatic)
                .focused($focus, equals: .response)
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()
            #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
                .frame(minHeight: 120)
            #else
                .frame(minHeight: 100)
            #endif
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var statusCodeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Status Code", systemImage: "number")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            #if os(iOS)
            TextField("200", text: $statusCode)
                .scrollDismissesKeyboard(.automatic)
                .focused($focus, equals: .statusCode)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            #else
            TextField("200", text: $statusCode)
                .focused($focus, equals: .statusCode)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 150)
            #endif
        }
    }

    private var headersField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Response Headers", systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            TextEditor(text: $headers)
                .scrollDismissesKeyboard(.automatic)
                .focused($focus, equals: .headers)
                .font(.system(.callout, design: .monospaced))
                .autocorrectionDisabled()
            #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
                .frame(minHeight: 80, maxHeight: 500)
            #else
                .frame(minHeight: 70, maxHeight: 200)
            #endif
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var delayField: some View {
        HStack(alignment: .center, spacing: 6) {
            Label("Delay in seconds", systemImage: "clock")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            #if os(iOS)
            TextField("0", text: $delay)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            #else
            TextField("0", text: $delay)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 150)
            #endif
        }
    }

    private var saveLocallySection: some View {
        Section {
            Toggle("Save locally", isOn: $saveLocally)
                .toggleStyle(SwitchToggleStyle())
        } footer: {
            Text("Saved rules are applied automatically on app launch")
                .font(.caption)
        }
    }

    @ViewBuilder
    private var deleteSection: some View {
        if let editingItem = item, editingItem.showDelete {
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .alert("Delete Rule", isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        delete(editingItem)
                    }
                } message: {
                    Text("Are you sure you want to delete this rule? This action cannot be undone.")
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(item == nil ? "Add" : "Save") {
                addRule()
            }
            .disabled(isCriteriaEmpty)
        }
    }

    private var isCriteriaEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var ruleDescription: String {
        switch rule {
        case .url:
            return "Match the complete URL"
        case .host:
            return "Match the host name"
        case .path:
            return "Match the complete path excluding the host name"
        case .endPath:
            return "Match the ending path from the URL"
        case .pathComponent:
            return "Match any path component from the URL"
        }
    }

    private func addRule() {
        let matchRule = makeMatchRule()

        do {
            if isMock {
                let mock = try makeMock(rule: matchRule)
                replaceExistingItemIfNeeded()
                MockServer.shared.register(mock)
            } else {
                let exclusion = LoggingExclusionRule(method: method, rule: matchRule, saveLocally: saveLocally)
                replaceExistingItemIfNeeded()
                LoggingExclusionManager.shared.register(request: exclusion)
            }

            onSave?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func makeMatchRule() -> MatchRule {
        let criteria = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch rule {
        case .url:
            return .url(criteria)
        case .host:
            return .hostName(criteria)
        case .endPath:
            return .endPath(criteria)
        case .path:
            return .path(criteria)
        case .pathComponent:
            return .subPath(criteria)
        }
    }

    private func makeMock(rule: MatchRule) throws -> Mock {
        let responseData = try HTTPInputConverter.jsonData(from: response)
        let statusCode = try HTTPInputConverter.statusCode(from: statusCode)
        let headersData = try HTTPInputConverter.headers(from: headers)
        let response = HTTPResponse(headers: headersData,
                                    statusCode: statusCode,
                                    responseData: responseData,
                                    error: nil,
                                    responseTime: Double(delay) ?? 0)
        return Mock(method: method,
                    rule: rule,
                    response: response,
                    saveLocally: saveLocally)
    }

    private func replaceExistingItemIfNeeded() {
        guard let existingItem = item else { return }
        if existingItem.isMock {
            MockServer.shared.remove(id: existingItem.id)
        } else {
            LoggingExclusionManager.shared.remove(id: existingItem.id)
        }
    }

    private func delete(_ item: AddRuleItem) {
        if item.isMock {
            MockServer.shared.remove(id: item.id)
        } else {
            LoggingExclusionManager.shared.remove(id: item.id)
        }
        dismiss()
    }
}

#Preview {
    AddRuleItemView(isMock: true, title: "Add mock")
}
