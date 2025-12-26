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
        guard !isLoggingEnabled else { return }
        URLProtocol.registerClass(NetworkURLProtocol.self)
        URLSessionConfiguration.enableNetworkMonitoring()
        startObservingUpdates()
        isLoggingEnabled = true
        DebugPrint.log("NETWORK SPECTATOR: Logging initiated.")
    }
    
    /// Disables monitoring and logging. 'isLoggingEnabled' flag avoids redudant invocation.
    func disable() {
        guard isLoggingEnabled else { return }
        URLProtocol.unregisterClass(NetworkURLProtocol.self)
        URLSessionConfiguration.disableNetworkMonitoring()
        stop()
        isLoggingEnabled = false
        DebugPrint.log("NETWORK SPECTATOR: Logging stopped.")
    }

    /// Starts observing updates from the network log store.
    private func startObservingUpdates() {
        itemUpdateTask = Task { [weak self] in
            guard let self else { return }

            // Iterate the async stream produced by the LogStore
            for await updatedItems in await NetworkLogStore.shared.itemUpdates() {
                if Task.isCancelled { break }
                // Hop to the main actor to update published state
                self.items = updatedItems
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

    /// List of logged items.
    private var items: [LogItem] = []
    
    /// Cache to update the items.
    private var cache: [UUID: Int] = [:]
    
    /// AsyncStream to stream the item updates to the UI layer.
    private var continuations: [UUID: AsyncStream<[LogItem]>.Continuation] = [:]
    
    /// Singleton.
    static let shared = NetworkLogStore()

    private init() {}

    /// Provides a stream of live updates to the item list.
    func itemUpdates() -> AsyncStream<[LogItem]> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let id = UUID()

            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.removeContinuation(id)
                }
            }

            // Store continuation and yield current items synchronously within the actor
            Task {
                await self.storeContinuation(continuation, for: id)
                await continuation.yield(self.items)
            }
        }
    }

    private func storeContinuation(_ continuation: AsyncStream<[LogItem]>.Continuation, for id: UUID) {
        continuations[id] = continuation
    }

    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }

    /// Adds or updates an item and notifies all observers.
    func add(_ item: LogItem) {
        if let index = cache[item.id] {
            items[index] = item
            cache[item.id] = nil
        } else {
            cache[item.id] = items.count
            items.append(item)
        }

        for continuation in continuations.values {
            continuation.yield(items)
        }
    }

    /// Disables the store and finishes all active streams.
    func stop() {
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }
    
    func clear() {
        items.removeAll()
        cache.removeAll()
    }
}
