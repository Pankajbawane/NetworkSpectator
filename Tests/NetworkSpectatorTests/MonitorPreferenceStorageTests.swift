//
//  MonitorPreferenceStorageTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 07/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - MonitorPreferenceStorage Tests
@Suite("MonitorPreferenceStorage Tests")
struct MonitorPreferenceStorageTests {

    @Test("StorageKey monitorPreference has correct raw value")
    func testMonitorPreferenceKeyRawValue() async throws {
        #expect(StorageKey.monitorPreference.rawValue == "MONITOR_PREFERENCE")
    }
    
    @Test("Save true and retrieve returns true")
    func testSaveTrueAndRetrieve() async throws {
        let store = MockStorage()
        let storage = MonitorPreferenceStorage(key: .monitorPreference, store: store)

        storage.save(true)

        let result = storage.retrieve()
        #expect(result == true)
    }

    @Test("Save false and retrieve returns false")
    func testSaveFalseAndRetrieve() async throws {
        let store = MockStorage()
        let storage = MonitorPreferenceStorage(key: .monitorPreference, store: store)

        storage.save(false)

        let result = storage.retrieve()
        #expect(result == false)
    }

    @Test("Retrieve returns false when no value stored")
    func testRetrieveDefaultsToFalse() async throws {
        let store = MockStorage()
        let storage = MonitorPreferenceStorage(key: .monitorPreference, store: store)

        let result = storage.retrieve()
        #expect(result == false)
    }

    @Test("Clear removes stored preference")
    func testClearRemovesPreference() async throws {
        let store = MockStorage()
        let storage = MonitorPreferenceStorage(key: .monitorPreference, store: store)

        storage.save(true)
        #expect(storage.retrieve() == true)

        storage.clear()
        #expect(storage.retrieve() == false)
    }

    @Test("Save overwrites previous value")
    func testSaveOverwritesPreviousValue() async throws {
        let store = MockStorage()
        let storage = MonitorPreferenceStorage(key: .monitorPreference, store: store)

        storage.save(true)
        #expect(storage.retrieve() == true)

        storage.save(false)
        #expect(storage.retrieve() == false)
    }

    @Test("Uses correct storage key")
    func testUsesCorrectStorageKey() async throws {
        let store = MockStorage()
        let storage = MonitorPreferenceStorage(key: .monitorPreference, store: store)

        storage.save(true)

        // Verify the value is stored under the correct key
        let storedValue = store.value(forKey: StorageKey.monitorPreference.rawValue) as? Bool
        #expect(storedValue == true)
    }

    @Test("Does not interfere with other storage keys")
    func testDoesNotInterfereWithOtherKeys() async throws {
        let store = MockStorage()
        let preferenceStorage = MonitorPreferenceStorage(key: .monitorPreference, store: store)
        let ruleStorage = RuleStorage<Mock>(key: .mockRules, store: store)

        let mock = Mock(rule: .url("https://example.com"), response: nil as Data?, statusCode: 200, saveLocally: true)
        ruleStorage.save([mock])

        preferenceStorage.save(true)

        // Both values should be independently retrievable
        #expect(preferenceStorage.retrieve() == true)
        #expect(ruleStorage.retrieve().count == 1)

        preferenceStorage.clear()

        // Clearing preference should not affect mock rules
        #expect(preferenceStorage.retrieve() == false)
        #expect(ruleStorage.retrieve().count == 1)
    }
}
