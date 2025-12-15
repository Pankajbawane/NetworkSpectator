//
//  IgnoreRequest.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

public struct IgnoreRequest {

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

public final class IgnoreRequestManager {

    private var ignoreRequests: [IgnoreRequest] = []

    public nonisolated(unsafe) static let shared = IgnoreRequestManager()

    var isEnabled: Bool {
        !ignoreRequests.isEmpty
    }

    private init() { }

    public func disable() {
        ignoreRequests.removeAll()
    }

    public func register(_ rule: IgnoreRequest) {
        ignoreRequests.append(rule)
    }

    public func register(rules: [MatchRule]) {
        let ignoreRequest = IgnoreRequest(rules: rules)
        ignoreRequests.append(ignoreRequest)
    }

    public func register(rule: MatchRule) {
        let ignoreRequest = IgnoreRequest(rule: rule)
        ignoreRequests.append(ignoreRequest)
    }

    func shouldIgnore(_ url: URL) -> Bool {
        return ignoreRequests.contains { $0.shouldIgnore(url) }
    }
}
