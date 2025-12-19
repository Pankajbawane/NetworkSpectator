//
//  MockServer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

/// Manages registered mocks for network request interception.
final class MockServer {
    
    private(set) var mocks: [Mock] = []
    
    nonisolated(unsafe) static let shared: MockServer = .init()
    
    private init() { }
    
    /// Registers a mock to intercept matching network requests.
    /// - Parameter mock: The mock configuration to register.
    func register(_ mock: Mock) {
        mocks.append(mock)
    }
    
    func responseIfMocked(_ urlRequest: URLRequest) -> Mock? {
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
    
    /// Removes registered mock.
    func remove(id: UUID) {
        mocks.removeAll { $0.id == id }
    }
    
    /// Removes all registered mocks.
    func clear() {
        mocks.removeAll()
    }
}

