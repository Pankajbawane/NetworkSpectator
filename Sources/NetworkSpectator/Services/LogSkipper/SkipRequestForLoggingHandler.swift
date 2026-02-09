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
    private let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules)

    var isEnabled: Bool {
        !skipRequests.isEmpty
    }

    private init() {
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

    func register(rules: [MatchRule], saveLocally: Bool = false) {
        let skipRequest = SkipRequestForLogging(rules: rules, saveLocally: saveLocally)
        skipRequests.insert(skipRequest)
        if saveLocally {
            persist()
        }
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
