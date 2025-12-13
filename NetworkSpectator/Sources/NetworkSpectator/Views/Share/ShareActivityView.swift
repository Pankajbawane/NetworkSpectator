//
//  ShareActivityView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let item: Any
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [item], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}

#elseif canImport(AppKit)
import AppKit

struct ActivityView: NSViewControllerRepresentable {
    let item: Any

    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        controller.view = NSView(frame: .zero)
        return controller
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // Present the macOS share sheet using NSSharingServicePicker
        guard context.coordinator.hasPresented == false else { return }
        context.coordinator.hasPresented = true

        let picker = NSSharingServicePicker(items: [item])
        picker.delegate = context.coordinator

        let view = nsViewController.view
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, NSSharingServicePickerDelegate {
        var hasPresented = false
    }
}
#endif
