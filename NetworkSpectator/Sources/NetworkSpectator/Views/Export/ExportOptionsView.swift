//
//  ExportOptionsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//


import SwiftUI

struct ExportOptionsView: View {
    /// Callback with selected export type
    enum ExportType: String, CaseIterable {
        case text = "Text"
        case csv = "CSV"
        case postman = "Postman Collection"
    }

    @State private var showExport = false
    @State var url: URL?
    
    var onSelect: (ExportType) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.0)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Centered popover
            VStack(spacing: 20) {
                Text("Export As")
                    .font(.headline)
                    .padding(.bottom, 10)

                ForEach(ExportType.allCases, id: \.self) { type in
                    Button {
                        onSelect(type)
                    } label: {
                        Text(type.rawValue)
                            .frame(minWidth: 180)
                            .padding()
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 28)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(radius: 10, y: 2)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: UUID()) // triggers animation on present/dismiss
        .popover(isPresented: $showExport) {
            if let url = url {
                ActivityView(item: url)
            }
        }
    }
}
