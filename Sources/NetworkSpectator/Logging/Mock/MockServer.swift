//
//  MockServer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation
import os
import NetworkSpectatorCore

/// Manages registered mocks for network request interception.
package final class MockServer: Sendable {

    private let state: OSAllocatedUnfairLock<Set<Mock>>
    private let storage: RuleStorage<Mock>
    
    package static let shared: MockServer = .init()

    package var mocks: Set<Mock> {
        state.withLock { $0 }
    }

    package init(state: OSAllocatedUnfairLock<Set<Mock>> = OSAllocatedUnfairLock(initialState: []),
                storage: RuleStorage<Mock> = RuleStorage<Mock>(key: .mockRules)) {
        self.storage = storage
        self.state = state
    }

    /// Registers a mock to intercept matching network requests.
    /// - Parameter mock: The mock configuration to register.
    package func register(_ mock: Mock) {
        state.withLock { _ = $0.insert(mock) }
        if mock.saveLocally {
            persist()
        }
    }

    package func responseIfMocked(_ urlRequest: URLRequest) -> Mock? {
        let mock = state.withLock { mocks in
            mocks.first { $0.method.rawValue == urlRequest.httpMethod && $0.rule.matches(urlRequest) }
        }
        if let mock, mock.oneShot {
            remove(id: mock.id)
        }
        return mock
    }

    /// Removes registered mock.
    package func remove(id: UUID) {
        let removedMock: Mock? = state.withLock { mocks in
            if let mock = mocks.first(where: { $0.id == id }) {
                mocks.remove(mock)
                return mock
            }
            return nil
        }
        if let mock = removedMock, mock.saveLocally {
            persist()
        }
    }

    /// Removes all registered mocks.
    package func clear() {
        state.withLock { $0.removeAll() }
        persist()
    }

    /// Persists mocks marked with saveLocally to storage
    private func persist() {
        let mocksToSave = state.withLock { mocks in
            mocks.filter { $0.saveLocally }
        }
        if mocksToSave.isEmpty {
            storage.clear()
        } else {
            storage.save(Array(mocksToSave))
        }
    }
}

extension Mock: Mockable { }
