//
//  MonitorPreferenceStorage.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 06/03/26.
//

import Foundation

struct MonitorPreferenceStorage {
    
    private let key: StorageKey
    private let store: Storeable
    
    init(key: StorageKey = .monitorPreference, store: Storeable = UserDefaults.standard) {
        self.key = key
        self.store = store
    }
    
    /// Saves  to UserDefaults
    func save(_ enable: Bool) {
        store.set(enable, forKey: key.rawValue)
        store.synchronize()
    }
    
    /// Retrieves from UserDefaults
    func retrieve() -> Bool {
        store.value(forKey: key.rawValue) as? Bool ?? false
    }
    
    /// Clears all stored rules
    func clear() {
        store.removeObject(forKey: key.rawValue)
        store.synchronize()
    }
}
