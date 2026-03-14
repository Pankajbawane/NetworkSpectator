//
//  SettingsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import SwiftUI

struct SettingsView: View {

    @State private var mockCount: Int = 0
    @State private var skipLoggingCount: Int = 0
    @State private var toggleMonitoring: Bool = false
    @State private var togglePersistence: Bool = false
    @State private var refreshID = UUID()
    @ObservedObject private var store = NetworkLogContainer.shared
    
    let preferenceStorage = PreferenceStorage(preference: .monitoring)

    var body: some View {
        List {
            if store.setupMode != .started {
                monitoringManagementSection
            }
            insightSection
            historySection
            mockManagementSection
            skipLoggingManagementSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationDestination(for: SettingsRoute.self) { route in
            switch route {
            case .insights:
                AnalyticsDashboardView(items: store.items)
            case .history:
                LogHistoryView()
            case .mockManagement:
                MockManagementView(onDataChanged: { refreshID = UUID() })
            case .skipLogging:
                SkipLoggingManagementView(onDataChanged: { refreshID = UUID() })
            }
        }
        .navigationTitle("Tools")
        .onAppear {
            loadCounts()
            loadMonitoringState()
        }
        .onChange(of: refreshID) { _ in
            loadCounts()
        }
    }

    // MARK: - Monitoring Management Section
    
    private var monitoringManagementSection: some View {
        Section {
            Toggle(isOn: $toggleMonitoring) {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: store.isLoggingEnabled ? "network" : "network.slash")
                            .font(.title3)
                            .foregroundStyle(store.isLoggingEnabled ? .blue : .secondary)
                            .frame(width: 28)
                        
                        Text("Network Monitoring")
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
            .toggleStyle(SwitchToggleStyle())
            
        } header: {
            Text("Monitoring is \(store.isLoggingEnabled ? "enabled" : "disabled")")
                .font(.subheadline)
                .monospaced(true)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        } footer: {
                if store.setupMode == .none || store.setupMode == .uiInitiated {
                    VStack {
                        Text("Use NetworkSpectator.start(onDemand:) early in your app's lifecycle to enable on-demand monitoring. It allows this preference to persists across launches and monitoring begins automatically on app launch.")
                            .font(.footnote)
                        Divider()
                    }
                }
        }
        .onChange(of: toggleMonitoring) { value in
            if store.setupMode == .onDemand {
                PreferenceStorage(preference: .monitoring).save(true)
            }
            preferenceStorage.save(value)
            if value {
                store.enableInternally()
            } else {
                store.disable()
            }
        }
    }
    
    // MARK: - Insights Section

    private var insightSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.insights) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.title3)
                        .foregroundStyle(.purple)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Insights")
                            .font(.body)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
           
        } footer: {
            Text("View analytics and insights for network requests")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Insights Section

    private var historySection: some View {
        Section {
            NavigationLink(value: SettingsRoute.history) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.title2)
                        .foregroundStyle(.mint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("History")
                            .font(.body)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
           
        } footer: {
            Text("View history of logged network requests")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Mock Management Section

    private var mockManagementSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.mockManagement) {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mock Responses")
                            .font(.body)
                        if mockCount > 0 {
                            Text("\(mockCount) active mock\(mockCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No active mocks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if mockCount > 0 {
                        Text("\(mockCount)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.green)
                            )
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            
        } footer: {
            Text("Configure mock responses for network requests")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Skip Rules Management Section
    
    private var skipLoggingManagementSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.skipLogging) {
                HStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Skip Logging Rules")
                            .font(.body)
                        if skipLoggingCount > 0 {
                            Text("\(skipLoggingCount) active rule\(skipLoggingCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No active rules")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if skipLoggingCount > 0 {
                        Text("\(skipLoggingCount)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.orange)
                            )
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            
        } footer: {
            Text("Configure skip rules for network requests")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Data Management

    private func loadCounts() {
        mockCount = MockServer.shared.mocks.count
        skipLoggingCount = SkipRequestForLoggingHandler.shared.skipRequests.count
    }

    private func loadMonitoringState() {
        toggleMonitoring = store.isLoggingEnabled
    }
}

// MARK: - Navigation
extension SettingsView {
    enum SettingsRoute: Hashable {
        case insights
        case history
        case mockManagement
        case skipLogging
    }
}
