//
//  MockManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

public struct Mock {
    let headers: [String: String]
    let statusCode: Int
    let response: Data?
    let error: Error?
    let rules: [MatchRule]?
    let matches: ((URLRequest) -> Bool)?
    
    internal func urlResponse(_ request: URLRequest) -> HTTPURLResponse? {
        guard let url = request.url else { return nil }
        
        return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
    }
    
    init(rules: [MatchRule], response: [AnyHashable: Any]?, headers: [String: String] = [:], statusCode: Int = 200, error: Error? = nil) throws {
        self.rules = rules
        self.response = try JSONSerialization.data(withJSONObject: response, options: [])
        self.headers = headers
        self.statusCode = statusCode
        self.matches = nil
        self.error = error
    }
    
    init(rules: [MatchRule], response: Data?, headers: [String: String] = [:], statusCode: Int = 200, error: Error? = nil) {
        self.rules = rules
        self.response = response
        self.headers = headers
        self.statusCode = statusCode
        self.matches = nil
        self.error = error
    }
    
    init(response: [AnyHashable: Any]?, headers: [String: String] = [:], statusCode: Int = 200, error: Error? = nil, matches: @escaping (URLRequest) -> Bool) throws {
        self.rules = nil
        self.response = try JSONSerialization.data(withJSONObject: response, options: [])
        self.headers = headers
        self.statusCode = statusCode
        self.matches = matches
        self.error = error
    }
    
    init(response: Data?, headers: [String: String] = [:], statusCode: Int = 200, error: Error? = nil, matches: @escaping (URLRequest) -> Bool) {
        self.rules = nil
        self.response = response
        self.headers = headers
        self.statusCode = statusCode
        self.matches = matches
        self.error = error
    }
}

public final class MockManager {
    
    internal var mocks: [Mock] = []
    
    nonisolated(unsafe) public static let shared = MockManager()
    
    public func register(_ mock: Mock) {
        mocks.append(mock)
    }
    
    func responseIfMocked(_ urlRequest: URLRequest) -> Mock? {
        guard let url = urlRequest.url else { return nil }
        if let match = mocks.first(where: { item in
            if let matches = item.matches, matches(urlRequest) {
                return true
            }
            if let rules = item.rules, rules.allSatisfy({ $0.matches(url) }) {
                return true
            }
            return false
        }) {
            return match
        }
        return nil
    }
    
    public func clear() {
        mocks.removeAll()
    }
}

