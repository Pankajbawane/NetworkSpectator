//
//  MockServer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

/// Manages registered mocks for network request interception.
final class MockServer: @unchecked Sendable {
    
    private(set) var mocks: Set<Mock> = []
    
    static let shared: MockServer = .init()
    
    private init() {
        let storage = RuleStorage<Mock>(key: .mockRules)
        mocks = Set(storage.retrieve())
    }
    
    /// Registers a mock to intercept matching network requests.
    /// - Parameter mock: The mock configuration to register.
    func register(_ mock: Mock) {
        mocks.insert(mock)
    }
    
    func responseIfMocked(_ urlRequest: URLRequest) -> Mock? {
        guard let url = urlRequest.url else { return nil }
        return mocks.first { mock in
                return mock.rules.allSatisfy { $0.matches(urlRequest) }
            return false
        }
    }
    
    /// Removes registered mock.
    func remove(id: UUID) {
        if let mock = mocks.first(where: { $0.id == id }) {
            mocks.remove(mock)
        }
    }
    
    /// Removes all registered mocks.
    func clear() {
        mocks.removeAll()
    }
}

