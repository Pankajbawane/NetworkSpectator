//
//  NetworkLogMonitor.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 02/07/26.
//

import SwiftUI
import NetworkSpectatorCore
import NetworkSpectatorMocking

/// Coordinates monitoring controls and exposes monitoring state to the UI.
@MainActor
package final class NetworkLogMonitor: ObservableObject, Sendable {
    package static let shared = NetworkLogMonitor()
    
    private let logContainer: NetworkLogContainer
    private let logStore: any NetworkLogStoring
    
    /// Safeguard against redundant activations. Avoids multiple calls to start/stop monitoring.
    @Published package private(set) var isLoggingEnabled: Bool = false
    
    /// Tracks how monitoring was initialized, programmatically or UI.
    package private(set) var setupMode: SetupMode = .none
    
    package init(logContainer: NetworkLogContainer = .shared,
                logStore: any NetworkLogStoring = NetworkLogStore.shared) {
        self.logContainer = logContainer
        self.logStore = logStore
    }
    
    /// When Monitoring state to be handled by UI on demand.
    package func enableOnDemand() async {
        setupMode = .onDemand
        // if preference was stored.
        if PreferenceStorage(preference: .monitoring).retrieve() {
            await enable()
        }
    }
    
    /// When enabled only with UI.
    package func enableInternally() async {
        if setupMode == .none {
            setupMode = .uiInitiated
        }
        await enable()
    }
    
    /// Enables monitoring and logging. 'isLoggingEnabled' flag avoids redundant invocation.
    package func enable() async {
        guard !isLoggingEnabled else {
            DebugConsoleLogger.log("NETWORK SPECTATOR: Monitoring was already active.")
            return
        }
        if setupMode == .none {
            setupMode = .started
        }
        logContainer.startProjectingUpdates()
        await startSession()
        isLoggingEnabled = true
        DebugConsoleLogger.log("NETWORK SPECTATOR: Logging initiated.")
    }
    
    /// Disables monitoring and logging. 'isLoggingEnabled' flag avoids redundant invocation.
    package func disable() async {
        guard isLoggingEnabled else {
            DebugConsoleLogger.log("NETWORK SPECTATOR: Monitoring was inactive.")
            return
        }
        await stopSession()
        logContainer.stopProjectingUpdates()
        isLoggingEnabled = false
        DebugConsoleLogger.log("NETWORK SPECTATOR: Monitoring stopped.")
    }
    
    /// Clears current list of items. This does not stop the monitoring.
    package func clear() async {
        guard isLoggingEnabled else {
            logContainer.resetProjection()
            return
        }
        
        logContainer.startProjectingUpdates()
        await restartSession()
    }
    
    private func startSession() async {
        NetworkURLProtocol.logger = UIItemLogger()
        NetworkURLProtocol.mockServer = MockServer.shared
        await logStore.start()
        await LogHistoryManager.shared.startObserving()
        NetworkInterceptor.shared.enable(for: .logging)
    }
    
    private func stopSession() async {
        NetworkInterceptor.shared.disable(for: .logging)
        await logStore.deactivate()
        await LogHistoryManager.shared.finalizeAndStopObserving()
        await logStore.stop()
        NetworkURLProtocol.logger = DefaultItemLogger()
    }
    
    private func restartSession() async {
        await logStore.deactivate()
        await LogHistoryManager.shared.finalizeAndStopObserving()
        await logStore.start()
        await LogHistoryManager.shared.startObserving()
    }
}



extension NetworkLogMonitor {
    /// How the monitoring was initialized.
    package enum SetupMode {
        /// Not yet initialized — user opened the UI without calling start().
        case none
        /// NetworkSpectator.start() was called (always-on monitoring).
        case started
        /// NetworkSpectator.start(onDemand: true) was called.
        case onDemand
        /// Started through UI.
        case uiInitiated
    }
}
