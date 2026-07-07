//
//  NetworkLogStoreTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectator
@testable import NetworkSpectatorCore
@testable import NetworkSpectatorMocking
@testable import NetworkSpectatorLogging

// MARK: - NetworkLogStore Tests
// Tests use the shared singleton and clean up via stop() between tests.
// Tests exercise add, snapshot, itemCount, and update streaming.
@Suite("NetworkLogStore Tests", .serialized)
struct NetworkLogStoreTests {

    // MARK: - Helpers

    private var store: NetworkLogStore { NetworkLogStore.shared }

    private func makeItem(
        id: UUID = UUID(),
        url: String = "https://example.com/api",
        method: String = "GET",
        statusCode: Int = 200,
        isLoading: Bool = true
    ) -> LogItem {
        LogItem(id: id, url: url, method: method, statusCode: statusCode, isLoading: isLoading)
    }

    // MARK: - Add and Snapshot

    @Test("Adding an item makes it available in snapshot")
    func testAddAndSnapshot() async {
        await store.start()
        let item = makeItem()
        await store.add(item)

        let snapshot = await store.snapshot()
        #expect(snapshot.contains(where: { $0.id == item.id }))
    }

    @Test("Adding multiple items increases count")
    func testAddMultipleItems() async {
        await store.start()

        await store.add(makeItem())
        await store.add(makeItem())
        await store.add(makeItem())

        let newCount = await store.itemCount
        #expect(newCount == 3)
    }

    // MARK: - Update Existing Item

    @Test("Adding item with same ID updates instead of duplicating")
    func testUpdateExistingItem() async {
        await store.start()
        let id = UUID()

        let initial = makeItem(id: id, statusCode: 0, isLoading: true)
        await store.add(initial)
        let countAfterAdd = await store.itemCount

        let updated = LogItem(
            id: id,
            url: "https://example.com/api",
            method: "GET",
            statusCode: 200,
            isLoading: false
        )
        await store.add(updated)

        let countAfterUpdate = await store.itemCount
        // Count should not increase when updating same ID
        #expect(countAfterUpdate == countAfterAdd)

        let snapshot = await store.snapshot()
        let foundItem = snapshot.first(where: { $0.id == id })
        #expect(foundItem?.statusCode == 200)
        #expect(foundItem?.isLoading == false)
    }

    // MARK: - Batch Updates Stream

    @Test("updates stream receives appended item after add")
    func testUpdatesStream() async {
        await store.start()
        let stream = await store.updates()

        let item = makeItem()
        await store.add(item)

        // Wait for the flush interval to fire
        try? await Task.sleep(for: .milliseconds(200))

        // Collect the first batch
        var receivedBatch: [NetworkLogUpdate]?
        for await batch in stream {
            receivedBatch = batch
            break
        }

        #expect(receivedBatch != nil)
        let containsAppendedItem = receivedBatch?.contains { update in
            if case .append(let appendedItem) = update {
                return appendedItem.id == item.id
            }
            return false
        }
        #expect(containsAppendedItem == true)
    }

    // MARK: - Snapshot Contains Correct Data

    @Test("Snapshot returns items with correct data")
    func testSnapshotReturnsCorrectData() async {
        await store.start()
        let item = makeItem(url: "https://snapshot-test.com/data", method: "POST", statusCode: 201)
        await store.add(item)

        let snapshot = await store.snapshot()
        let found = snapshot.first(where: { $0.id == item.id })

        #expect(found?.url == "https://snapshot-test.com/data")
        #expect(found?.method == "POST")
        #expect(found?.statusCode == 201)
    }

    // MARK: - Modularization Boundaries

    @Test("Mock-only interception serves mocks without writing to log store")
    func testMockOnlyInterceptionDoesNotWriteToLogStore() async throws {
        try await withMockOnlySession {
            let body = Data(#"{"source":"mock-only"}"#.utf8)
            let mock = Mock(
                method: .GET,
                rule: .url("https://mock-only.example.com/users"),
                response: body,
                headers: ["X-Mock": "true"],
                statusCode: 203,
                error: nil,
                saveLocally: true
            )

            NetworkSpectatorMocking.register(mock)

            let (data, response) = try await URLSession.shared.data(
                from: URL(string: "https://mock-only.example.com/users")!
            )

            #expect(data == body)
            #expect((response as? HTTPURLResponse)?.statusCode == 203)
            #expect(NetworkSpectatorMocking.mocks.contains(mock))

            try? await Task.sleep(for: .milliseconds(100))
            let snapshot = await NetworkLogStore.shared.snapshot()
            #expect(snapshot.isEmpty)
            #expect(NetworkLogStore.shared.currentSession() == nil)
        }
    }

    @Test("Logging exclusions do not block mock-only interception")
    func testLoggingExclusionsDoNotBlockMockOnlyInterception() async throws {
        try await withMockOnlySession {
            let url = "https://excluded.example.com/analytics"
            let rule = LoggingExclusionRule(method: .GET, rule: .url(url), saveLocally: false)
            LoggingExclusionManager.shared.register(request: rule)

            let mock = Mock(
                method: .GET,
                rule: .url(url),
                response: Data("excluded but mocked".utf8),
                headers: [:],
                statusCode: 200,
                error: nil,
                saveLocally: false
            )
            NetworkSpectatorMocking.register(mock)

            let (data, response) = try await URLSession.shared.data(from: URL(string: url)!)

            #expect(String(data: data, encoding: .utf8) == "excluded but mocked")
            #expect((response as? HTTPURLResponse)?.statusCode == 200)
            #expect(await NetworkLogStore.shared.snapshot().isEmpty)
        }
    }

    @Test("Log store rejects writes captured for a stale session")
    func testRejectsStaleSessionWrites() async {
        await store.stop()
        await store.start()
        let staleSession = store.currentSession()
        await store.deactivate()

        await store.add(makeItem(url: "https://stale.example.com", isLoading: false), session: staleSession)

        let snapshot = await store.snapshot()
        #expect(snapshot.isEmpty)
        await store.stop()
    }

    @Test("Log store rejects writes captured before a new session starts")
    func testRejectsPreviousSessionWritesAfterRestart() async {
        await store.stop()
        await store.start()
        let previousSession = store.currentSession()

        await store.start()
        await store.add(makeItem(url: "https://previous.example.com", isLoading: false), session: previousSession)

        let snapshot = await store.snapshot()
        #expect(snapshot.isEmpty)
        await store.stop()
    }

    @Test("Full facade reset clears mocks and logging exclusions")
    func testFullFacadeResetClearsMocksAndLoggingExclusions() async {
        NetworkSpectatorMocking.clearMocks()
        LoggingExclusionManager.shared.clear()
        let mock = Mock(
            method: .GET,
            rule: .url("https://facade.example.com"),
            response: nil as Data?,
            headers: [:],
            statusCode: 200,
            error: nil,
            saveLocally: false
        )
        let exclusion = LoggingExclusionRule(method: .GET, rule: .hostName("facade.example.com"))

        NetworkSpectator.registerMock(for: mock)
        NetworkSpectator.excludeFromLogging(for: exclusion)
        NetworkSpectator.reset()

        #expect(NetworkSpectatorMocking.mocks.isEmpty)
        #expect(LoggingExclusionManager.shared.rules.isEmpty)
    }

    private func withMockOnlySession(_ operation: () async throws -> Void) async throws {
        await store.stop()
        LoggingExclusionManager.shared.clear()
        NetworkSpectatorMocking.clearMocks()
        NetworkSpectatorMocking.start()

        do {
            try await operation()
            cleanupMockOnlySession()
            await store.stop()
        } catch {
            cleanupMockOnlySession()
            await store.stop()
            throw error
        }
    }

    private func cleanupMockOnlySession() {
        NetworkSpectatorMocking.stop()
        NetworkSpectatorMocking.clearMocks()
        LoggingExclusionManager.shared.clear()
    }
}
