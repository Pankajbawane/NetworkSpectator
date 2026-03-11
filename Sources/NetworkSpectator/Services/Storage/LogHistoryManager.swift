//
//  LogHistoryManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 03/03/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Manages session-based persistence of log items to disk.
/// Periodically snapshots items from `NetworkLogStore` and persists them via debounced writes.
/// All disk I/O runs on the actor's serial executor, off the main thread.
actor LogHistoryManager {

    // MARK: - Dependencies

    private let storage: LogHistoryStorage
    private let itemProvider: @Sendable () async -> [LogItem]

    // MARK: - Session State

    private var sessionStartTime: Date?
    private var sessionKey: String?

    // MARK: - Debounce State

    private var writeTask: Task<Void, Never>?
    private let debounceInterval: Duration
    private var observeTask: Task<Void, Never>?

    // MARK: - Observation State

    private var isObserving: Bool = false

    // MARK: - Date Formatting

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Singleton

    static let shared = LogHistoryManager()

    private static let defaultItemProvider: @Sendable () async -> [LogItem] = {
        await NetworkLogStore.shared.snapshot()
    }

    private init() {
        self.storage = LogHistoryStorage()
        self.debounceInterval = .seconds(2)
        self.itemProvider = LogHistoryManager.defaultItemProvider
        observeAppLifecycle()
    }

    /// Initializer with injectable dependencies.
    init(storage: LogHistoryStorage,
         debounceInterval: Duration = .seconds(2),
         itemProvider: @escaping @Sendable () async -> [LogItem]) {
        self.storage = storage
        self.debounceInterval = debounceInterval
        self.itemProvider = itemProvider
    }

    // MARK: - Observation Lifecycle

    /// Marks the session as active, records the start time, and begins observing batch updates.
    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        sessionStartTime = Date()

        // Observe batched updates from the network log store, debouncing writes.
        observeTask = Task {
            for await _ in await NetworkLogStore.shared.batchUpdates() {
                guard !Task.isCancelled else { break }
                schedulePersist()
            }
        }
    }

    /// Cancels any pending writes and observation, resets observation state.
    func stopObserving() {
        isObserving = false
        observeTask?.cancel()
        observeTask = nil
        writeTask?.cancel()
        writeTask = nil
    }

    /// Immediately persists the current session, resets state, and stops observing.
    func finalizeAndStopObserving() async {
        await persistCurrentSession()
        resetSession()
        stopObserving()
    }

    /// Immediately persists the current session and resets session data.
    /// Does not stop observation — use `stopObserving()` or `finalizeAndStopObserving()` for that.
    func finalizeSession() async {
        writeTask?.cancel()
        writeTask = nil
        await persistCurrentSession()
        resetSession()
    }

    // MARK: - Debounce

    /// Schedules a debounced persist. Exposed as internal for testability via `@testable import`.
    func schedulePersist() {
        guard isObserving else { return }
        scheduleDebouncedWrite()
    }

    private func scheduleDebouncedWrite() {
        writeTask?.cancel()
        let interval = debounceInterval
        writeTask = Task {
            do {
                try await Task.sleep(for: interval)
            } catch {
                return // Cancelled
            }
            await self.persistCurrentSession()
        }
    }

    // MARK: - Persistence

    private func persistCurrentSession() async {
        let items = await itemProvider()
        guard !items.isEmpty, let start = sessionStartTime else { return }

        guard let data = try? JSONEncoder().encode(items) else { return }

        let end = items.last?.finishTime ?? items.last?.startTime ?? start
        let size = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .binary)

        let newKey = "\(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end)) | Total: \(items.count) | Size: \(size)"

        // If key changed, remove the old file
        if let oldKey = sessionKey, oldKey != newKey {
            storage.delete(forKey: oldKey)
        }

        storage.save(data, forKey: newKey)
        sessionKey = newKey
    }

    private func resetSession() {
        sessionStartTime = nil
        sessionKey = nil
    }

    // MARK: - App Lifecycle

    private nonisolated func observeAppLifecycle() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { _ in
            Task { await self.finalizeSession() }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { _ in
            Task { await self.finalizeSession() }
        }
        #elseif canImport(AppKit)
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { _ in
            Task { await self.finalizeSession() }
        }
        #endif
    }
}
