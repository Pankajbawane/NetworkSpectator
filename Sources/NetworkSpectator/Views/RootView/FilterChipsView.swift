//
//  FilterChipsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import SwiftUI

struct FilterChipsView: View {
    @Binding var selectedMethods: Set<String>
    @Binding var selectedStatusCategories: Set<String>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Method chips
                ForEach(Array(selectedMethods).sorted(), id: \.self) { method in
                    FilterChip(
                        title: method,
                        color: methodColor(method)
                    ) {
                        selectedMethods.remove(method)
                    }
                }

                // Status category chips
                ForEach(Array(selectedStatusCategories).sorted(), id: \.self) { category in
                    FilterChip(
                        title: category,
                        color: statusCategoryColor(category)
                    ) {
                        selectedStatusCategories.remove(category)
                    }
                }

                // Clear all button
                if !selectedMethods.isEmpty || !selectedStatusCategories.isEmpty {
                    Button {
                        selectedMethods.removeAll()
                        selectedStatusCategories.removeAll()
                    } label: {
                        Text("Clear All")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "PATCH": return .purple
        case "DELETE": return .red
        default: return .gray
        }
    }

    private func statusCategoryColor(_ category: String) -> Color {
        switch category {
        case "Success": return .green
        case "Redirection": return .yellow
        case "Client Error": return .orange
        case "Server Error": return .red
        default: return .gray
        }
    }
}

struct FilterChip: View {
    let title: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color)
        .cornerRadius(16)
    }
}
