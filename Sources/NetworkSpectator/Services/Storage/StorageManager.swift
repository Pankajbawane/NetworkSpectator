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

/// Simple storage manager for persisting rules to UserDefaults
struct RuleStorage<T: Codable> {

    private let key: StorageKey

    init(key: StorageKey) {
        self.key = key
    }

    /// Saves an array of rules to UserDefaults
    func save(_ items: [T]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: key.rawValue)
        } catch {
            print("Failed to save \(key.rawValue): \(error)")
        }
    }

    /// Retrieves all rules from UserDefaults
    func retrieve() -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else {
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
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }
}
