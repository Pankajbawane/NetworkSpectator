//
//  MatchRule.swift
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
    case regex(String)
    case queryParameter(key: String, value: String? = nil)

    func matches(_ url: URL) -> Bool {
        switch self {
        case .hostName(let pattern):
            guard let host = url.host else { return false }
            return compare(host, with: pattern)

        case .url(let pattern):
            return compare(url.absoluteString, with: pattern)

        case .path(let pattern):
            return compare(url.path(), with: pattern)

        case .endPath(let pattern):
            return compare(url.lastPathComponent, with: pattern)

        case .pathComponent(let pattern):
            let pathComponents = url.pathComponents
            return pathComponents.contains { component in
                compare(component, with: pattern)
            }

        case .regex(let pattern):
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return false
            }
            let urlString = url.absoluteString
            let range = NSRange(urlString.startIndex..., in: urlString)
            return regex.firstMatch(in: urlString, options: [], range: range) != nil

        case .queryParameter(let key, let expectedValue):
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                return false
            }

            if let expectedValue = expectedValue {
                return queryItems.contains { $0.name == key && $0.value == expectedValue }
            } else {
                return queryItems.contains { $0.name == key }
            }
        }
    }

    private func compare(_ value: String, with pattern: String) -> Bool {
        if pattern.contains("*") {
            return matchesWildcard(value, pattern: pattern)
        } else {
            return value.lowercased() == pattern.lowercased()
        }
    }

    private func matchesWildcard(_ value: String, pattern: String) -> Bool {
        let compareValue = value.lowercased()
        let comparePattern = pattern.lowercased()

        let regexPattern = "^" + comparePattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*") + "$"

        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            return false
        }

        let range = NSRange(compareValue.startIndex..., in: compareValue)
        return regex.firstMatch(in: compareValue, options: [], range: range) != nil
    }
}
