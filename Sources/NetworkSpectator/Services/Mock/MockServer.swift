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
    private let storage: RuleStorage<Mock>

    static let shared: MockServer = .init()

    init(storage: RuleStorage<Mock> = RuleStorage<Mock>(key: .mockRules)) {
        self.storage = storage
        mocks = Set(storage.retrieve())
    }

    /// Registers a mock to intercept matching network requests.
    /// - Parameter mock: The mock configuration to register.
    func register(_ mock: Mock) {
        mocks.insert(mock)
        if mock.saveLocally {
            persist()
        }
    }

    func responseIfMocked(_ urlRequest: URLRequest) -> Mock? {
        return mocks.first { mock in
            mock.rule.matches(urlRequest)
        }
    }

    /// Removes registered mock.
    func remove(id: UUID) {
        if let mock = mocks.first(where: { $0.id == id }) {
            mocks.remove(mock)
            if mock.saveLocally {
                persist()
            }
        }
    }

    /// Removes all registered mocks.
    func clear() {
        mocks.removeAll()
        persist()
    }

    /// Persists mocks marked with saveLocally to storage
    private func persist() {
        let mocksToSave = mocks.filter { $0.saveLocally }
        storage.save(Array(mocksToSave))
    }
}

