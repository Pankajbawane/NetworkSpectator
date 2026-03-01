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
    @ObservedObject private var store = NetworkLogContainer.shared

    var body: some View {
        List {
            insightSection
            mockManagementSection
            skipLoggingManagementSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Tools")
        .onAppear {
            loadCounts()
        }
    }

    // MARK: - Insights Section

    private var insightSection: some View {
        Section {
            NavigationLink {
                AnalyticsDashboardView(data: store.items)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.title3)
                        .foregroundStyle(.blue)
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

    // MARK: - Mock Management Section

    private var mockManagementSection: some View {
        Section {
            NavigationLink {
                MockManagementView()
            } label: {
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
            NavigationLink {
                SkipLoggingManagementView()
            } label: {
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
}
