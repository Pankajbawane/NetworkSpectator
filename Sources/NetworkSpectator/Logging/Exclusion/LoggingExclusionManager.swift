//
//  LoggingExclusionManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 09/02/26.
//

import Foundation
@_exported import NetworkSpectatorCore

package final class LoggingExclusionManager: @unchecked Sendable {

    package static let shared: LoggingExclusionManager = .init()

    package var rules: Set<LoggingExclusionRule> = []
    private let storage: RuleStorage<LoggingExclusionRule>

    package var isEnabled: Bool {
        !rules.isEmpty
    }

    package init(storage: RuleStorage<LoggingExclusionRule> = RuleStorage<LoggingExclusionRule>(key: .exclusionRules)) {
        self.storage = storage
        rules = Set(storage.retrieve())
    }

    package func remove(id: UUID) {
        if let item = rules.first(where: { $0.id == id }) {
            rules.remove(item)
            if item.saveLocally {
                persist()
            }
        }
    }

    package func clear() {
        rules.removeAll()
        persist()
    }

    package func register(method: HTTPMethod, rule: MatchRule, saveLocally: Bool = false) {
        let exclude = LoggingExclusionRule(method: method, rule: rule, saveLocally: saveLocally)
        rules.insert(exclude)
        if saveLocally {
            persist()
        }
    }

    package func register(request: LoggingExclusionRule) {
        rules.insert(request)
        if request.saveLocally {
            persist()
        }
    }

    package func shouldExcludeLogging(_ urlRequest: URLRequest) -> Bool {
        return rules.contains { $0.shouldIgnore(urlRequest) }
    }

    /// Persists excluded requests marked with saveLocally to storage
    private func persist() {
        let requestsToSave = rules.filter { $0.saveLocally }
        storage.save(Array(requestsToSave))
    }
}
