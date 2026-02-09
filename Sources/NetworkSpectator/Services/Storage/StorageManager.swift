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

protocol RuleStorable {
    associatedtype T
    var key: StorageKey { get }
    func save(rule: T)
    func remove(rule: T)
    func retrieve() -> [T]
}

struct RuleStorage<T: Codable & Equatable>: RuleStorable {
    
    let key: StorageKey
    
    init(key: StorageKey) {
        self.key = key
    }
    
    func save(rule: T) {
        var previous = retrieve()
        previous.append(rule)
        store(previous)
    }
    
    func remove(rule: T) {
        var previous = retrieve()
        previous.removeAll { $0 == rule }
        store(previous)
    }
    
    private func store(_ value: Codable) {
        do {
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.setValue(data, forKey: key.rawValue)
        } catch {
            print(error)
        }
    }
    
    func retrieve() -> [T] {
        guard let data = UserDefaults.standard.value(forKey: key.rawValue) as? Data else {
            return []
        }
        do {
            let items = try JSONDecoder().decode([T].self, from: data)
            return items
        } catch {
            print(error)
            return []
        }
    }
}
