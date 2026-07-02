//
//  NetworkLogStore.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/03/26.
//

import Foundation
import os

/// Identifies a specific active logging session.
struct NetworkLogSession: Equatable, Sendable {
    fileprivate let id: UUID
}

/// Represents an incremental network log update.
enum NetworkLogUpdate: Sendable {
    case append(LogItem)
    case update(LogItem, index: Int)
    case reset
}

private final class NetworkLogSessionState: @unchecked Sendable {
    private let session = OSAllocatedUnfairLock<NetworkLogSession?>(initialState: nil)
    
    func start() -> NetworkLogSession {
        let newSession = NetworkLogSession(id: UUID())
        session.withLock { $0 = newSession }
        return newSession
    }
    
    func stop() {
        session.withLock { $0 = nil }
    }
    
    func current() -> NetworkLogSession? {
        session.withLock { $0 }
    }
    
    func isCurrent(_ candidate: NetworkLogSession) -> Bool {
        session.withLock { $0 == candidate }
    }
}

/// Store abstraction used by UI-facing containers.
protocol NetworkLogStoring: Sendable {
    func start() async
    func deactivate() async
    
    /// Returns a stream of future batched delta updates.
    ///
    /// This stream does not replay the current store contents to new subscribers.
    /// Consumers that need a complete live projection must subscribe before the
    /// session starts, then apply every emitted delta in order. A late subscriber
    /// should call `snapshot()` first or it may receive `.update(index:)` events
    /// for items it never saw appended.
    func updates() async -> AsyncStream<[NetworkLogUpdate]>
    func stop() async
}

/// LogStore actor for thread-safe management and streaming of network log items.
internal actor NetworkLogStore: NetworkLogStoring {
    /// The authoritative list of all log items for the current session.
    private var items: [LogItem] = []
    
    /// Maps item ID to index in `items` for O(1) lookups.
    private var indexByID: [UUID: Int] = [:]
    
    /// Active subscriber continuations keyed by unique subscriber ID.
    /// Each subscriber receives batches of updates independently.
    private var continuations: [UUID: AsyncStream<[NetworkLogUpdate]>.Continuation] = [:]
    
    /// Buffer of updates that accumulate between batch flushes.
    private var pendingUpdates: [NetworkLogUpdate] = []
    
    /// Task that manages the time-based flush interval.
    private var flushTask: Task<Void, Never>?
    
    private let sessionState = NetworkLogSessionState()
    
    /// Maximum number of updates to buffer before flushing immediately.
    private let maxBatchSize: Int = 50
    
    /// Time window to coalesce updates before flushing.
    private let flushInterval: Duration = .milliseconds(5)
    
    /// Singleton.
    static let shared = NetworkLogStore()

    private init() { }
    
    nonisolated func currentSession() -> NetworkLogSession? {
        sessionState.current()
    }
    
    /// Starts a new active session and clears any previous session state.
    func start() {
        _ = sessionState.start()
        clear(emitReset: true)
    }
    
    /// Stops accepting new log items without clearing the current snapshot.
    func deactivate() {
        sessionState.stop()
        flushBuffer()
    }

    /// Creates a new `AsyncStream` subscription that delivers future batched delta updates.
    ///
    /// No initial snapshot is emitted. Subscribers are expected to start observing
    /// before `start()` begins a new session, or to rebuild their initial state
    /// from `snapshot()` before consuming this stream.
    func updates() -> AsyncStream<[NetworkLogUpdate]> {
        let subscriberID = UUID()
        let (stream, continuation) = AsyncStream<[NetworkLogUpdate]>.makeStream()
        
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

    /// Adds or updates an item using the store's current session.
    /// Prefer `add(_:session:)` for work that crosses an async boundary.
    func add(_ item: LogItem) {
        guard let session = sessionState.current() else { return }
        add(item, session: session)
    }
    
    /// Adds or updates an item only if it belongs to the active session.
    /// Updates are buffered and delivered as deltas to reduce MainActor work.
    func add(_ item: LogItem, session: NetworkLogSession?) {
        guard let session, sessionState.isCurrent(session) else { return }
        
        if let index = indexByID[item.id] {
            items[index] = item
            pendingUpdates.append(.update(item, index: index))
        } else {
            let index = items.count
            indexByID[item.id] = index
            items.append(item)
            pendingUpdates.append(.append(item))
        }
        
        // Flush immediately if buffer exceeds threshold.
        if pendingUpdates.count >= maxBatchSize {
            flushBuffer()
        } else {
            scheduleFlush()
        }
    }
    
    /// Schedules a time-delayed flush. Resets the timer on each call so that
    /// rapid successive updates are coalesced into a single batch.
    private func scheduleFlush() {
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
        guard !pendingUpdates.isEmpty else { return }
        
        let updates = pendingUpdates
        pendingUpdates = []
        
        for continuation in continuations.values {
            continuation.yield(updates)
        }
    }

    /// Disables the store and finishes all active streams.
    func stop() {
        deactivate()
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations = [:]
        clear(emitReset: false)
    }
    
    private func clear(emitReset: Bool) {
        items = []
        indexByID = [:]
        pendingUpdates = []
        flushTask?.cancel()
        flushTask = nil
        
        guard emitReset else { return }
        for continuation in continuations.values {
            continuation.yield([.reset])
        }
    }
}
