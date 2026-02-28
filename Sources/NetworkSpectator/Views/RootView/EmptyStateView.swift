//
//  EmptyStateView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import SwiftUI

struct EmptyStateView: View {
    let isSearchActive: Bool
    let searchText: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if isSearchActive && !searchText.isEmpty {
                Button {
                    // This will be handled by parent view clearing search
                } label: {
                    Label("Clear Search", systemImage: "xmark.circle.fill")
                        .font(.callout)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(#colorLiteral(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)).opacity(0.3))
    }

    private var iconName: String {
        if isSearchActive {
            return "magnifyingglass"
        }
        return "network"
    }

    private var title: String {
        if isSearchActive {
            return "No Results Found"
        }
        return "No Network Requests"
    }

    private var message: String {
        if isSearchActive {
            return "No requests match '\(searchText)'. Try adjusting your search or filters."
        }
        return "Network requests will appear here as your app makes API calls. Start using your app to see network activity."
    }
}

#Preview("Empty State") {
    EmptyStateView(isSearchActive: false, searchText: "")
}

#Preview("Search Empty") {
    EmptyStateView(isSearchActive: true, searchText: "api/users")
}
