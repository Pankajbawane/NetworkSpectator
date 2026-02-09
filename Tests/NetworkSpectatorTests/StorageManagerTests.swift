//
//  StorageManagerTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 09/02/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

class MockStorage: Storeable {
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

        let mock1 = Mock(rules: [.url("https://api.example.com/users")], response: nil as Data?, statusCode: 200, saveLocally: true)
        let mock2 = Mock(rules: [.path("/api/data")], response: "test".data(using: .utf8), statusCode: 404, saveLocally: true)

        storage.save([mock1, mock2])
        UserDefaults.standard.synchronize()

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 2)
        #expect(retrieved.contains(where: { $0.statusCode == 200 }))
        #expect(retrieved.contains(where: { $0.statusCode == 404 }))
    }

    @Test("Save and retrieve skip requests")
    func testSaveAndRetrieveSkipRequests() async throws {
        let store = MockStorage()
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: store)

        let skip1 = SkipRequestForLogging(rule: .url("https://analytics.com"), saveLocally: true)
        let skip2 = SkipRequestForLogging(rules: [.hostName("tracking.com")], saveLocally: true)

        storage.save([skip1, skip2])
        UserDefaults.standard.synchronize()

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 2)
        #expect(retrieved.contains(where: { $0.rules.contains(.url("https://analytics.com")) }))
        #expect(retrieved.contains(where: { $0.rules.contains(.hostName("tracking.com")) }))
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

        let mock = Mock(rules: [.url("https://example.com")], response: nil as Data?, statusCode: 200, saveLocally: true)
        storage.save([mock])

        #expect(storage.retrieve().count == 1)

        storage.clear()

        #expect(storage.retrieve().isEmpty)
    }

    @Test("Overwrite existing storage")
    func testOverwriteStorage() async throws {
        let store = MockStorage()
        let storage = RuleStorage<Mock>(key: .mockRules, store: store)

        let mock1 = Mock(rules: [.url("https://first.com")], response: nil as Data?, statusCode: 200, saveLocally: true)
        storage.save([mock1])

        let mock2 = Mock(rules: [.url("https://second.com")], response: nil as Data?, statusCode: 201, saveLocally: true)
        storage.save([mock2])

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.statusCode == 201)
    }

    @Test("Storage preserves mock properties")
    func testStoragePreservesMockProperties() async throws {
        let store = MockStorage()
        let storage = RuleStorage<Mock>(key: .mockRules, store: store)

        let headers = ["Content-Type": "application/json", "X-Custom": "value"]
        let responseData = "{\"key\":\"value\"}".data(using: .utf8)
        let rules = [MatchRule.url("https://api.example.com"), MatchRule.path("/test")]

        let mock = Mock(rules: rules, response: responseData, headers: headers, statusCode: 201, saveLocally: true)
        storage.save([mock])

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)

        if let savedMock = retrieved.first {
            #expect(savedMock.statusCode == 201)
            #expect(savedMock.response == responseData)
            #expect(savedMock.headers["Content-Type"] == "application/json")
            #expect(savedMock.headers["X-Custom"] == "value")
            #expect(savedMock.rules.count == 2)
            #expect(savedMock.saveLocally == true)
        }
    }

    @Test("Storage preserves skip request properties")
    func testStoragePreservesSkipRequestProperties() async throws {
        let store = MockStorage()
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: store)

        let rules = [MatchRule.hostName("analytics.com"), MatchRule.path("/track")]
        let skipRequest = SkipRequestForLogging(rules: rules, saveLocally: true)

        storage.save([skipRequest])

        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)
    }

}
