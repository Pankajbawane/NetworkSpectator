//
//  NetworkLogContainer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

/// Manages network log updates and publishes.
@MainActor
final class NetworkLogContainer: ObservableObject, Sendable {
    static let shared = NetworkLogContainer()

    @Published var items: [LogItem] = []
    private var itemUpdateTask: Task<Void, Never>?
    private let store = NetworkLogStore.shared
    private var isLoggingEnabled: Bool = false

    private init() {
        
    }
    
    func enable() {
        guard !isLoggingEnabled else { return }
        URLProtocol.registerClass(NetworkURLProtocol.self)
        URLSessionConfiguration.enableNetworkMonitoring()
        startObservingUpdates()
        isLoggingEnabled = true
        DebugPrint.log("NETWORK SPECTATOR: Logging initiated.")
    }
    
    func disable() {
        guard isLoggingEnabled else { return }
        URLProtocol.unregisterClass(NetworkURLProtocol.self)
        URLSessionConfiguration.disableNetworkMonitoring()
        stop()
        isLoggingEnabled = false
        DebugPrint.log("NETWORK SPECTATOR: Logging stopped.")
    }

    /// Adds a new `LogItem` to the log in a concurrent-safe manner.
    func add(_ item: LogItem) {
        Task {
            await store.add(item)
        }
    }

    /// Starts observing updates from the network log container.
    private func startObservingUpdates() {
        itemUpdateTask = Task { [weak self] in
            guard let self else { return }

            // Iterate the async stream produced by the actor
            for await updatedItems in await store.itemUpdates() {
                if Task.isCancelled { break }
                // Hop to the main actor to update published state
                self.updateItems(updatedItems)
            }
        }
    }

    private func updateItems(_ newItems: [LogItem]) {
        self.items = newItems
    }

    /// Cancels ongoing observation of network log updates.
    private func stop() {
        itemUpdateTask?.cancel()
        itemUpdateTask = nil
        items.removeAll()

        Task {
            await store.stop()
        }
    }
    
    func clear() {
        items.removeAll()
        Task {
            await store.clear()
        }
    }
}

/// Container actor for thread-safe management and streaming of network log items.
internal actor NetworkLogStore {

    private var items: [LogItem] = []
    private var cache: [UUID: Int] = [:]
    private var continuations: [UUID: AsyncStream<[LogItem]>.Continuation] = [:]
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
        } else {
            cache[item.id] = items.count
            items.append(item)
        }

        for continuation in continuations.values {
            continuation.yield(items)
        }
    }

    /// Disables the container and finishes all active streams.
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
