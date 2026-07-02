//
//  LogSkipRequest.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

public struct LogSkipRequest: Identifiable, Hashable, Codable {

    public let id: UUID
    let rule: MatchRule
    let saveLocally: Bool

    public init(method: HTTPMethod,
                rule: MatchRule,
                id: UUID = UUID(),
                saveLocally: Bool = false) {
        self.rule = rule
        self.id = id
        self.saveLocally = saveLocally
    }

    func shouldIgnore(_ urlRequest: URLRequest) -> Bool {
        return rule.matches(urlRequest)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: LogSkipRequest, rhs: LogSkipRequest) -> Bool {
        lhs.id == rhs.id
    }
}

