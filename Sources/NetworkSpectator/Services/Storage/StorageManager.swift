//
//  StorageManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 31/01/26.
//

import Foundation

enum StorageKey: String {
    case mockRules = "MOCK_RULES"
    case skipRules = "SKIP_RULES"
}

protocol Storeable {
    func set(_ value: Any?, forKey defaultName: String)
    func data(forKey defaultName: String) -> Data?
    func removeObject(forKey defaultName: String)
    @discardableResult func synchronize() -> Bool
}

extension UserDefaults: Storeable {
    
}

/// Simple storage manager for persisting rules to UserDefaults
struct RuleStorage<T: Codable> {

    private let key: StorageKey
    private let store: Storeable

    init(key: StorageKey, store: Storeable = UserDefaults.standard) {
        self.key = key
        self.store = store
    }

    /// Saves an array of rules to UserDefaults
    func save(_ items: [T]) {
        do {
            let data = try JSONEncoder().encode(items)
            store.set(data, forKey: key.rawValue)
            store.synchronize()
        } catch {
            print("Failed to save \(key.rawValue): \(error)")
        }
    }

    /// Retrieves all rules from UserDefaults
    func retrieve() -> [T] {
        guard let data = store.data(forKey: key.rawValue) else {
            return []
        }
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("Failed to retrieve \(key.rawValue): \(error)")
            return []
        }
    }

    /// Clears all stored rules
    func clear() {
        store.removeObject(forKey: key.rawValue)
        store.synchronize()
    }
}
