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
    }
    
    /// Disables monitoring and logging. 'isLoggingEnabled' flag avoids redudant invocation.
    func disable() {
        guard isLoggingEnabled else {
            DebugPrint.log("NETWORK SPECTATOR: Monitoring was inactive.")
            return
        }
        URLProtocol.unregisterClass(NetworkURLProtocol.self)
        URLSessionConfiguration.disableNetworkMonitoring()
        stop()
        isLoggingEnabled = false
        DebugPrint.log("NETWORK SPECTATOR: Monitoring stopped.")
    }

    /// Starts observing updates from the network log store.
    private func startObservingUpdates() {
        itemUpdateTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // Iterate the async stream produced by the LogStore
            for await updatedItems in await NetworkLogStore.shared.itemUpdates() {
                if Task.isCancelled { break }
                // Hop to the main actor to update published state
                switch updatedItems {
                case .append(let item):
                    self.items.append(item)
                case .update(let item, let index):
                    // Updated LogItem
                    if index < self.items.count, self.items[index].id == item.id {
                        self.items[index] = item
                    } else {
                        // Recovery - If item not found, treat as new
                        self.items.append(item)
                    }
                }
            }
        }
    }

    /// Cancels ongoing observation of network log updates.
    private func stop() {
        itemUpdateTask?.cancel()
        itemUpdateTask = nil
        items.removeAll()

        Task {
            await NetworkLogStore.shared.stop()
        }
    }
    
    /// Clears current list of items. This does not stop the monitoring.
    func clear() {
        items.removeAll()
        Task {
            await NetworkLogStore.shared.clear()
        }
    }
}

/// LogStore actor for thread-safe management and streaming of network log items.
internal actor NetworkLogStore {
    
    enum ItemStream {
        case append(LogItem)
        case update(LogItem, Int)
    }
    
    /// Cache to track which items have been added.
    private var cache: [UUID: Int] = [:]
    
    private var continuation: AsyncStream<ItemStream>.Continuation?
    
    /// Buffer updates that arrive before a continuation is registered.
    private var pending: [ItemStream] = []
    
    /// Singleton.
    static let shared = NetworkLogStore()

    private init() { }

    func itemUpdates() -> AsyncStream<ItemStream> {
        AsyncStream<ItemStream> { [weak self] continuation in
            
            guard let self else {
                continuation.finish()
                return
            }
            Task {
                await storeContinuation(continuation)
            }
        }
    }
    
    func storeContinuation(_ continuation: AsyncStream<ItemStream>.Continuation) {
        if self.continuation != nil {
            self.continuation?.finish()
        }
        self.continuation = continuation
        // Deliver any pending updates that were buffered before a subscriber attached.
        if !pending.isEmpty {
            for update in pending {
                self.continuation?.yield(update)
            }
            pending.removeAll()
        }
    }

    /// Adds or updates an item and notifies LogContainer.
    func add(_ item: LogItem) {
        let update: ItemStream
        
        if let index = cache[item.id] {
            // Item exists - send update
            update = .update(item, index)
        } else {
            // New item - add to cache and send append
            cache[item.id] = cache.count
            update = .append(item)
        }

        if let continuation {
            continuation.yield(update)
        } else {
            pending.append(update)
        }
    }

    /// Disables the store and finishes all active streams.
    func stop() {
        continuation?.finish()
        continuation = nil
        pending.removeAll()
        cache.removeAll()
    }
    
    func clear() {
        cache.removeAll()
        pending.removeAll()
    }
}
