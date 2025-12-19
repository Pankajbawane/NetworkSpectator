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
    @Binding var selectedStatusCategories: Set<String>
    let availableMethods: [String]

    private let statusCategories = ["Success", "Redirection", "Client Error", "Server Error", "Informational", "Unknown"]

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

                // Status Categories Section
                Section {
                    ForEach(statusCategories, id: \.self) { category in
                        Toggle(isOn: Binding(
                            get: { selectedStatusCategories.contains(category) },
                            set: { isSelected in
                                if isSelected {
                                    selectedStatusCategories.insert(category)
                                } else {
                                    selectedStatusCategories.remove(category)
                                }
                            }
                        )) {
                            HStack {
                                Circle()
                                    .fill(statusCategoryColor(category))
                                    .frame(width: 12, height: 12)
                                Text(category)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Status Categories")
                        Spacer()
                        if !selectedStatusCategories.isEmpty {
                            Button("Clear") {
                                selectedStatusCategories.removeAll()
                            }
                            .font(.caption)
                        }
                    }
                }
            }
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
                    if !selectedMethods.isEmpty || !selectedStatusCategories.isEmpty {
                        Button("Clear All") {
                            selectedMethods.removeAll()
                            selectedStatusCategories.removeAll()
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

    private func statusCategoryColor(_ category: String) -> Color {
        switch category {
        case "Success": return .green
        case "Redirection": return .yellow
        case "Client Error": return .orange
        case "Server Error": return .red
        case "Informational": return .blue
        default: return .gray
        }
    }
}

#Preview {
    FilterSheetView(
        selectedMethods: .constant(["GET", "POST"]),
        selectedStatusCategories: .constant(["Success"]),
        availableMethods: ["GET", "POST", "PUT", "DELETE"]
    )
}
