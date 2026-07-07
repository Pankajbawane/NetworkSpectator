//
//  EmptyStateModifier.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 28/02/26.
//

import SwiftUI

/// A view modifier that displays an empty state with an icon, title, and message
struct EmptyStateModifier: ViewModifier {
    let icon: String
    let title: String
    let message: String
    
    func body(content: Content) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

extension View {
    /// Displays an empty state view with the specified icon, title, and message
    /// - Parameters:
    ///   - icon: The SF Symbol name to display
    ///   - title: The title text
    ///   - message: The descriptive message
    /// - Returns: A view with the empty state styling applied
    func emptyState(icon: String, title: String, message: String) -> some View {
        modifier(EmptyStateModifier(icon: icon, title: title, message: message))
    }
}
