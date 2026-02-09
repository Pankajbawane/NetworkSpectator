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

    var isEnabled: Bool {
        !skipRequests.isEmpty
    }

    private init() {
        let storage = RuleStorage<SkipRequestForLogging>(key: .skipRules)
        skipRequests = Set(storage.retrieve())
    }

    func remove(id: UUID) {
        if let item = skipRequests.first { $0.id == id } {
            skipRequests.remove(item)
        }
    }
    
    func clear() {
        skipRequests.removeAll()
    }

    func register(rules: [MatchRule]) {
        let skipRequest = SkipRequestForLogging(rules: rules)
        skipRequests.insert(skipRequest)
    }

    func register(rule: MatchRule) {
        let skipRequest = SkipRequestForLogging(rule: rule)
        skipRequests.insert(skipRequest)
    }
    
    func register(request: SkipRequestForLogging) {
        skipRequests.insert(request)
    }

    func shouldSkipLogging(_ urlRequest: URLRequest) -> Bool {
        return skipRequests.contains { $0.shouldIgnore(urlRequest) }
    }
}
