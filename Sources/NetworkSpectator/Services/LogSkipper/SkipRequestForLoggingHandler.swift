//
//  SkipRequestForLoggingHandler.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 09/02/26.
//

import Foundation

final class SkipRequestForLoggingHandler: @unchecked Sendable {

    internal static let shared: SkipRequestForLoggingHandler = .init()

    var skipRequests: Set<SkipRequestForLogging> = []
    private let storage: RuleStorage<SkipRequestForLogging>

    var isEnabled: Bool {
        !skipRequests.isEmpty
    }

    init(storage: RuleStorage<SkipRequestForLogging> = RuleStorage<SkipRequestForLogging>(key: .skipRules)) {
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

    func register(rule: MatchRule, saveLocally: Bool = false) {
        let skipRequest = SkipRequestForLogging(rule: rule, saveLocally: saveLocally)
        skipRequests.insert(skipRequest)
        if saveLocally {
            persist()
        }
    }

    func register(request: SkipRequestForLogging) {
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
