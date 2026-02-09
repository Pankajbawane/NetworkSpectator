//
//  AddRuleItemView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import SwiftUI

struct AddRuleItemView: View {
    enum Rule: String, CaseIterable, Identifiable {
        case url = "URL"
        case path = "Path"
        case endPath = "EndPath"
        case pathComponent = "Path Component"

        var id: Self { self }

        var title: String {
            rawValue
        }
    }

    let isMock: Bool
    let title: String
    let item: AddRuleItem?
    let onSave: (() -> Void)?
    @State private var saveLocally: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var response: String = ""
    @State private var statusCode: String = ""
    @State private var headers: String = ""
    @State private var rule: Rule = .url
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    init(isMock: Bool, title: String, item: AddRuleItem? = nil, onSave: (() -> Void)? = nil) {
        self.isMock = isMock
        self.title = title
        self.item = item
        self.onSave = onSave

        if let item = item {
            _text = State(initialValue: item.text)
            _response = State(initialValue: item.response)
            _statusCode = State(initialValue: item.statusCode)
            _headers = State(initialValue: item.headers)
            _rule = State(initialValue: item.rule)
            _saveLocally = State(initialValue: item.saveLocally)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
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

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        #if os(iOS)
                        Text("Criteria")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        #endif
                        TextEditor(text: $text)
                            .font(.body)
                            .autocorrectionDisabled()
                        #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.asciiCapable)
                            .frame(minHeight: 80)
                        #else
                            .frame(minHeight: 60)
                        #endif
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(text.isEmpty ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Rule Criteria")
                } footer: {
                    Text("Enter the pattern to match")
                        .font(.caption)
                }

                if isMock {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Response Body", systemImage: "doc.text")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)

                                TextEditor(text: $response)
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

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Label("Status Code", systemImage: "number")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)

                                #if os(iOS)
                                TextField("200", text: $statusCode)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                #else
                                TextField("200", text: $statusCode)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 150)
                                #endif
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Label("Headers", systemImage: "list.bullet.rectangle")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)

                                TextEditor(text: $headers)
                                    .font(.system(.callout, design: .monospaced))
                                    .autocorrectionDisabled()
                                #if os(iOS)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.asciiCapable)
                                    .frame(minHeight: 80)
                                #else
                                    .frame(minHeight: 70)
                                #endif
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Mock Response")
                    } footer: {
                        Text("Provide JSON response body, HTTP status code, and headers in key===value format)")
                            .font(.caption)
                    }
                }
                
                Section {
                    Toggle("Save locally", isOn: $saveLocally)
                        .toggleStyle(SwitchToggleStyle())
                } footer: {
                    Text("Saved rules are applied automatically on app launch")
                        .font(Font.caption)
                }
                    
            }
            #if os(macOS)
            .formStyle(.grouped)
            .padding(20)
            .navigationTitle(title)
            #endif
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(item == nil ? "Add" : "Save") {
                        addRule()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var ruleDescription: String {
        switch rule {
        case .url:
            return "Match the complete URL"
        case .path:
            return "Match the URL path"
        case .endPath:
            return "Match URLs ending with this path"
        case .pathComponent:
            return "Match any path component"
        }
    }

    private func addRule() {
        let matchRule: MatchRule
        switch rule {
        case .url:
            matchRule = .url(text)
        case .endPath:
            matchRule = .endPath(text)
        case .path:
            matchRule = .path(text)
        case .pathComponent:
            matchRule = .subPath(text)
        }

        // If we're editing an existing item, remove the old one first
        if let existingItem = item {
            if isMock {
                MockServer.shared.remove(id: existingItem.id)
            } else {
                SkipRequestForLoggingHandler.shared.remove(id: existingItem.id)
            }
        }

        if isMock {
            do {
                let responseData = try HTTPInputConverter.jsonData(from: response)
                let statuscode = try HTTPInputConverter.statusCode(from: statusCode)
                let headersData = try HTTPInputConverter.headers(from: headers)
                let mock = Mock(rules: [matchRule],
                               response: responseData,
                               headers: headersData,
                               statusCode: statuscode,
                                saveLocally: saveLocally)
                MockServer.shared.register(mock)
                
                // Call onSave callback if provided
                if let onSave = onSave {
                    onSave()
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                return
            }
        } else {
            let skipRequest = SkipRequestForLogging(rule: matchRule, saveLocally: saveLocally)
            SkipRequestForLoggingHandler.shared.register(request: skipRequest)

            // Call onSave callback if provided
            if let onSave = onSave {
                onSave()
            }
        }

        guard !showErrorAlert else { return }
        dismiss()
    }
}

#Preview {
    AddRuleItemView(isMock: true, title: "Add mock")
}
