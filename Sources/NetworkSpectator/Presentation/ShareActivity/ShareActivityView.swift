//
//  ShareActivityView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit

struct ShareActivityView: UIViewControllerRepresentable {
    let item: Any
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [item], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}

#elseif canImport(AppKit)
// Extension to add macOS share functionality directly to any View
extension View {
    func macOSShareSheet<T: Identifiable>(item: Binding<T?>, content: @escaping (T) -> Any) -> some View where T.ID == UUID {
        background(ShareActivityView(item: item, content: content))
    }
}

struct ShareActivityView<T: Identifiable>: NSViewRepresentable where T.ID == UUID {
    @Binding var item: T?
    let content: (T) -> Any

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let currentItem = item,
              context.coordinator.lastItemID != currentItem.id else {
            return
        }

        context.coordinator.lastItemID = currentItem.id
        let shareData = content(currentItem)

        DispatchQueue.main.async {
            guard let window = nsView.window,
                  let contentView = window.contentView else {
                context.coordinator.lastItemID = nil
                return
            }

            let picker = NSSharingServicePicker(items: [shareData])
            picker.delegate = context.coordinator

            let rect = NSRect(
                x: contentView.bounds.maxX,
                y: contentView.bounds.midY,
                width: 1,
                height: 1
            )

            picker.show(relativeTo: rect, of: contentView, preferredEdge: .minY)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, NSSharingServicePickerDelegate {
        var lastItemID: UUID?
    }
}
#endif
