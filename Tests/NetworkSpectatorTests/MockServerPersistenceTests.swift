//
//  MockServerPersistenceTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 09/02/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - MockServer Persistence Tests
@Suite("MockServer Persistence Tests")
struct MockServerPersistenceTests {

    @Test("Register mock with saveLocally true persists to storage")
    func testRegisterMockWithSaveLocallyPersists() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)
        let mock = Mock(rule: .url("https://api.example.com/users"), response: nil as Data?, statusCode: 200, saveLocally: true)
        server.register(mock)

        // Verify it's in memory
        #expect(server.mocks.count == 1)

        // Verify it's persisted to storage
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.statusCode == 200)
    }

    @Test("Register mock with saveLocally false does not persist")
    func testRegisterMockWithoutSaveLocallyDoesNotPersist() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)
        let mock = Mock(rule: .url("https://api.example.com/temp"), response: nil as Data?, statusCode: 201, saveLocally: false)
        server.register(mock)

        // Verify it's in memory
        #expect(server.mocks.count == 1)

        // Verify it's NOT persisted to storage
        let retrieved = storage.retrieve()
        #expect(retrieved.isEmpty)
    }

    @Test("Remove mock with saveLocally true updates storage")
    func testRemoveMockWithSaveLocallyUpdatesStorage() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)
        let mock = Mock(rule: .url("https://api.example.com/delete"), response: nil as Data?, statusCode: 200, saveLocally: true)
        server.register(mock)

        #expect(server.mocks.count == 1)

        server.remove(id: mock.id)

        // Verify it's removed from memory
        #expect(server.mocks.isEmpty)

        // Verify it's removed from storage
        let retrieved = storage.retrieve()
        #expect(retrieved.isEmpty)
    }

    @Test("Remove mock with saveLocally false does not affect storage")
    func testRemoveMockWithoutSaveLocallyDoesNotAffectStorage() async throws {
        // First add a persistent mock
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)
        let persistentMock = Mock(rule: .url("https://api.example.com/keep"), response: nil as Data?, statusCode: 200, saveLocally: true)
        server.register(persistentMock)

        // Add a non-persistent mock
        let tempMock = Mock(rule: .url("https://api.example.com/temp"), response: nil as Data?, statusCode: 201, saveLocally: false)
        server.register(tempMock)

        #expect(server.mocks.count == 2)

        // Remove the temporary mock
        server.remove(id: tempMock.id)

        // Verify storage still has the persistent mock only
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.statusCode == 200)
    }

    @Test("Clear removes all mocks and clears storage")
    func testClearRemovesAllMocksAndClearsStorage() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)
        let mock1 = Mock(rule: .url("https://api.example.com/1"), response: nil as Data?, statusCode: 200, saveLocally: true)
        let mock2 = Mock(rule: .url("https://api.example.com/2"), response: nil as Data?, statusCode: 201, saveLocally: false)

        server.register(mock1)
        server.register(mock2)

        #expect(server.mocks.count == 2)

        server.clear()

        // Verify memory is cleared
        #expect(server.mocks.isEmpty)

        // Verify storage is cleared
        let retrieved = storage.retrieve()
        #expect(retrieved.isEmpty)
    }

    @Test("Multiple persistent mocks are all saved")
    func testMultiplePersistentMocksAreSaved() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)

        let mock1 = Mock(rule: .url("https://api.example.com/1"), response: nil as Data?, statusCode: 200, saveLocally: true)
        let mock2 = Mock(rule: .url("https://api.example.com/2"), response: nil as Data?, statusCode: 201, saveLocally: true)
        let mock3 = Mock(rule: .url("https://api.example.com/3"), response: nil as Data?, statusCode: 202, saveLocally: true)

        server.register(mock1)
        server.register(mock2)
        server.register(mock3)

        // Verify storage has all three
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 3)
    }

    @Test("Mixed persistent and non-persistent mocks only persist the correct ones")
    func testMixedPersistentAndNonPersistentMocks() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)

        let persistent1 = Mock(rule: .url("https://api.example.com/p1"), response: nil as Data?, statusCode: 200, saveLocally: true)
        let temp1 = Mock(rule: .url("https://api.example.com/t1"), response: nil as Data?, statusCode: 201, saveLocally: false)
        let persistent2 = Mock(rule: .url("https://api.example.com/p2"), response: nil as Data?, statusCode: 202, saveLocally: true)
        let temp2 = Mock(rule: .url("https://api.example.com/t2"), response: nil as Data?, statusCode: 203, saveLocally: false)

        server.register(persistent1)
        server.register(temp1)
        server.register(persistent2)
        server.register(temp2)

        // Verify memory has all four
        #expect(server.mocks.count == 4)

        // Verify storage only has the two persistent ones
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 2)
        #expect(retrieved.allSatisfy { $0.saveLocally })
        #expect(retrieved.contains(where: { $0.statusCode == 200 }))
        #expect(retrieved.contains(where: { $0.statusCode == 202 }))
    }

    @Test("ResponseIfMocked returns correct mock for matching request")
    func testResponseIfMockedReturnsCorrectMock() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)

        let mock = Mock(rule: .url("https://api.example.com/users"), response: "test".data(using: .utf8), statusCode: 200, saveLocally: false)
        server.register(mock)

        let url = URL(string: "https://api.example.com/users")!
        let request = URLRequest(url: url)

        let matchedMock = server.responseIfMocked(request)
        #expect(matchedMock != nil)
        #expect(matchedMock?.statusCode == 200)
    }

    @Test("ResponseIfMocked returns nil for non-matching request")
    func testResponseIfMockedReturnsNilForNonMatching() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)

        let mock = Mock(rule: .url("https://api.example.com/users"), response: nil as Data?, statusCode: 200, saveLocally: false)
        server.register(mock)

        let url = URL(string: "https://api.different.com/data")!
        let request = URLRequest(url: url)

        let matchedMock = server.responseIfMocked(request)
        #expect(matchedMock == nil)
    }

    @Test("Persisted mocks can be retrieved from storage")
    func testPersistedMocksCanBeRetrievedFromStorage() async throws {
        // Save mocks directly to storage
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())

        let mock1 = Mock(rule: .url("https://api.example.com/1"), response: nil as Data?, statusCode: 200, saveLocally: true)
        let mock2 = Mock(rule: .url("https://api.example.com/2"), response: nil as Data?, statusCode: 201, saveLocally: true)

        storage.save([mock1, mock2])

        // Verify storage has the mocks (in real scenario these would be loaded on app restart)
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 2)
        #expect(retrieved.contains(where: { $0.statusCode == 200 }))
        #expect(retrieved.contains(where: { $0.statusCode == 201 }))
    }

    @Test("Mock with delay is registered and matched correctly")
    func testMockWithDelayIsRegisteredAndMatched() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)

        let mock = Mock(rule: .url("https://api.example.com/slow"), response: "delayed".data(using: .utf8), statusCode: 200, delay: 2.0)
        server.register(mock)

        let url = URL(string: "https://api.example.com/slow")!
        let request = URLRequest(url: url)

        let matchedMock = server.responseIfMocked(request)
        #expect(matchedMock != nil)
        #expect(matchedMock?.delay == 2.0)
    }

    @Test("Mock delay persists to storage")
    func testMockDelayPersistsToStorage() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer(storage: storage)

        let mock = Mock(rule: .url("https://api.example.com/delayed"), response: nil as Data?, statusCode: 200, saveLocally: true, delay: 1.5)
        server.register(mock)

        let retrieved = storage.retrieve()
        #expect(retrieved.first?.delay == 1.5)
    }

    @Test("Storage preserves mock properties")
    func testStoragePreservesMockProperties() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())

        let original = Mock(rule: .url("https://api.example.com/data"), response: "body".data(using: .utf8), statusCode: 202, saveLocally: true, delay: 0.5)
        storage.save([original])

        let retrieved = storage.retrieve()
        guard let restored = retrieved.first else {
            Issue.record("Expected one mock in storage")
            return
        }

        #expect(restored.id == original.id)
        #expect(restored.statusCode == original.statusCode)
        #expect(restored.saveLocally == original.saveLocally)
        #expect(restored.delay == original.delay)
        #expect(restored.rule == original.rule)
    }
}
