//
//  SkipRequestPersistenceTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 09/02/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - SkipRequestForLoggingHandler Persistence Tests
@Suite("SkipRequestForLoggingHandler Persistence Tests")
struct SkipRequestPersistenceTests {

    @Test("Register rule with saveLocally true persists to storage")
    func testRegisterRuleWithSaveLocallyPersists() async throws {
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(rule: .url("https://analytics.com/track"), saveLocally: true)

        // Verify it's in memory
        #expect(handler.skipRequests.count == 1)

        // Verify it's persisted to storage
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.rule == .url("https://analytics.com/track"))
    }

    @Test("Register rule with saveLocally false does not persist")
    func testRegisterRuleWithoutSaveLocallyDoesNotPersist() async throws {
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(rule: .hostName("temp.com"), saveLocally: false)

        // Verify it's in memory
        #expect(handler.skipRequests.count == 1)

        // Verify it's NOT persisted to storage
        let retrieved = storage.retrieve()
        #expect(retrieved.isEmpty)
    }

    @Test("Register request object persists if saveLocally is true")
    func testRegisterRequestObjectPersists() async throws {
        let skipRequest = SkipRequestForLogging(rule: .url("https://ads.com"), saveLocally: true)
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(request: skipRequest)

        // Verify it's persisted to storage
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.saveLocally == true)
    }

    @Test("Remove skip request with saveLocally true updates storage")
    func testRemoveSkipRequestWithSaveLocallyUpdatesStorage() async throws {
        let skipRequest = SkipRequestForLogging(rule: .url("https://tracking.com"), saveLocally: true)
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(request: skipRequest)

        #expect(handler.skipRequests.count == 1)

        handler.remove(id: skipRequest.id)

        // Verify it's removed from memory
        #expect(handler.skipRequests.isEmpty)

        // Verify it's removed from storage
        let retrieved = storage.retrieve()
        #expect(retrieved.isEmpty)
    }

    @Test("Remove skip request with saveLocally false does not affect storage")
    func testRemoveSkipRequestWithoutSaveLocallyDoesNotAffectStorage() async throws {
        // First add a persistent skip request
        let persistentRequest = SkipRequestForLogging(rule: .url("https://keep.com"), saveLocally: true)
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(request: persistentRequest)

        // Add a non-persistent skip request
        let tempRequest = SkipRequestForLogging(rule: .url("https://temp.com"), saveLocally: false)
        handler.register(request: tempRequest)

        #expect(handler.skipRequests.count == 2)

        // Remove the temporary request
        handler.remove(id: tempRequest.id)

        // Verify storage still has the persistent request only
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.rule == .url("https://keep.com"))
    }

    @Test("Clear removes all skip requests and clears storage")
    func testClearRemovesAllAndClearsStorage() async throws {
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(rule: .url("https://analytics.com"), saveLocally: true)
        handler.register(rule: .hostName("tracking.com"), saveLocally: false)

        #expect(handler.skipRequests.count == 2)

        handler.clear()

        // Verify memory is cleared
        #expect(handler.skipRequests.isEmpty)

        // Verify storage is cleared
        let retrieved = storage.retrieve()
        #expect(retrieved.isEmpty)
    }

    @Test("Multiple persistent skip requests are all saved")
    func testMultiplePersistentSkipRequestsAreSaved() async throws {
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(rule: .url("https://analytics.com"), saveLocally: true)
        handler.register(rule: .hostName("tracking.com"), saveLocally: true)
        handler.register(rule: .path("/ads"), saveLocally: true)

        // Verify storage has all three
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 3)
    }

    @Test("Mixed persistent and non-persistent skip requests only persist the correct ones")
    func testMixedPersistentAndNonPersistentSkipRequests() async throws {
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(rule: .url("https://persistent1.com"), saveLocally: true)
        handler.register(rule: .url("https://temp1.com"), saveLocally: false)
        handler.register(rule: .hostName("persistent2.com"), saveLocally: true)
        handler.register(rule: .path("/temp"), saveLocally: false)

        // Verify memory has all four
        #expect(handler.skipRequests.count == 4)

        // Verify storage only has the two persistent ones
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 2)
        #expect(retrieved.allSatisfy { $0.saveLocally })
    }

    @Test("ShouldSkipLogging returns true for matching request")
    func testShouldSkipLoggingReturnsTrue() async throws {
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(rule: .url("https://analytics.com/track"), saveLocally: false)

        let url = URL(string: "https://analytics.com/track")!
        let request = URLRequest(url: url)

        let shouldSkip = handler.shouldSkipLogging(request)
        #expect(shouldSkip == true)
    }

    @Test("ShouldSkipLogging returns false for non-matching request")
    func testShouldSkipLoggingReturnsFalse() async throws {
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(rule: .url("https://analytics.com/track"), saveLocally: false)

        let url = URL(string: "https://api.example.com/users")!
        let request = URLRequest(url: url)

        let shouldSkip = handler.shouldSkipLogging(request)
        #expect(shouldSkip == false)
    }

    @Test("IsEnabled returns true when skip requests exist")
    func testIsEnabledReturnsTrue() async throws {
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        let handler = SkipRequestForLoggingHandler(storage: storage)
        handler.register(rule: .url("https://analytics.com"), saveLocally: false)
        #expect(handler.isEnabled == true)
    }

    @Test("Persisted skip requests can be retrieved from storage")
    func testPersistedSkipRequestsCanBeRetrievedFromStorage() async throws {
        // Save skip requests directly to storage
        let skip1 = SkipRequestForLogging(rule: .url("https://analytics.com"), saveLocally: true)
        let skip2 = SkipRequestForLogging(rule: .hostName("tracking.com"), saveLocally: true)

        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules, store: MockStorage())
        storage.save([skip1, skip2])

        // Verify storage has the skip requests (in real scenario these would be loaded on app restart)
        let retrieved = storage.retrieve()
        #expect(retrieved.count == 2)
        #expect(retrieved.contains(where: { $0.rule == .url("https://analytics.com") }))
        #expect(retrieved.contains(where: { $0.rule == .hostName("tracking.com") }))
    }
}
