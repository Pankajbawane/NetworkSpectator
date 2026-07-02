//
//  LogSkipManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 09/02/26.
//

import Foundation

final class LogSkipManager: @unchecked Sendable {

    static let shared: LogSkipManager = .init()

    var skipRequests: Set<LogSkipRequest> = []
    private let storage: RuleStorage<LogSkipRequest>

    var isEnabled: Bool {
        !skipRequests.isEmpty
    }

    init(storage: RuleStorage<LogSkipRequest> = RuleStorage<LogSkipRequest>(key: .skipRules)) {
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
        let skipRequest = LogSkipRequest(method: method, rule: rule, saveLocally: saveLocally)
        skipRequests.insert(skipRequest)
        if saveLocally {
            persist()
        }
    }

    func register(request: LogSkipRequest) {
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
