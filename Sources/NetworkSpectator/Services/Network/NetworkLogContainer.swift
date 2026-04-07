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
    
    /// Items on the MainActor to update on UI layer.
    @Published private(set) var items: [LogItem] = []
    
    var indexByID: [UUID: Int] = [:]
    
    /// Task to observe item updates from the store actor.
    private var itemUpdateTask: Task<Void, Never>?
    
    /// Safeguard against redundant activations. Avoids multiple calls to start/stop monitoring.
    @Published private(set) var isLoggingEnabled: Bool = false
    
    /// Tracks how monitoring was initialized, programmatically or UI.
    private(set) var setupMode: SetupMode = .none

    private init() { }
    
    /// When Monitoring state to be handled by UI on demand.
    func enableOnDemand() {
        setupMode = .onDemand
        // if preference was stored.
        if PreferenceStorage(preference: .monitoring).retrieve() {
            enable()
        }
    }
    
    /// When enabled only with UI.
    func enableInternally() {
        if setupMode == .none {
            setupMode = .uiInitiated
        }
        enable()
    }
    
    /// Enables monitoring and logging. 'isLoggingEnabled' flag avoids redundant invocation.
    func enable() {
        guard !isLoggingEnabled else {
            DebugPrint.log("NETWORK SPECTATOR: Monitoring was already active.")
            return
        }
        if setupMode == .none {
            setupMode = .started
        }
        NetworkInterceptor.shared.enable()
        startObservingUpdates()
        isLoggingEnabled = true
        DebugPrint.log("NETWORK SPECTATOR: Logging initiated.")
        Task { await LogHistoryManager.shared.startObserving() }
    }
    
    /// Disables monitoring and logging. 'isLoggingEnabled' flag avoids redundant invocation.
    func disable() {
        guard isLoggingEnabled else {
            DebugPrint.log("NETWORK SPECTATOR: Monitoring was inactive.")
            return
        }
        Task { await LogHistoryManager.shared.finalizeAndStopObserving() }
        NetworkInterceptor.shared.disable()
        stop()
        isLoggingEnabled = false
        DebugPrint.log("NETWORK SPECTATOR: Monitoring stopped.")
    }
    
    /// Starts observing batched updates from the network log store for UI updates.
    private func startObservingUpdates() {
        itemUpdateTask = Task { @MainActor [weak self] in
            guard self != nil else { return }
            
            for await batch in await NetworkLogStore.shared.batchUpdates() {
                guard !Task.isCancelled, let self else { break }
                self.applyBatch(batch)
            }
        }
    }
    
    /// Applies a batch of updates to `items` in a single mutation,
    /// triggering only one `@Published` change notification.
    private func applyBatch(_ batch: NetworkLogStore.ItemUpdate) {

        // Single published mutation per batch
        items = batch.items
        indexByID = batch.indices
    }
    
    private func reset() {
        itemUpdateTask?.cancel()
        itemUpdateTask = nil
        items = []
    }
    
    /// Cancels ongoing observation of network log updates.
    private func stop() {
        // Cancel observation immediately to prevent batches arriving after stop is called.
        itemUpdateTask?.cancel()
        itemUpdateTask = nil
        Task {
            await NetworkLogStore.shared.stop()
        }
        items = []
    }
    
    /// Clears current list of items. This does not stop the monitoring.
    func clear() {
        reset()
        Task {
            await LogHistoryManager.shared.finalizeAndStopObserving()
            await NetworkLogStore.shared.stop()
            // Restart observation on MainActor since startObservingUpdates
            // mutates @MainActor-isolated state (itemUpdateTask).
            await MainActor.run { [weak self] in
                self?.startObservingUpdates()
            }
            await LogHistoryManager.shared.startObserving()
        }
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

/// LogStore actor for thread-safe management and streaming of network log items.
internal actor NetworkLogStore {
    
    /// Represents an individual update item.
    struct ItemUpdate: Sendable {
        let items: [LogItem]
        let indices: [UUID: Int]
    }
    
    /// The authoritative list of all log items for the current session.
    private var items: [LogItem] = []
    
    /// Maps item ID to index in `items` for O(1) lookups.
    private var indexByID: [UUID: Int] = [:]
    
    /// Active subscriber continuations keyed by unique subscriber ID.
    /// Each subscriber receives batches of updates independently.
    private var continuations: [UUID: AsyncStream<ItemUpdate>.Continuation] = [:]
    
    /// Buffer of updates that accumulate between batch flushes.
    private var pendingUpdatesCount: Int = 0
    
    /// Task that manages the time-based flush interval.
    private var flushTask: Task<Void, Never>?
    
    /// Maximum number of updates to buffer before flushing immediately.
    private let maxBatchSize: Int = 50
    
    /// Time window to coalesce updates before flushing.
    private let flushInterval: Duration = .milliseconds(100)
    
    /// Singleton.
    static let shared = NetworkLogStore()

    private init() { }

    /// Creates a new `AsyncStream` subscription that delivers batched updates.
    /// Multiple subscribers are supported; each receives all future batches independently.
    func batchUpdates() -> AsyncStream<ItemUpdate> {
        let subscriberID = UUID()
        let (stream, continuation) = AsyncStream<ItemUpdate>.makeStream()
        
        continuations[subscriberID] = continuation
        
        continuation.onTermination = { @Sendable _ in
            Task { await self.removeContinuation(for: subscriberID) }
        }
        
        return stream
    }
    
    private func removeContinuation(for id: UUID) {
        continuations.removeValue(forKey: id)
    }

    /// Returns a snapshot of the current items for persistence.
    func snapshot() -> [LogItem] {
        items
    }
    
    /// Returns the count of current items.
    var itemCount: Int {
        items.count
    }

    /// Adds or updates an item. Updates are buffered and delivered in batches
    /// to reduce the frequency of actor-to-MainActor hops.
    func add(_ item: LogItem) {
        
        if let index = indexByID[item.id] {
            items[index] = item
        } else {
            indexByID[item.id] = items.count
            items.append(item)
        }
        
        pendingUpdatesCount += 1
        
        // Flush immediately if buffer exceeds threshold.
        if pendingUpdatesCount >= maxBatchSize {
            flushBuffer()
        } else {
            scheduleFlush()
        }
    }
    
    /// Schedules a time-delayed flush. Resets the timer on each call so that
    /// rapid successive updates are coalesced into a single batch.
    private func scheduleFlush() {
        // Reset the timer on each call so rapid successive updates are coalesced into a single batch.
        flushTask?.cancel()
        let interval = flushInterval
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            await self?.flushBuffer()
        }
    }
    
    /// Sends buffered updates to all subscribers as a single batch.
    private func flushBuffer() {
        flushTask?.cancel()
        flushTask = nil
        guard !items.isEmpty else { return }
        
        pendingUpdatesCount = 0
        
        for continuation in continuations.values {
            let batch = ItemUpdate(items: items, indices: indexByID)
            continuation.yield(batch)
        }
    }

    /// Disables the store and finishes all active streams.
    fileprivate func stop() {
        flushBuffer()
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations = [:]
        clear()
    }
    
    fileprivate func clear() {
        items = []
        indexByID = [:]
        pendingUpdatesCount = 0
        flushTask?.cancel()
        flushTask = nil
    }
}
