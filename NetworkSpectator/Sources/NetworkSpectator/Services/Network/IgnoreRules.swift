//
//  IgnoreRules.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

public enum MatchRule {
    case hostName(String)
    case url(String)
    case path(String)
    case endPath(String)
    case pathComponent(String)
}

public struct IgnoreRequest {
    
    let rules: [MatchRule]
    
    private(set) var hostName: String = ""
    private(set) var url: String = ""
    private(set) var path: String = ""
    private(set) var urlQuery: [URLQueryItem] = []
    private(set) var urlQueryKey: [String] = []
    private(set) var endPath: String = ""
    private(set) var pathComponent: String = ""
    
    init(rules: [MatchRule]) {
        self.rules = rules
        for rule in rules {
            switch rule {
            case .hostName(let host):
                self.hostName = host
            case .url(let url):
                self.url = url
            case .path(let path):
                self.path = path
            case .endPath(let endpath):
                self.endPath = endpath
            case .pathComponent(let pathComponent):
                self.pathComponent = pathComponent
            }
        }
    }
    
    mutating func add(_ rule: MatchRule) {
        switch rule {
        case .hostName(let host):
            self.hostName = host
        case .url(let url):
            self.url = url
        case .path(let path):
            self.path = path
        case .endPath(let endpath):
            self.endPath = endpath
        case .pathComponent(let pathComponent):
            self.pathComponent = pathComponent
        }
    }
}

public class IgnoreRequestManager {
    
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
    
    func shouldIgnore(_ url: URL) -> Bool {
        
        for item in ignoreRequests {
            
            var ruleMatched: Bool = false
            for rule in item.rules {
                switch rule {
                case .hostName(let string):
                    if !string.isEmpty {
                        ruleMatched = url.host == string
                    }
                case .url(let string):
                    if !string.isEmpty {
                        ruleMatched = url.absoluteString == string
                    }
                case .path(let string):
                    if !string.isEmpty {
                        ruleMatched = url.path() == string
                    }
                case .endPath(let string):
                    if !string.isEmpty {
                        ruleMatched = url.lastPathComponent == string
                    }
                case .pathComponent(let string):
                    if !string.isEmpty {
                        ruleMatched = url.absoluteString.contains(string)
                    }
                }
            }
            
            if ruleMatched {
                return true
            }
        }
        
        return false
    }
}
