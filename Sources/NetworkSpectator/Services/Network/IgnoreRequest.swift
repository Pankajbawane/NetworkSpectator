//
//  IgnoreRequest.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

public struct SkipRequestForLogging: Identifiable {

    public let id: UUID = UUID()
    let rules: [MatchRule]

    public init(rules: [MatchRule]) {
        self.rules = rules
    }

    public init(rule: MatchRule) {
        self.rules = [rule]
    }

    func shouldIgnore(_ url: URL) -> Bool {
        guard !rules.isEmpty else { return false }
        return rules.allSatisfy { $0.matches(url) }
    }
}

final class SkipRequestForLoggingHandler {

    internal nonisolated(unsafe) static let shared: SkipRequestForLoggingHandler = .init()
    
    var skipRequests: [SkipRequestForLogging] = []

    var isEnabled: Bool {
        !skipRequests.isEmpty
    }

    init() { }

    func clear() {
        skipRequests.removeAll()
    }

    func register(rules: [MatchRule]) {
        let skipRequest = SkipRequestForLogging(rules: rules)
        skipRequests.append(skipRequest)
    }

    func register(rule: MatchRule) {
        let skipRequest = SkipRequestForLogging(rule: rule)
        skipRequests.append(skipRequest)
    }

    func shouldSkipLogging(_ url: URL) -> Bool {
        return skipRequests.contains { $0.shouldIgnore(url) }
    }
}
