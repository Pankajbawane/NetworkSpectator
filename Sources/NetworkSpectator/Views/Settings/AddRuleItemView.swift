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

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var response: String = ""
    @State private var statusCode: String = ""
    @State private var headers: String = ""
    @State private var rule: Rule = .url
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Match Rule") {
                    Picker("Select rule", selection: $rule) {
                        ForEach(Rule.allCases) { rule in
                            Text(rule.title).tag(rule)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                #if os(macOS)
                Spacer().frame(minHeight: 10)
                #endif
                
                #if os(macOS)
                Spacer().frame(minHeight: 15)
                Divider()
                Spacer().frame(minHeight: 15)
                #endif
                
                Section("Enter rule criteria") {
                    TextEditor(text: $text)
                        .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                    #endif
                    #if os(macOS)
                        .frame(minHeight: 40)
                    #endif
                        .border(Color(.systemGray))
                }
                
                #if os(macOS)
                Spacer().frame(minHeight: 15)
                Divider()
                Divider()
                Spacer().frame(minHeight: 15)
                #endif
                
                if isMock {
                    Section("Mock Response") {
                        
                        HStack(alignment: .top) {
                            Text("Response")
                                .font(Font.caption.bold())
                            TextEditor(text: $response)
                                .font(.footnote)
                                .autocorrectionDisabled()
                            #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.asciiCapable)
                            #endif
                                .frame(minHeight: 90)
                                .border(Color(.systemGray))
                        }
                        
                        #if os(macOS)
                        Spacer().frame(minHeight: 15)
                        Divider()
                        Spacer().frame(minHeight: 15)
                        #endif
                        
                        HStack(alignment: .top) {
                            Text("Status Code")
                                .font(Font.caption.bold())
                            TextEditor(text: $statusCode)
                                .autocorrectionDisabled()
                            #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.numberPad)
                            #endif
                                .frame(minHeight: 40)
                                .border(Color(.systemGray))
                        }
                        
                        #if os(macOS)
                        Spacer().frame(minHeight: 15)
                        Divider()
                        Spacer().frame(minHeight: 15)
                        #endif
                        
                        HStack(alignment: .top) {
                            Text("Headers")
                                .font(Font.caption.bold())
                            TextEditor(text: $headers)
                                .font(.footnote)
                                .autocorrectionDisabled()
                            #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.asciiCapable)
                            #endif
                                .frame(minHeight: 60)
                                .border(Color(.systemGray))
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            #if os(macOS)
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
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddRuleItemView(isMock: true, title: "Add mock")
}
