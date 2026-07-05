//
//  RootView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct RootView: View {
    @ObservedObject private var store = NetworkLogContainer.shared
    
    var body: some View {
        NavigationStack {
            LogListView(logItems: store.items)
                .navigationDestination(for: LogListView.NavigationRoute.self) { route in
                    switch route {
                    case .logDetail(let item, let isHistoric):
                        LogDetailsContainerView(initialItem: item, isHistoricLogs: isHistoric)
                    case .settings:
                        SettingsView()
                    case .insights(let data):
                        AnalyticsDashboardView(items: data)
                    }
                }
        }
    }
}

#Preview {
    RootView()
}
