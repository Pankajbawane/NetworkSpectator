//
//  ResponseImageView.swift
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

struct ResponseImageView: View {

    let data: Data?

    var body: some View {
        if let data,
           let image = Self.makeImage(from: data) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(8)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("Unable to load image")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }

    private static func makeImage(from data: Data) -> Image? {
        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        return nil
        #endif
    }
}
