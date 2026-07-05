//
//  LoggingExclusionRule.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation
import NetworkSpectatorCore

public struct LoggingExclusionRule: Identifiable, Hashable, Codable {

    public var id: UUID = UUID()
    public let method: HTTPMethod
    public let rule: MatchRule
    public let saveLocally: Bool

    public init(method: HTTPMethod,
                rule: MatchRule,
                saveLocally: Bool = false) {
        self.method = method
        self.rule = rule
        self.saveLocally = saveLocally
    }

    func shouldIgnore(_ urlRequest: URLRequest) -> Bool {
        return rule.matches(urlRequest)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: LoggingExclusionRule, rhs: LoggingExclusionRule) -> Bool {
        lhs.id == rhs.id
    }
}

