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
            Image(systemName: viewState.icon)
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)

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
                    Button {
                        NetworkLogContainer.shared.enable()
                    } label: {
                        Text("Enable Monitoring")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.blue, lineWidth: 2)
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
        .background(Color(#colorLiteral(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)).opacity(viewState == .disabledLogging ? 0.2 : 0.3))
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
                return "globe.badge.clock.fill"
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

#Preview("Empty State") {
    EmptyStateView(isSearchActive: false, searchText: "")
}
