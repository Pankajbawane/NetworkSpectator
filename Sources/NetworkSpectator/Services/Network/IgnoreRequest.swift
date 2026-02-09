//
//  IgnoreRequest.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

public struct SkipRequestForLogging: Identifiable, Hashable {

    public let id: UUID = UUID()
    let rules: [MatchRule]

    public init(rules: [MatchRule]) {
        self.rules = rules
    }

    public init(rule: MatchRule) {
        self.rules = [rule]
    }

    func shouldIgnore(_ urlRequest: URLRequest) -> Bool {
        guard !rules.isEmpty else { return false }
        return rules.allSatisfy { $0.matches(urlRequest) }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rules)
    }
}

final class SkipRequestForLoggingHandler: @unchecked Sendable {

    internal static let shared: SkipRequestForLoggingHandler = .init()
    
    var skipRequests: Set<SkipRequestForLogging> = []

    var isEnabled: Bool {
        !skipRequests.isEmpty
    }

    private init() { }

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

    func shouldSkipLogging(_ urlRequest: URLRequest) -> Bool {
        return skipRequests.contains { $0.shouldIgnore(urlRequest) }
    }
}
