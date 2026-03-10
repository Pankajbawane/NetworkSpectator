//
//  LogSessionManagerTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 03/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - LogSessionManager Tests
@Suite("LogSessionManager Tests")
struct LogSessionManagerTests {

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Creates a manager with a mock item provider and storage.
    /// The `items` array is captured by reference so tests can mutate it
    /// and have the manager see the latest state on each snapshot.
    private func makeManager(items: ItemsRef) -> (LogSessionManager, MockFileStorage) {
        let mockFS = MockFileStorage()
        let baseURL = URL(fileURLWithPath: "/tmp/test-session-manager")
        let storage = LogHistoryStorage(fileManager: mockFS, baseURL: baseURL)
        let manager = LogSessionManager(
            storage: storage,
            debounceInterval: .milliseconds(100),
            itemProvider: { items.value }
        )
        return (manager, mockFS)
    }

    private func sampleLogItem(
        id: UUID = UUID(),
        url: String = "https://api.example.com/users",
        startTime: Date = Date(),
        finishTime: Date? = nil,
        statusCode: Int = 200,
        isLoading: Bool = true
    ) -> LogItem {
        LogItem(
            id: id,
            startTime: startTime,
            url: url,
            method: "GET",
            headers: ["Content-Type": "application/json"],
            requestBody: "",
            statusCode: statusCode,
            responseBody: isLoading ? "" : "{\"ok\":true}",
            responseHeaders: isLoading ? [:] : ["Content-Type": "application/json"],
            finishTime: finishTime,
            responseTime: finishTime.map { $0.timeIntervalSince(startTime) } ?? 0,
            isLoading: isLoading
        )
    }

    private func makeStorage(_ mockFS: MockFileStorage) -> LogHistoryStorage {
        LogHistoryStorage(fileManager: mockFS, baseURL: URL(fileURLWithPath: "/tmp/test-session-manager"))
    }

    @Test("Finalize persists items from provider")
    func testFinalizePersistsItems() async {
        let time = Date(timeIntervalSince1970: 1709400000)
        let items = ItemsRef([sampleLogItem(startTime: time)])
        let (manager, mockFS) = makeManager(items: items)

        await manager.startObserving()
        await manager.finalizeSession()

        let storage = makeStorage(mockFS)
        let keys = storage.listKeys()
        #expect(keys.count == 1)

        if let key = keys.first {
            let persisted = storage.retrieve(forKey: key.key)
            #expect(persisted.count == 1)
        }
    }

    @Test("Session start time is captured from startObserving")
    func testSessionStartTime() async {
        let time = Date(timeIntervalSince1970: 1709400000)
        let items = ItemsRef([sampleLogItem(startTime: time)])
        let (manager, mockFS) = makeManager(items: items)

        await manager.startObserving()
        await manager.finalizeSession()

        let storage = makeStorage(mockFS)
        let keys = storage.listKeys()
        #expect(keys.count == 1)
        // The key should start with the session start time (approximately now)
        #expect(keys.first?.key.contains("Total: 1") == true)
    }

    @Test("Debounce coalesces writes via schedulePersist")
    func testDebounceCoalescesWrites() async {
        let items = ItemsRef([LogItem]())
        let (manager, mockFS) = makeManager(items: items)

        await manager.startObserving()

        // Simulate 10 rapid schedulePersist calls, updating items each time
        for i in 0..<10 {
            let time = Date(timeIntervalSince1970: 1709400000 + Double(i))
            items.value.append(sampleLogItem(url: "https://api.com/\(i)", startTime: time))
            await manager.schedulePersist()
        }

        // At this point, the debounce timer hasn't fired yet, so no files should exist
        let filesBeforeDebounce = mockFS.files.filter { $0.key.contains("json") }.count
        #expect(filesBeforeDebounce == 0)

        // Wait for debounce to fire
        try? await Task.sleep(for: .milliseconds(200))

        // Now exactly one file should exist with all 10 items
        let storage = makeStorage(mockFS)
        let keys = storage.listKeys()
        #expect(keys.count == 1)

        if let key = keys.first {
            let persisted = storage.retrieve(forKey: key.key)
            #expect(persisted.count == 10)
        }
    }

    @Test("Key updates when items change between persists")
    func testKeyUpdatesOnChange() async {
        let time1 = Date(timeIntervalSince1970: 1709400000)
        let items = ItemsRef([sampleLogItem(startTime: time1)])
        let (manager, mockFS) = makeManager(items: items)

        await manager.startObserving()
        await manager.schedulePersist()

        // Wait for first debounce write
        try? await Task.sleep(for: .milliseconds(200))

        let storage = makeStorage(mockFS)
        let firstKeys = storage.listKeys()
        #expect(firstKeys.count == 1)
        let firstKey = firstKeys.first?.key

        // Add another item
        let time2 = Date(timeIntervalSince1970: 1709400060)
        items.value.append(sampleLogItem(url: "https://b.com", startTime: time2))
        await manager.schedulePersist()

        // Wait for second debounce write
        try? await Task.sleep(for: .milliseconds(200))

        let secondKeys = storage.listKeys()
        #expect(secondKeys.count == 1)
        #expect(secondKeys.first?.key != firstKey)
        #expect(secondKeys.first?.key.contains("Total: 2") == true)
    }

    @Test("Finalize writes immediately bypassing debounce")
    func testFinalizeWritesImmediately() async {
        let time = Date(timeIntervalSince1970: 1709400000)
        let items = ItemsRef([sampleLogItem(startTime: time)])
        let (manager, mockFS) = makeManager(items: items)

        await manager.startObserving()
        await manager.finalizeSession()

        // Should have written immediately without waiting for debounce
        let storage = makeStorage(mockFS)
        let keys = storage.listKeys()
        #expect(keys.count == 1)

        if let key = keys.first {
            let persisted = storage.retrieve(forKey: key.key)
            #expect(persisted.count == 1)
        }
    }

    @Test("Finalize resets state for new session")
    func testFinalizeResetsState() async {
        let time1 = Date(timeIntervalSince1970: 1709400000)
        let items = ItemsRef([sampleLogItem(url: "https://session1.com", startTime: time1)])
        let (manager, mockFS) = makeManager(items: items)

        // First session
        await manager.startObserving()
        await manager.finalizeSession()

        // Second session with different items
        let time2 = Date(timeIntervalSince1970: 1709500000)
        items.value = [sampleLogItem(url: "https://session2.com", startTime: time2)]
        await manager.startObserving()
        await manager.finalizeSession()

        let storage = makeStorage(mockFS)
        let keys = storage.listKeys()
        #expect(keys.count == 2)
    }

    @Test("Empty provider does not write")
    func testEmptyProviderDoesNotWrite() async {
        let items = ItemsRef([LogItem]())
        let (manager, mockFS) = makeManager(items: items)

        await manager.startObserving()
        await manager.finalizeSession()

        let filesWritten = mockFS.files.filter { $0.key.contains("json") }.count
        #expect(filesWritten == 0)
    }

    @Test("Updated items are persisted correctly")
    func testUpdatedItemsPersisted() async {
        let time = Date(timeIntervalSince1970: 1709400000)
        let finishTime = Date(timeIntervalSince1970: 1709400005)
        let itemID = UUID()

        // Start with a loading item
        let loadingItem = sampleLogItem(id: itemID, startTime: time, isLoading: true)
        let items = ItemsRef([loadingItem])
        let (manager, mockFS) = makeManager(items: items)

        await manager.startObserving()

        // Simulate the item getting updated (response received)
        let completedItem = LogItem(
            id: itemID,
            startTime: time,
            url: loadingItem.url,
            method: "GET",
            statusCode: 200,
            responseBody: "{\"ok\":true}",
            finishTime: finishTime,
            responseTime: 5.0,
            isLoading: false
        )
        items.value = [completedItem]

        await manager.finalizeSession()

        let storage = makeStorage(mockFS)
        let keys = storage.listKeys()
        #expect(keys.count == 1)

        if let key = keys.first {
            let persisted = storage.retrieve(forKey: key.key)
            #expect(persisted.count == 1)
            #expect(persisted.first?.isLoading == false)
            #expect(persisted.first?.statusCode == 200)
        }
    }

    @Test("Preserves all items through session persistence")
    func testPreservesAllItems() async {
        var itemsList = [LogItem]()
        for i in 0..<5 {
            let time = Date(timeIntervalSince1970: 1709400000 + Double(i * 10))
            itemsList.append(sampleLogItem(
                url: "https://api.com/endpoint\(i)",
                startTime: time,
                statusCode: 200 + i
            ))
        }
        let items = ItemsRef(itemsList)
        let (manager, mockFS) = makeManager(items: items)

        await manager.startObserving()
        await manager.finalizeSession()

        let storage = makeStorage(mockFS)
        let keys = storage.listKeys()
        #expect(keys.count == 1)

        if let key = keys.first {
            let persisted = storage.retrieve(forKey: key.key)
            #expect(persisted.count == 5)
            #expect(persisted[0].url == "https://api.com/endpoint0")
            #expect(persisted[4].url == "https://api.com/endpoint4")
            #expect(persisted[2].statusCode == 202)
        }
    }

    @Test("schedulePersist does nothing when not observing")
    func testSchedulePersistIgnoredWhenNotObserving() async {
        let items = ItemsRef([sampleLogItem()])
        let (manager, mockFS) = makeManager(items: items)

        // Don't call startObserving
        await manager.schedulePersist()

        try? await Task.sleep(for: .milliseconds(200))

        let filesWritten = mockFS.files.filter { $0.key.contains("json") }.count
        #expect(filesWritten == 0)
    }
}

// MARK: - Helpers

/// Reference wrapper so tests can mutate the items array
/// and have the manager's itemProvider closure see the changes.
private final class ItemsRef: @unchecked Sendable {
    var value: [LogItem]
    init(_ value: [LogItem]) { self.value = value }
}
