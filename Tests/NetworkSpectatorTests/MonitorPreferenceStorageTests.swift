//
//  MonitorPreferenceStorageTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 07/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - PreferenceStorage Tests
@Suite("PreferenceStorage Tests")
struct MonitorPreferenceStorageTests {

    @Test("StorageKey monitorPreference has correct raw value")
    func testMonitorPreferenceKeyRawValue() async throws {
        #expect(StorageKey.monitorPreference.rawValue == "NETWORKSPECTATOR_MONITOR_PREFERENCE")
    }
    
    @Test("StorageKey historyPreference has correct raw value")
    func testHistoryPreferenceKeyRawValue() async throws {
        #expect(StorageKey.historyPreference.rawValue == "NETWORKSPECTATOR_HISTORY_PREFERENCE")
    }
    
    @Test("Save true and retrieve returns true")
    func testSaveTrueAndRetrieve() async throws {
        let store = MockStorage()
        let storage = PreferenceStorage(preference: .monitoring, store: store)

        storage.save(true)

        let result = storage.retrieve()
        #expect(result == true)
    }

    @Test("Save false and retrieve returns false")
    func testSaveFalseAndRetrieve() async throws {
        let store = MockStorage()
        let storage = PreferenceStorage(preference: .monitoring, store: store)

        storage.save(false)

        let result = storage.retrieve()
        #expect(result == false)
    }

    @Test("Retrieve returns false when no value stored")
    func testRetrieveDefaultsToFalse() async throws {
        let store = MockStorage()
        let storage = PreferenceStorage(preference: .monitoring, store: store)

        let result = storage.retrieve()
        #expect(result == false)
    }
    
    @Test("Retrieve returns custom default value when no value stored")
    func testRetrieveCustomDefaultValue() async throws {
        let store = MockStorage()
        let storage = PreferenceStorage(preference: .history, store: store)

        let result = storage.retrieve(true)
        #expect(result == true)
    }

    @Test("Clear removes stored preference")
    func testClearRemovesPreference() async throws {
        let store = MockStorage()
        let storage = PreferenceStorage(preference: .monitoring, store: store)

        storage.save(true)
        #expect(storage.retrieve() == true)

        storage.clear()
        #expect(storage.retrieve() == false)
    }

    @Test("Save overwrites previous value")
    func testSaveOverwritesPreviousValue() async throws {
        let store = MockStorage()
        let storage = PreferenceStorage(preference: .monitoring, store: store)

        storage.save(true)
        #expect(storage.retrieve() == true)

        storage.save(false)
        #expect(storage.retrieve() == false)
    }

    @Test("Uses correct storage key")
    func testUsesCorrectStorageKey() async throws {
        let store = MockStorage()
        let storage = PreferenceStorage(preference: .monitoring, store: store)

        storage.save(true)

        // Verify the value is stored under the correct key
        let storedValue = store.value(forKey: StorageKey.monitorPreference.rawValue) as? Bool
        #expect(storedValue == true)
    }
    
    @Test("History preference uses correct storage key")
    func testHistoryUsesCorrectStorageKey() async throws {
        let store = MockStorage()
        let storage = PreferenceStorage(preference: .history, store: store)

        storage.save(true)

        let storedValue = store.value(forKey: StorageKey.historyPreference.rawValue) as? Bool
        #expect(storedValue == true)
    }

    @Test("Does not interfere with other storage keys")
    func testDoesNotInterfereWithOtherKeys() async throws {
        let store = MockStorage()
        let preferenceStorage = PreferenceStorage(preference: .monitoring, store: store)
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
    
    @Test("Monitoring and history preferences are independent")
    func testMonitoringAndHistoryIndependent() async throws {
        let store = MockStorage()
        let monitoring = PreferenceStorage(preference: .monitoring, store: store)
        let history = PreferenceStorage(preference: .history, store: store)

        monitoring.save(true)
        history.save(false)

        #expect(monitoring.retrieve() == true)
        #expect(history.retrieve() == false)

        history.save(true)
        monitoring.save(false)

        #expect(monitoring.retrieve() == false)
        #expect(history.retrieve() == true)
    }
}
