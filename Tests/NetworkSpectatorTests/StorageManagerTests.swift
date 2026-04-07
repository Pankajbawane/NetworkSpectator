//
//  StorageManagerTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 09/02/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

final class MockStorage: Storeable, @unchecked Sendable {
    var store: [String: Any] = [:]
    
    func set(_ value: Any?, forKey defaultName: String) {
        store[defaultName] = value
    }
    
    func data(forKey defaultName: String) -> Data? {
        if let value = store[defaultName], let data = value as? Data {
            return data
        }
        return nil
    }
    
    func value(forKey defaultName: String) -> Any? {
        store[defaultName]
    }
    
    func removeObject(forKey defaultName: String) {
        store[defaultName] = nil
    }
    
    func synchronize() -> Bool {
        true
    }
}

// MARK: - RuleStorage Tests
@Suite("RuleStorage Tests")
struct RuleStorageTests {

    @Test("Save and retrieve mocks")
    func testSaveAndRetrieveMocks() async throws {
        let store = MockStorage()
        let storage = RuleStorage<Mock>(key: .mockRules, store: store)

        let mock1 = Mock(method: .GET, rule: .url("https://api.example.com/users"), response: nil as Data?, headers: [:], statusCode: 200, error: nil, saveLocally: true)
        let mock2 = Mock(method: .GET, rule: .path("/api/data"), response: "test".data(using: .utf8), headers: [:], statusCode: 404, error: nil, saveLocally: true)

        storage.save([mock1, mock2])
        UserDefaults.standard.synchronize()

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 2)
        #expect(retrieved.contains(where: { $0.response.statusCode == 200 }))
        #expect(retrieved.contains(where: { $0.response.statusCode == 404 }))
    }

    @Test("Save and retrieve skip requests")
    func testSaveAndRetrieveSkipRequests() async throws {
        let store = MockStorage()
        let storage = RuleStorage<LogSkipRequest>(key: .skipRules, store: store)

        let skip1 = LogSkipRequest(method: .GET, rule: .url("https://analytics.com"), saveLocally: true)
        let skip2 = LogSkipRequest(method: .GET, rule: .hostName("tracking.com"), saveLocally: true)

        storage.save([skip1, skip2])
        UserDefaults.standard.synchronize()

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 2)
        #expect(retrieved.contains(where: { $0.rule == .url("https://analytics.com") }))
        #expect(retrieved.contains(where: { $0.rule == .hostName("tracking.com") }))
    }

    @Test("Retrieve empty storage returns empty array")
    func testRetrieveEmptyStorage() async throws {
        let store = MockStorage()
        let storage = RuleStorage<Mock>(key: .mockRules, store: store)

        let retrieved = storage.retrieve()
        #expect(retrieved.isEmpty)
    }

    @Test("Clear storage removes all items")
    func testClearStorage() async throws {
        let store = MockStorage()
        let storage = RuleStorage<Mock>(key: .mockRules, store: store)

        let mock = Mock(method: .GET, rule: .url("https://example.com"), response: nil as Data?, headers: [:], statusCode: 200, error: nil, saveLocally: true)
        storage.save([mock])

        #expect(storage.retrieve().count == 1)

        storage.clear()

        #expect(storage.retrieve().isEmpty)
    }

    @Test("Overwrite existing storage")
    func testOverwriteStorage() async throws {
        let store = MockStorage()
        let storage = RuleStorage<Mock>(key: .mockRules, store: store)

        let mock1 = Mock(method: .GET, rule: .url("https://first.com"), response: nil as Data?, headers: [:], statusCode: 200, error: nil, saveLocally: true)
        storage.save([mock1])

        let mock2 = Mock(method: .GET, rule: .url("https://second.com"), response: nil as Data?, headers: [:], statusCode: 201, error: nil, saveLocally: true)
        storage.save([mock2])

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.response.statusCode == 201)
    }

    @Test("Storage preserves mock properties")
    func testStoragePreservesMockProperties() async throws {
        let store = MockStorage()
        let storage = RuleStorage<Mock>(key: .mockRules, store: store)

        let headers = ["Content-Type": "application/json", "X-Custom": "value"]
        let responseData = "{\"key\":\"value\"}".data(using: .utf8)
        let rule = MatchRule.url("https://api.example.com")

        let mock = Mock(method: .GET, rule: rule, response: responseData, headers: headers, statusCode: 201, error: nil, saveLocally: true)
        storage.save([mock])

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)

        if let savedMock = retrieved.first {
            #expect(savedMock.response.statusCode == 201)
            #expect(savedMock.response.responseData == responseData)
            #expect(savedMock.response.headers["Content-Type"] == "application/json")
            #expect(savedMock.response.headers["X-Custom"] == "value")
            #expect(savedMock.saveLocally == true)
        }
    }

    @Test("Storage preserves skip request properties")
    func testStoragePreservesSkipRequestProperties() async throws {
        let store = MockStorage()
        let storage = RuleStorage<LogSkipRequest>(key: .skipRules, store: store)

        let rule = MatchRule.hostName("analytics.com")
        let skipRequest = LogSkipRequest(method: .GET, rule: rule, saveLocally: true)

        storage.save([skipRequest])

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)
    }

}
