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
    @State var isLoggingEnabled: Bool = NetworkLogContainer.shared.isLoggingEnabled

    @State private var rotationAngle: Double = 0
    @State private var gearRotation: Double = 0
    @State private var isTapped: Bool = false

    private var viewState: ViewState {
        if !isLoggingEnabled {
            return .disabledLogging
        }
        if isSearchActive {
            return .search
        }
        return .emptyData
    }

    var body: some View {
        VStack(spacing: 16) {
            if viewState == .disabledLogging {
                Image(systemName: viewState.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(gearRotation))
                    .animation(
                        .linear(duration: 30).repeatForever(autoreverses: false),
                        value: gearRotation
                    )
                    .onAppear {
                        if viewState == .disabledLogging {
                            gearRotation = 360
                        }
                    }
            } else {
                Image(systemName: viewState.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: 6) {
                Text(viewState.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospaced(true)
                    .foregroundStyle(.primary)

                Text(viewState.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                if viewState == .disabledLogging {
                    enableLoggingButton
                }
            }

            if viewState == .search && !searchText.isEmpty {
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
        .background(Color.white.opacity(viewState == .disabledLogging ? 0.15 : 0.3))
    }
    
    @ViewBuilder
    var enableLoggingButton: some View {
        let tintColor: Color = isTapped ? .green : .blue
        Button {
            guard !isTapped else { return }
            NetworkLogContainer.shared.enable()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                isTapped = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isLoggingEnabled = NetworkLogContainer.shared.isLoggingEnabled
            }
        } label: {
            Text(isTapped ? "Enabled Monitoring" : "Enable Monitoring")
                .font(.body)
                .fontWeight(.semibold)
                .padding(10)
                .foregroundStyle(tintColor)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tintColor, lineWidth: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.1),
                                    .green.opacity(0.2),
                                    .cyan.opacity(1),
                                    .green.opacity(0.2),
                                    .white.opacity(0.1),
                                ]),
                                center: .center,
                                angle: .degrees(rotationAngle)
                            ),
                            lineWidth: 3
                        )
                )
        }
        .buttonStyle(BounceButtonStyle())
        .disabled(isTapped)
        .padding(15)
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
        }
    }
}

extension EmptyStateView {
    enum ViewState {
        case emptyData
        case search
        case disabledLogging
        
        var icon: String {
            switch self {
            case .emptyData:
                return "network"
            case .search:
                return "magnifyingglass"
            case .disabledLogging:
                return "gearshape.fill"
            }
        }
        
        var title: String {
            switch self {
            case .emptyData:
                return "No Network Requests"
            case .search:
                return "No Results Found"
            case .disabledLogging:
                return "NetworkSpectator"
            }
        }
        
        var message: String {
            switch self {
            case .emptyData:
                return "Network requests will appear here as your app makes HTTP calls. Start using your app to see network activity."
            case .search:
                return "No requests matched. Try adjusting your search or filters."
            case .disabledLogging:
                return "Enable monitoring to see network activity. To enable programmatically, call `NetworkLogger.enable()` in the app launch implementation."
            }
        }
    }
}

private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

#Preview("Empty State") {
    EmptyStateView(isSearchActive: false, searchText: "")
}
