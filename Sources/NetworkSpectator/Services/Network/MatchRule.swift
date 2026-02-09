//
//  MatchRule.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

public enum MatchRule: Equatable, Hashable {
    case hostName(String)
    case url(String)
    case path(String)
    case endPath(String)
    case subPath(String)
    case regex(String)
    case queryParameter(key: String, value: String? = nil)
    case urlRequest(URLRequest)
    
    var ruleName: String {
        switch self {
        case .hostName(let string): return "Rule_Host Name" + ": " + string
        case .url(let string): return "Rule_URL" + ": " + string
        case .path(let string): return "Rule_Path" + ": " + string
        case .endPath(let string): return "Rule_End Path" + ": " + string
        case .subPath(let string): return "Rule_Sub Path" + ": " + string
        case .regex(let string): return "Rule_Regex" + ": " + string
        case .queryParameter: return "Rule_Query Parameter"
        case .urlRequest(_): return "Rule_URLRequest"
        }
    }

    func matches(_ urlRequest: URLRequest) -> Bool {
        guard let url = urlRequest.url else {
            return self == .urlRequest(urlRequest)
        }
        
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

        case .subPath(let pattern):
            return url.absoluteString.lowercased().contains(pattern.lowercased())

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
        case .urlRequest(let thisRequest): return urlRequest == thisRequest
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

extension MatchRule: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case value
        case key
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        if type == "urlRequest" {
            // URLRequest doesn't conform to Codable, so we can't decode it
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "URLRequest cannot be decoded"
            )
        }
        
        let value = try container.decode(String.self, forKey: .value)
        
        switch type {
        case "hostName":
            self = .hostName(value)
        case "url":
            self = .url(value)
        case "path":
            self = .path(value)
        case "endPath":
            self = .endPath(value)
        case "subPath":
            self = .subPath(value)
        case "regex":
            self = .regex(value)
        case "queryParameter":
            let key = try container.decode(String.self, forKey: .key)
            self = .queryParameter(key: key, value: value)
        
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown MatchRule type: \(type)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .hostName(let value):
            try container.encode("hostName", forKey: .type)
            try container.encode(value, forKey: .value)
        case .url(let value):
            try container.encode("url", forKey: .type)
            try container.encode(value, forKey: .value)
        case .path(let value):
            try container.encode("path", forKey: .type)
            try container.encode(value, forKey: .value)
        case .endPath(let value):
            try container.encode("endPath", forKey: .type)
            try container.encode(value, forKey: .value)
        case .subPath(let value):
            try container.encode("subPath", forKey: .type)
            try container.encode(value, forKey: .value)
        case .regex(let value):
            try container.encode("regex", forKey: .type)
            try container.encode(value, forKey: .value)
        case .queryParameter(let key, let value):
            try container.encode("queryParameter", forKey: .type)
            try container.encode(key, forKey: .key)
            try container.encodeIfPresent(value, forKey: .value)
        case .urlRequest:
            // URLRequest doesn't conform to Codable, so we skip encoding
            // This will result in an incomplete encoding, but as requested
            try container.encode("urlRequest", forKey: .type)
        }
    }
}
