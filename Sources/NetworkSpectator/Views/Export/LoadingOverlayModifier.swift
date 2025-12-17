import SwiftUI

struct LoadingOverlayModifier: ViewModifier {
    let isPresented: Bool
    let text: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView(text)
                                .progressViewStyle(.circular)
                            if text.isEmpty == false {
                                Text(text)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(20)
                        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
    }
}

extension View {
    func loadingOverlay(isPresented: Bool, text: String = "") -> some View {
        modifier(LoadingOverlayModifier(isPresented: isPresented, text: text))
    }
}
