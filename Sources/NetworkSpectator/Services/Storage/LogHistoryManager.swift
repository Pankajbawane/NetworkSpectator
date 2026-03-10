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
/// Periodically snapshots items from `NetworkLogStore` and persists them.
/// All disk I/O runs on the actor's serial executor, off the main thread.
actor LogHistoryManager {

    // MARK: - Dependencies

    private let storage: LogHistoryStorage
    private let itemProvider: @Sendable () async -> [LogItem]

    // MARK: - Session State

    private var sessionStartTime: Date?
    private var currentKey: String?

    // MARK: - Debounce State

    private var writeTask: Task<Void, Never>?
    private let debounceInterval: Duration

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

    init(storage: LogHistoryStorage = LogHistoryStorage(),
         debounceInterval: Duration = .seconds(2),
         itemProvider: @escaping @Sendable () async -> [LogItem] = LogHistoryManager.defaultItemProvider) {
        self.storage = storage
        self.debounceInterval = debounceInterval
        self.itemProvider = itemProvider
        observeAppLifecycle()
    }

    // MARK: - Observation Lifecycle

    /// Marks the session as active and records the start time.
    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        sessionStartTime = Date()
    }

    /// Cancels any pending writes and resets observation state.
    func stopObserving() {
        isObserving = false
        writeTask?.cancel()
        writeTask = nil
    }

    /// Immediately persists the current session, resets state, and stops observing.
    func finalizeAndStopObserving() async {
        await finalizeSession()
        stopObserving()
    }

    /// Schedules a debounced persist. Called by `NetworkLogContainer` after applying
    /// a batch of updates to notify that new data is available.
    func schedulePersist() {
        guard isObserving else { return }
        scheduleDebouncedWrite()
    }

    /// Immediately persists the current session and resets state.
    func finalizeSession() async {
        writeTask?.cancel()
        writeTask = nil
        await persistCurrentSession()
        resetSession()
        isObserving = false
    }

    // MARK: - Debounce

    private func scheduleDebouncedWrite() {
        writeTask?.cancel()
        let interval = debounceInterval
        writeTask = Task { [weak self] in
            do {
                try await Task.sleep(for: interval)
            } catch {
                return // Cancelled
            }
            await self?.persistCurrentSession()
        }
    }

    // MARK: - Persistence

    private func persistCurrentSession() async {
        let items = await itemProvider()
        guard !items.isEmpty, let start = sessionStartTime else { return }

        let end = items.last?.finishTime ?? items.last?.startTime ?? start

        let data = try? JSONEncoder().encode(items)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useBytes]
        formatter.includesUnit = true

        let size = formatter.string(fromByteCount: Int64(data?.count ?? 0))

        let newKey = "\(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end)) | Total: \(items.count) | Size: " + size

        // If key changed, remove the old file
        if let oldKey = currentKey, oldKey != newKey {
            storage.delete(forKey: oldKey)
        }

        storage.save(items, forKey: newKey)
        currentKey = newKey
    }

    private func resetSession() {
        sessionStartTime = nil
        currentKey = nil
    }

    // MARK: - App Lifecycle

    private nonisolated func observeAppLifecycle() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.finalizeSession() }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.finalizeSession() }
        }
        #elseif canImport(AppKit)
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.finalizeSession() }
        }
        #endif
    }
}
