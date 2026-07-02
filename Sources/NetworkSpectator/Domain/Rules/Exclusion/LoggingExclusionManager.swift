//
//  LoggingExclusionManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 09/02/26.
//

import Foundation

final class LoggingExclusionManager: @unchecked Sendable {

    static let shared: LoggingExclusionManager = .init()

    var skipRequests: Set<LoggingExclusionRule> = []
    private let storage: RuleStorage<LoggingExclusionRule>

    var isEnabled: Bool {
        !skipRequests.isEmpty
    }

    init(storage: RuleStorage<LoggingExclusionRule> = RuleStorage<LoggingExclusionRule>(key: .skipRules)) {
        self.storage = storage
        skipRequests = Set(storage.retrieve())
    }

    func remove(id: UUID) {
        if let item = skipRequests.first(where: { $0.id == id }) {
            skipRequests.remove(item)
            if item.saveLocally {
                persist()
            }
        }
    }

    func clear() {
        skipRequests.removeAll()
        persist()
    }

    func register(method: HTTPMethod, rule: MatchRule, saveLocally: Bool = false) {
        let skipRequest = LoggingExclusionRule(method: method, rule: rule, saveLocally: saveLocally)
        skipRequests.insert(skipRequest)
        if saveLocally {
            persist()
        }
    }

    func register(request: LoggingExclusionRule) {
        skipRequests.insert(request)
        if request.saveLocally {
            persist()
        }
    }

    func shouldSkipLogging(_ urlRequest: URLRequest) -> Bool {
        return skipRequests.contains { $0.shouldIgnore(urlRequest) }
    }

    /// Persists skip requests marked with saveLocally to storage
    private func persist() {
        let requestsToSave = skipRequests.filter { $0.saveLocally }
        storage.save(Array(requestsToSave))
    }
}
