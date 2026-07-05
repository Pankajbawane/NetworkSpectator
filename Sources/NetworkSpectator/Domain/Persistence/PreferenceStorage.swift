//
//  MonitorPreferenceStorage.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 06/03/26.
//

import Foundation
import NetworkSpectatorCore

package struct PreferenceStorage {
    
    package enum Preference {
        case monitoring
        case history
        
        var key: StorageKey {
            switch self {
            case .monitoring: return .monitorPreference
            case .history: return .historyPreference
            }
        }
    }
    
    private let key: StorageKey
    private let store: Storeable
    
    package init(preference: Preference, store: Storeable = UserDefaults.standard) {
        self.key = preference.key
        self.store = store
    }
    
    /// Saves  to UserDefaults
    package func save(_ enable: Bool) {
        store.set(enable, forKey: key.rawValue)
        store.synchronize()
    }
    
    /// Retrieves from UserDefaults
    package func retrieve(_ defaultValue: Bool = false) -> Bool {
        return store.value(forKey: key.rawValue) as? Bool ?? defaultValue
    }
    
    /// Clears all stored rules
    package func clear() {
        store.removeObject(forKey: key.rawValue)
        store.synchronize()
    }
}
