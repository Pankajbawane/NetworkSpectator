//
//  NetworkLogContainer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI
import NetworkSpectatorCore

/// Manages network log updates and publishes on MainActor.
/// Communicates with UI layer for updates.
@MainActor
package final class NetworkLogContainer: ObservableObject, Sendable {
    /// Singleton.
    package static let shared = NetworkLogContainer()
    
    private let logStore: any NetworkLogStoring
    
    /// Items on the MainActor to update on UI layer.
    @Published package private(set) var items: [LogItem] = []
    
    private var indexByID: [UUID: Int] = [:]
    
    /// Task to observe item updates from the store actor.
    private var itemUpdateTask: Task<Void, Never>?
    
    package init(logStore: any NetworkLogStoring = NetworkLogStore.shared) {
        self.logStore = logStore
    }
    
    package func latestItem(for id: UUID) -> LogItem? {
        guard let index = indexByID[id], items.indices.contains(index) else {
            return nil
        }
        return items[index]
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
    
    package func startProjectingUpdates() {
        reset()
        startObservingUpdates()
    }
    
    package func stopProjectingUpdates() {
        stopObservingUpdates()
        reset()
    }
    
    package func resetProjection() {
        reset()
    }
    
    private func reset() {
        itemUpdateTask?.cancel()
        itemUpdateTask = nil
        items = []
        indexByID = [:]
    }
    
    /// Cancels ongoing observation of network log updates.
    private func stopObservingUpdates() {
        // Cancel observation immediately to prevent batches arriving after stop is called.
        itemUpdateTask?.cancel()
        itemUpdateTask = nil
    }
}
