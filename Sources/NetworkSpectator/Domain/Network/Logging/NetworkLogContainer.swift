//
//  NetworkLogContainer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

/// Manages network log updates and publishes on MainActor.
/// Communicates with UI layer for updates.
@MainActor
final class NetworkLogContainer: ObservableObject, Sendable {
    /// Singleton.
    static let shared = NetworkLogContainer()
    
    private let logStore: any NetworkLogStoring
    
    /// Items on the MainActor to update on UI layer.
    @Published private(set) var items: [LogItem] = []
    
    private(set) var indexByID: [UUID: Int] = [:]
    
    /// Task to observe item updates from the store actor.
    private var itemUpdateTask: Task<Void, Never>?
    
    /// Safeguard against redundant activations. Avoids multiple calls to start/stop monitoring.
    @Published private(set) var isLoggingEnabled: Bool = false
    
    /// Tracks how monitoring was initialized, programmatically or UI.
    private(set) var setupMode: SetupMode = .none

    init(logStore: any NetworkLogStoring = NetworkLogStore.shared) {
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
        await logStore.start()
        reset()
        startObservingUpdates()
        NetworkInterceptor.shared.enable()
        isLoggingEnabled = true
        DebugPrint.log("NETWORK SPECTATOR: Logging initiated.")
        await LogHistoryManager.shared.startObserving()
    }
    
    /// Disables monitoring and logging. 'isLoggingEnabled' flag avoids redundant invocation.
    func disable() async {
        guard isLoggingEnabled else {
            DebugPrint.log("NETWORK SPECTATOR: Monitoring was inactive.")
            return
        }
        NetworkInterceptor.shared.disable()
        await logStore.deactivate()
        await LogHistoryManager.shared.finalizeAndStopObserving()
        await stop()
        isLoggingEnabled = false
        DebugPrint.log("NETWORK SPECTATOR: Monitoring stopped.")
    }
    
    /// Starts observing batched updates from the network log store for UI updates.
    private func startObservingUpdates() {
        itemUpdateTask = Task { @MainActor [weak self] in
            guard self != nil else { return }
            
            guard let stream = await self?.logStore.updates() else { return }
            
            for await updates in stream {
                guard !Task.isCancelled, let self else { break }
                self.apply(updates)
            }
        }
    }
    
    /// Applies a batch of incremental updates to `items` in a single mutation,
    /// triggering only one `@Published` change notification.
    private func apply(_ updates: [NetworkLogUpdate]) {
        guard !updates.isEmpty else { return }
        
        var updatedItems = items
        var updatedIndices = indexByID
        
        for update in updates {
            switch update {
            case .append(let item):
                updatedIndices[item.id] = updatedItems.count
                updatedItems.append(item)
            case .update(let item, let index):
                guard index < updatedItems.count else { continue }
                updatedItems[index] = item
                updatedIndices[item.id] = index
            case .reset:
                updatedItems = []
                updatedIndices = [:]
            }
        }
        
        items = updatedItems
        indexByID = updatedIndices
    }
    
    private func reset() {
        itemUpdateTask?.cancel()
        itemUpdateTask = nil
        items = []
        indexByID = [:]
    }
    
    /// Cancels ongoing observation of network log updates.
    private func stop() async {
        // Cancel observation immediately to prevent batches arriving after stop is called.
        itemUpdateTask?.cancel()
        itemUpdateTask = nil
        await logStore.stop()
        reset()
    }
    
    /// Clears current list of items. This does not stop the monitoring.
    func clear() async {
        await logStore.deactivate()
        await LogHistoryManager.shared.finalizeAndStopObserving()
        reset()
        await logStore.start()
        startObservingUpdates()
        await LogHistoryManager.shared.startObserving()
    }
}

extension NetworkLogContainer {
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
