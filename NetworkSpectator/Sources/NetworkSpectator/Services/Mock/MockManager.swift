//
//  MockServer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

/// Manages registered mocks for network request interception.
final class MockServer {
    
    internal var mocks: [Mock] = []
    
    internal init() { }
    
    /// Registers a mock to intercept matching network requests.
    /// - Parameter mock: The mock configuration to register.
    func register(_ mock: Mock) {
        mocks.append(mock)
    }
    
    internal func responseIfMocked(_ urlRequest: URLRequest) -> Mock? {
        guard let url = urlRequest.url else { return nil }
        return mocks.first { mock in
            if let matches = mock.matches {
                return matches(urlRequest)
            }
            if let rules = mock.rules {
                return rules.allSatisfy { $0.matches(url) }
            }
            return false
        }
        
    }
    
    /// Removes all registered mocks.
    public func clear() {
        mocks.removeAll()
    }
}

