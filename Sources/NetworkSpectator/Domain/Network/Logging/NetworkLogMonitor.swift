//
//  NetworkLogMonitor.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 02/07/26.
//

import SwiftUI

/// Coordinates monitoring controls and exposes monitoring state to the UI.
@MainActor
final class NetworkLogMonitor: ObservableObject, Sendable {
    static let shared = NetworkLogMonitor()
    
    private let logContainer: NetworkLogContainer
    private let logStore: any NetworkLogStoring
    
    /// Safeguard against redundant activations. Avoids multiple calls to start/stop monitoring.
    @Published private(set) var isLoggingEnabled: Bool = false
    
    /// Tracks how monitoring was initialized, programmatically or UI.
    private(set) var setupMode: SetupMode = .none
    
    init(logContainer: NetworkLogContainer = .shared,
         logStore: any NetworkLogStoring = NetworkLogStore.shared) {
        self.logContainer = logContainer
        self.logStore = logStore
    }
    
    /// When Monitoring state to be handled by UI on demand.
    func enableOnDemand() async {
        setupMode = .onDemand
        // if preference was stored.
        if PreferenceStorage(preference: .monitoring).retrieve() {
            await enable()
        }
    }
    
    /// When enabled only with UI.
    func enableInternally() async {
        if setupMode == .none {
            setupMode = .uiInitiated
        }
        await enable()
    }
    
    /// Enables monitoring and logging. 'isLoggingEnabled' flag avoids redundant invocation.
    func enable() async {
        guard !isLoggingEnabled else {
            DebugPrint.log("NETWORK SPECTATOR: Monitoring was already active.")
            return
        }
        if setupMode == .none {
            setupMode = .started
        }
        logContainer.startProjectingUpdates()
        await startSession()
        isLoggingEnabled = true
        DebugPrint.log("NETWORK SPECTATOR: Logging initiated.")
    }
    
    /// Disables monitoring and logging. 'isLoggingEnabled' flag avoids redundant invocation.
    func disable() async {
        guard isLoggingEnabled else {
            DebugPrint.log("NETWORK SPECTATOR: Monitoring was inactive.")
            return
        }
        await stopSession()
        logContainer.stopProjectingUpdates()
        isLoggingEnabled = false
        DebugPrint.log("NETWORK SPECTATOR: Monitoring stopped.")
    }
    
    /// Clears current list of items. This does not stop the monitoring.
    func clear() async {
        guard isLoggingEnabled else {
            logContainer.resetProjection()
            return
        }
        
        logContainer.startProjectingUpdates()
        await restartSession()
    }
    
    private func startSession() async {
        await logStore.start()
        NetworkInterceptor.shared.enable()
        await LogHistoryManager.shared.startObserving()
    }
    
    private func stopSession() async {
        NetworkInterceptor.shared.disable()
        await logStore.deactivate()
        await LogHistoryManager.shared.finalizeAndStopObserving()
        await logStore.stop()
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
    enum SetupMode {
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
