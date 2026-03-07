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
    @ObservedObject var monitor = NetworkLogContainer.shared

    @State private var rotationAngle: Double = 0
    @State private var gearRotation: Double = 0
    @State private var isTapped: Bool = false

    private var viewState: ViewState {
        if !monitor.isLoggingEnabled {
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
        .overlay(alignment: .bottom) {
            if !monitor.isLoggingEnabled && (monitor.setupMode == .none || monitor.setupMode == .uiInitiated) {
                HStack {
                    Spacer()
                        .frame(width: 20)
                    Text("Add NetworkSpectator.start(:) early in your app's lifecycle to capture HTTP traffic. In on-demand mode, you can toggle monitoring at any time and optionally persist the preference across app launches.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(15)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.gray).opacity(0.1))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.gray).opacity(0.3), lineWidth: 1)
                        }
                    Spacer()
                        .frame(width: 20)
                }
            }
        }
    }
    
    @ViewBuilder
    var enableLoggingButton: some View {
        let tintColor: Color = isTapped ? .green : .blue
        Button {
            guard !isTapped else { return }
            isTapped = true
            // Delay enable so the bounce + green state is visible before the view transitions
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                NetworkLogContainer.shared.enableInternally()
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
        .onDisappear {
            // Reset animation.
            isTapped = false
            gearRotation = 0
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
                return "Tap below to start capturing network activity for this session. Monitoring preferences can be accessed via Tools > Network Monitor."
            }
        }
    }
}

private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25,
                               dampingFraction: 0.4,
                               blendDuration: 0),
                       value: configuration.isPressed)
    }
}

#Preview("Empty State") {
    EmptyStateView(isSearchActive: false, searchText: "")
}
