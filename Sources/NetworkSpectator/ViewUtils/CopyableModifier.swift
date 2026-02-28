//
//  CopyableModifier.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 28/02/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A view modifier that overlays a clipboard copy button.
/// Tapping the button copies the provided value to the system pasteboard
/// and briefly shows a checkmark as confirmation.
struct CopyableModifier: ViewModifier {
    let value: String
    let size: Font
    @State private var showCopied = false
    
    init(value: String, size: Font = .callout) {
        self.value = value
        self.size = size
    }

    func body(content: Content) -> some View {
        Button {
            copyToClipboard(value)
            withAnimation {
                showCopied = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 1000_000_000)
                withAnimation {
                    showCopied = false
                }
            }
        } label: {
            Image(systemName: showCopied ? "checkmark" : "list.clipboard.fill")
                .font(size)
                .foregroundColor(showCopied ? .green : .secondary)
        }
        .buttonStyle(.plain)
        .frame(height: 20)
    }

    private func copyToClipboard(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}

extension View {
    /// Adds a clipboard copy button to the top-right corner of the view.
    /// - Parameter value: The string to copy to the pasteboard when tapped.
    /// - Returns: A view with the copy button overlay applied.
    func copyable(value: String, size: Font = .callout) -> some View {
        modifier(CopyableModifier(value: value, size: size))
    }
}
