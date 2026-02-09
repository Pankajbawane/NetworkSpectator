//
//  SkipRequestForLogging.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

public struct SkipRequestForLogging: Identifiable, Hashable, Codable {

    public let id: UUID
    let rules: [MatchRule]
    let saveLocally: Bool

    public init(rules: [MatchRule], id: UUID = UUID(), saveLocally: Bool = false) {
        self.rules = rules
        self.id = id
        self.saveLocally = saveLocally
    }

    public init(rule: MatchRule, id: UUID = UUID(), saveLocally: Bool = false) {
        self.rules = [rule]
        self.id = id
        self.saveLocally = saveLocally
    }

    func shouldIgnore(_ urlRequest: URLRequest) -> Bool {
        guard !rules.isEmpty else { return false }
        return rules.allSatisfy { $0.matches(urlRequest) }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: SkipRequestForLogging, rhs: SkipRequestForLogging) -> Bool {
        lhs.id == rhs.id
    }
}

