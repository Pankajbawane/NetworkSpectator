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
        case pathComponent = "PathComponent"

        var id: Self { self }

        var title: String {
            switch self {
            case .url: return "URL"
            case .path: return "Path"
            case .endPath: return "End Path"
            case .pathComponent: return "Path Component"
            }
        }
    }

    let isMock: Bool
    let title: String
    let placeholder: String

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var response: String = ""
    @State private var statusCode: String = ""
    @State private var headers: String = ""
    @State private var rule: Rule = .url
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    var complete: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section("Match Rule") {
                    Picker("", selection: $rule) {
                        ForEach(Rule.allCases) { rule in
                            Text(rule.title).tag(rule)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section("Enter matching criteria") {
                    TextEditor(text: $text)
                        .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                    #endif
                        .frame(minHeight: 40)
                }
                
                if isMock {
                    Section("Mock Response") {
                        
                        Text("Response")
                            .font(Font.caption.bold())
                        TextEditor(text: $response)
                            .autocorrectionDisabled()
                        #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.asciiCapable)
                            .border(Color(.secondarySystemBackground))
                        #endif
                            .frame(minHeight: 90)
                        
                        
                        HStack {
                            Text("Status Code")
                                .font(Font.caption.bold())
                            TextField("Enter", text: $statusCode)
                                .autocorrectionDisabled()
                            #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.numberPad)
                                .border(Color(.secondarySystemBackground))
                            #endif
                                .frame(minHeight: 40)
                        }
                        
                        
                        Text("Headers")
                            .font(Font.caption.bold())
                        TextEditor(text: $headers)
                            .autocorrectionDisabled()
                        #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.asciiCapable)
                            .border(Color(.secondarySystemBackground))
                        #endif
                            .frame(minHeight: 60)
                        
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let matchRule: MatchRule
                        switch rule {
                        case .url:
                            matchRule = .url(text)
                        case .endPath:
                            matchRule = .endPath(text)
                        case .path:
                            matchRule = .path(text)
                        case .pathComponent:
                            matchRule = .pathComponent(text)
                        }
                        if isMock {
                            do {
                                let responseData = try HTTPInputConverter.jsonData(from: response)
                                let statuscode = try HTTPInputConverter.statusCode(from: statusCode)
                                let headersData = try HTTPInputConverter.headers(from: headers)
                                let mock = try Mock(rules: [matchRule],
                                                    response: responseData,
                                                    headers: headersData,
                                                    statusCode: statuscode)
                                MockServer.shared.register(mock)
                            } catch {
                                self.errorMessage = error.localizedDescription
                                self.showErrorAlert = true
                                return
                            }
                        } else {
                            SkipRequestForLoggingHandler.shared.register(rule: matchRule)
                        }
                        guard !showErrorAlert else { return }
                        complete?()
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

