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
internal final class NetworkLogContainer: ObservableObject, Sendable {
    /// Singleton.
    static let shared = NetworkLogContainer()
    
    /// Items on the MainActor to update on UI layer.
    @Published var items: [LogItem] = []
    
    /// Lookup from LogItem.id to index in `items` for O(1) updates.
    private var indexByID: [UUID: Int] = [:]
    
    /// Task to observe item updates from the store actor.
    private var itemUpdateTask: Task<Void, Never>?
    
    /// Safeguard againts redudant calls. Avoids multiple calls to start/stop monitoring.
    private var isLoggingEnabled: Bool = false
    
    private init() { }
    
    /// Enables monitoring and logging. 'isLoggingEnabled' flag avoids redudant invocation.
    func enable() {
        guard !isLoggingEnabled else {
            DebugPrint.log("NETWORK SPECTATOR: Monitoring was already active.")
            return
        }
        URLProtocol.registerClass(NetworkURLProtocol.self)
        URLSessionConfiguration.enableNetworkMonitoring()
        startObservingUpdates()
        isLoggingEnabled = true
        DebugPrint.log("NETWORK SPECTATOR: Logging initiated.")
        Task { await LogHistoryManager.shared.startObserving() }
    }
    
    /// Disables monitoring and logging. 'isLoggingEnabled' flag avoids redudant invocation.
    func disable() {
        guard isLoggingEnabled else {
            DebugPrint.log("NETWORK SPECTATOR: Monitoring was inactive.")
            return
        }
        Task { await LogHistoryManager.shared.finalizeAndStopObserving() }
        URLProtocol.unregisterClass(NetworkURLProtocol.self)
        URLSessionConfiguration.disableNetworkMonitoring()
        stop()
        isLoggingEnabled = false
        DebugPrint.log("NETWORK SPECTATOR: Monitoring stopped.")
    }
    
    /// Notifies `LogHistoryManager` that items changed so it can schedule a debounced persist.
    private func notifyHistoryManager() {
        Task { await LogHistoryManager.shared.schedulePersist() }
    }
    
    /// Starts observing batched updates from the network log store for UI updates.
    private func startObservingUpdates() {
        itemUpdateTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            for await batch in await NetworkLogStore.shared.batchUpdates() {
                if Task.isCancelled { break }
                self.applyBatch(batch)
            }
        }
    }
    
    /// Applies a batch of updates to `items` in a single mutation,
    /// triggering only one `@Published` change notification.
    private func applyBatch(_ batch: [NetworkLogStore.ItemUpdate]) {
        for update in batch {
            switch update {
            case .append(let item):
                indexByID[item.id] = items.count
                items.append(item)
            case .update(let item, let id):
                if let index = indexByID[id], index < items.count, items[index].id == id {
                    items[index] = item
                }
            }
        }
        notifyHistoryManager()
    }
    
    private func reset() {
        itemUpdateTask?.cancel()
        itemUpdateTask = nil
        items.removeAll()
        indexByID.removeAll()
    }
    
    /// Cancels ongoing observation of network log updates.
    private func stop() {
        reset()
        Task {
            await NetworkLogStore.shared.stop()
        }
    }
    
    /// Clears current list of items. This does not stop the monitoring.
    func clear() {
        reset()
        Task {
            await LogHistoryManager.shared.finalizeAndStopObserving()
            await NetworkLogStore.shared.stop()
            // Restart observation for both UI and history persistence.
            startObservingUpdates()
            await LogHistoryManager.shared.startObserving()
        }
    }
}

internal actor NetworkLogStore {
    
    /// Represents an individual update to a log item.
    enum ItemUpdate: Sendable {
        /// A new item was logged.
        case append(LogItem)
        /// An existing item was updated (e.g. response received). Carries the updated item and its original ID.
        case update(LogItem, UUID)
    }
    
    /// The authoritative list of all log items for the current session.
    private var items: [LogItem] = []
    
    /// Maps item ID to index in `items` for O(1) lookups.
    private var indexByID: [UUID: Int] = [:]
    
    /// Active subscriber continuations keyed by unique subscriber ID.
    /// Each subscriber receives batches of updates independently.
    private var continuations: [UUID: AsyncStream<[ItemUpdate]>.Continuation] = [:]
    
    /// Buffer of updates that accumulate between batch flushes.
    private var buffer: [ItemUpdate] = []
    
    /// Updates that arrive before any subscriber is registered.
    private var pending: [ItemUpdate] = []
    
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
    func batchUpdates() -> AsyncStream<[ItemUpdate]> {
        let subscriberID = UUID()
        let (stream, continuation) = AsyncStream<[ItemUpdate]>.makeStream()
        
        continuations[subscriberID] = continuation
        
        // Deliver any pending updates buffered before a subscriber attached.
        if !pending.isEmpty {
            continuation.yield(pending)
            pending.removeAll()
        }
        
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
        let update: ItemUpdate
        
        if let index = indexByID[item.id] {
            items[index] = item
            update = .update(item, item.id)
        } else {
            indexByID[item.id] = items.count
            items.append(item)
            update = .append(item)
        }

        if continuations.isEmpty {
            pending.append(update)
        } else {
            buffer.append(update)
            
            // Flush immediately if buffer exceeds threshold.
            if buffer.count >= maxBatchSize {
                flushBuffer()
            } else {
                scheduleFlush()
            }
        }
    }
    
    /// Schedules a time-delayed flush. Resets the timer on each call so that
    /// rapid successive updates are coalesced into a single batch.
    private func scheduleFlush() {
        guard flushTask == nil else { return }
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
        guard !buffer.isEmpty else { return }
        
        let batch = buffer
        buffer.removeAll()
        
        for continuation in continuations.values {
            continuation.yield(batch)
        }
    }

    /// Disables the store and finishes all active streams.
    fileprivate func stop() {
        flushBuffer()
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
        clear()
    }
    
    fileprivate func clear() {
        items.removeAll()
        indexByID.removeAll()
        buffer.removeAll()
        pending.removeAll()
        flushTask?.cancel()
        flushTask = nil
    }
}
