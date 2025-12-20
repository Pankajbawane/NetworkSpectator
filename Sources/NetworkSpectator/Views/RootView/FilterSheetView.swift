//
//  FilterSheetView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMethods: Set<String>
    @Binding var selectedStatusCodeCategory: Set<String>
    
    let availableMethods: [String]
    private let statusCodeCategory = ["100..<200", "200..<300", "300..<400", "400..<500", "500..<600", "Unknown"]

    var body: some View {
        NavigationStack {
            Form {
                // HTTP Methods Section
                Section {
                    if availableMethods.isEmpty {
                        Text("No methods available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableMethods, id: \.self) { method in
                            Toggle(isOn: Binding(
                                get: { selectedMethods.contains(method) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedMethods.insert(method)
                                    } else {
                                        selectedMethods.remove(method)
                                    }
                                }
                            )) {
                                HStack {
                                    HTTPMethodBadge(method: method)
                                    Text(method)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("HTTP Methods")
                        Spacer()
                        if !selectedMethods.isEmpty {
                            Button("Clear") {
                                selectedMethods.removeAll()
                            }
                            .font(.caption)
                        }
                    }
                }

                // Status Code Categories Section
                Section {
                    ForEach(statusCodeCategory, id: \.self) { category in
                        Toggle(isOn: Binding(
                            get: { selectedStatusCodeCategory.contains(category) },
                            set: { isSelected in
                                if isSelected {
                                    selectedStatusCodeCategory.insert(category)
                                } else {
                                    selectedStatusCodeCategory.remove(category)
                                }
                            }
                        )) {
                            HStack {
                                Circle()
                                    .fill(statusCodeCategoryColor(category))
                                    .frame(width: 12, height: 12)
                                Text(category)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Status Codes")
                        Spacer()
                        if !selectedStatusCodeCategory.isEmpty {
                            Button("Clear") {
                                selectedStatusCodeCategory.removeAll()
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            #if os(macOS)
            .padding(20)
            #endif
            .navigationTitle("Filter Requests")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .destructiveAction) {
                    if !selectedMethods.isEmpty || !selectedStatusCodeCategory.isEmpty {
                        Button("Clear All") {
                            selectedMethods.removeAll()
                            selectedStatusCodeCategory.removeAll()
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
    }
    
    private func statusCodeCategoryColor(_ range: String) -> Color {
        switch range {
        case "100..<200": return .green
        case "200..<300": return .yellow
        case "300..<400": return .orange
        case "400..<500": return .red
        case "500..<600": return .blue
        default: return .gray
        }
    }
}
