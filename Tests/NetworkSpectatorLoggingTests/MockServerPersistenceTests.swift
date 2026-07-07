//
//  MockServerPersistenceTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 09/02/26.
//

import Testing
import Foundation
@testable import NetworkSpectatorCore
@testable import NetworkSpectatorMocking
@testable import NetworkSpectatorLogging

// MARK: - MockServer Tests
@Suite("MockServer Tests")
struct MockServerPersistenceTests {

    @Test("Register mock stores it in memory")
    func testRegisterMockStoresInMemory() async throws {
        let server = MockServer()
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/users"),
                        response: nil as Data?,
                        headers: [:],
                        statusCode: 200,
                        error: nil,
                        saveLocally: true)

        server.register(mock)

        #expect(server.mocks.count == 1)
        #expect(server.mocks.first?.response.statusCode == 200)
    }

    @Test("Register mock does not persist automatically")
    func testRegisterMockDoesNotPersistAutomatically() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer()
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/temp"),
                        response: nil as Data?,
                        headers: [:],
                        statusCode: 201,
                        error: nil,
                        saveLocally: true)

        server.register(mock)

        #expect(server.mocks.count == 1)
        #expect(storage.retrieve().isEmpty)
    }

    @Test("Remove mock updates memory only")
    func testRemoveMockUpdatesMemoryOnly() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer()
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/delete"),
                        response: nil as Data?,
                        headers: [:],
                        statusCode: 200,
                        error: nil,
                        saveLocally: true)
        storage.save([mock])
        server.register(mock)

        server.remove(id: mock.id)

        #expect(server.mocks.isEmpty)
        #expect(storage.retrieve().count == 1)
    }

    @Test("Clear removes all mocks from memory only")
    func testClearRemovesAllMocksFromMemoryOnly() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer()
        let mock1 = Mock(method: .GET, rule: .url("https://api.example.com/1"), response: nil as Data?, headers: [:], statusCode: 200, error: nil, saveLocally: true)
        let mock2 = Mock(method: .GET, rule: .url("https://api.example.com/2"), response: nil as Data?, headers: [:], statusCode: 201, error: nil, saveLocally: false)
        storage.save([mock1])

        server.register(mock1)
        server.register(mock2)
        server.clear()

        #expect(server.mocks.isEmpty)
        #expect(storage.retrieve().count == 1)
    }

    @Test("ResponseIfMocked returns correct mock for matching request")
    func testResponseIfMockedReturnsCorrectMock() async throws {
        let server = MockServer()
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/users"),
                        response: "test".data(using: .utf8),
                        headers: [:],
                        statusCode: 200,
                        error: nil,
                        saveLocally: false)
        server.register(mock)

        let url = URL(string: "https://api.example.com/users")!
        let request = URLRequest(url: url)

        let matchedMock = server.responseIfMocked(request)
        #expect(matchedMock != nil)
        #expect(matchedMock?.response.statusCode == 200)
    }

    @Test("ResponseIfMocked returns nil for non-matching request")
    func testResponseIfMockedReturnsNilForNonMatching() async throws {
        let server = MockServer()
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/users"),
                        response: nil as Data?,
                        headers: [:],
                        statusCode: 200,
                        error: nil,
                        saveLocally: false)
        server.register(mock)

        let url = URL(string: "https://api.different.com/data")!
        let request = URLRequest(url: url)

        let matchedMock = server.responseIfMocked(request)
        #expect(matchedMock == nil)
    }

    @Test("One-shot mock is removed after matching")
    func testOneShotMockIsRemovedAfterMatching() async throws {
        let server = MockServer()
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/once"),
                        response: HTTPResponse(headers: [:], statusCode: 200, responseData: nil, error: nil),
                        saveLocally: false,
                        oneShot: true)
        server.register(mock)

        let request = URLRequest(url: URL(string: "https://api.example.com/once")!)

        #expect(server.responseIfMocked(request) != nil)
        #expect(server.mocks.isEmpty)
    }

    @Test("Mock with delay is registered and matched correctly")
    func testMockWithDelayIsRegisteredAndMatched() async throws {
        let server = MockServer()
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/slow"),
                        response: "delayed".data(using: .utf8),
                        statusCode: 200,
                        delay: 2.0)
        server.register(mock)

        let url = URL(string: "https://api.example.com/slow")!
        let request = URLRequest(url: url)

        let matchedMock = server.responseIfMocked(request)
        #expect(matchedMock != nil)
        #expect(matchedMock?.response.responseTime == 2.0)
    }

    @Test("Persisted mocks can be retrieved from storage explicitly")
    func testPersistedMocksCanBeRetrievedFromStorage() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let mock1 = Mock(method: .GET, rule: .url("https://api.example.com/1"), response: nil as Data?, headers: [:], statusCode: 200, error: nil, saveLocally: true)
        let mock2 = Mock(method: .GET, rule: .url("https://api.example.com/2"), response: nil as Data?, headers: [:], statusCode: 201, error: nil, saveLocally: true)

        storage.save([mock1, mock2])

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 2)
        #expect(retrieved.contains(where: { $0.response.statusCode == 200 }))
        #expect(retrieved.contains(where: { $0.response.statusCode == 201 }))
    }

    @Test("Storage preserves mock properties")
    func testStoragePreservesMockProperties() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let original = Mock(method: .GET,
                            rule: .url("https://api.example.com/data"),
                            response: "body".data(using: .utf8),
                            headers: [:],
                            statusCode: 202,
                            error: nil,
                            saveLocally: true,
                            delay: 0.5)

        storage.save([original])

        let retrieved = storage.retrieve()
        guard let restored = retrieved.first else {
            Issue.record("Expected one mock in storage")
            return
        }

        #expect(restored.id == original.id)
        #expect(restored.response.statusCode == original.response.statusCode)
        #expect(restored.saveLocally == original.saveLocally)
        #expect(restored.response.responseTime == original.response.responseTime)
        #expect(restored.rule == original.rule)
    }

    @Test("PersistentMockStorage persists mocks marked saveLocally")
    func testPersistentMockStoragePersistsSavedMocks() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer()
        let persistentStorage = PersistentMockServer(storage: storage, mockServer: server)
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/persist"),
                        response: nil as Data?,
                        headers: [:],
                        statusCode: 200,
                        error: nil,
                        saveLocally: true)

        persistentStorage.register(mock)

        #expect(server.mocks.count == 1)
        #expect(storage.retrieve().count == 1)
    }

    @Test("PersistentMockStorage keeps non-persistent mocks in memory only")
    func testPersistentMockStorageSkipsTemporaryMocks() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer()
        let persistentStorage = PersistentMockServer(storage: storage, mockServer: server)
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/temp"),
                        response: nil as Data?,
                        headers: [:],
                        statusCode: 200,
                        error: nil,
                        saveLocally: false)

        persistentStorage.register(mock)

        #expect(server.mocks.count == 1)
        #expect(storage.retrieve().isEmpty)
    }

    @Test("PersistentMockStorage remove updates persisted mocks")
    func testPersistentMockStorageRemoveUpdatesStorage() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer()
        let persistentStorage = PersistentMockServer(storage: storage, mockServer: server)
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/remove"),
                        response: nil as Data?,
                        headers: [:],
                        statusCode: 200,
                        error: nil,
                        saveLocally: true)

        persistentStorage.register(mock)
        persistentStorage.remove(id: mock.id)

        #expect(server.mocks.isEmpty)
        #expect(storage.retrieve().isEmpty)
    }

    @Test("PersistentMockStorage clear removes memory and persisted mocks")
    func testPersistentMockStorageClearRemovesMemoryAndStorage() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer()
        let persistentStorage = PersistentMockServer(storage: storage, mockServer: server)
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/clear"),
                        response: nil as Data?,
                        headers: [:],
                        statusCode: 200,
                        error: nil,
                        saveLocally: true)

        persistentStorage.register(mock)
        persistentStorage.clear()

        #expect(server.mocks.isEmpty)
        #expect(storage.retrieve().isEmpty)
    }

    @Test("PersistentMockStorage load restores persisted mocks into memory")
    func testPersistentMockStorageLoadRestoresMocks() async throws {
        let storage = RuleStorage<Mock>(key: .mockRules, store: MockStorage())
        let server = MockServer()
        let persistentStorage = PersistentMockServer(storage: storage, mockServer: server)
        let mock = Mock(method: .GET,
                        rule: .url("https://api.example.com/restore"),
                        response: nil as Data?,
                        headers: [:],
                        statusCode: 200,
                        error: nil,
                        saveLocally: true)
        storage.save([mock])

        persistentStorage.load()

        #expect(server.mocks.count == 1)
        #expect(server.mocks.first?.rule == mock.rule)
    }
}
