//
//  StorageManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 31/01/26.
//

import Foundation
import NetworkSpectatorCore

package enum StorageKey: String, Sendable {
    case mockRules = "NETWORKSPECTATOR_MOCK_RULES"
    case exclusionRules = "NETWORKSPECTATOR_EXCLUSION_RULES"
    case monitorPreference = "NETWORKSPECTATOR_MONITOR_PREFERENCE"
    case historyPreference = "NETWORKSPECTATOR_HISTORY_PREFERENCE"
}

package protocol Storeable: Sendable {
    func set(_ value: Any?, forKey defaultName: String)
    func data(forKey defaultName: String) -> Data?
    func removeObject(forKey defaultName: String)
    func value(forKey defaultName: String) -> Any?
    @discardableResult func synchronize() -> Bool
}

extension UserDefaults: Storeable { }

/// Simple storage manager for persisting rules to UserDefaults
package struct RuleStorage<T: Codable>: Sendable {

    private let key: StorageKey
    private let store: Storeable

    package init(key: StorageKey, store: Storeable = UserDefaults.standard) {
        self.key = key
        self.store = store
    }

    /// Saves an array of rules to UserDefaults
    package func save(_ items: [T]) {
        do {
            let data = try JSONEncoder().encode(items)
            store.set(data, forKey: key.rawValue)
            store.synchronize()
        } catch {
            DebugConsoleLogger.log("Failed to save \(key.rawValue): \(error)")
        }
    }

    /// Retrieves all rules from UserDefaults
    package func retrieve() -> [T] {
        guard let data = store.data(forKey: key.rawValue) else {
            return []
        }
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            DebugConsoleLogger.log("Failed to retrieve \(key.rawValue): \(error)")
            return []
        }
    }

    /// Clears all stored rules
    package func clear() {
        store.removeObject(forKey: key.rawValue)
        store.synchronize()
    }
}
