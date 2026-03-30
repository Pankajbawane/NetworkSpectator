//
//  MockServer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation
import os

/// Manages registered mocks for network request interception.
final class MockServer: @unchecked Sendable {

    private let state: OSAllocatedUnfairLock<Set<Mock>>
    private let storage: RuleStorage<Mock>

    static let shared: MockServer = .init()

    var mocks: Set<Mock> {
        state.withLock { $0 }
    }

    init(storage: RuleStorage<Mock> = RuleStorage<Mock>(key: .mockRules)) {
        self.storage = storage
        state = OSAllocatedUnfairLock(initialState: Set(storage.retrieve()))
    }

    /// Creates an empty mock server with no persisted mocks.
    /// Used by the test harness to isolate test mocks from UI mocks.
    static func defaultServer() -> MockServer {
        MockServer(state: OSAllocatedUnfairLock(initialState: []),
                   storage: RuleStorage<Mock>(key: .mockRules))
    }

    private init(state: OSAllocatedUnfairLock<Set<Mock>>, storage: RuleStorage<Mock>) {
        self.state = state
        self.storage = storage
    }

    /// Registers a mock to intercept matching network requests.
    /// - Parameter mock: The mock configuration to register.
    func register(_ mock: Mock) {
        state.withLock { _ = $0.insert(mock) }
        if mock.saveLocally {
            persist()
        }
    }

    func responseIfMocked(_ urlRequest: URLRequest) -> Mock? {
        state.withLock { mocks in
            mocks.first { $0.rule.matches(urlRequest) }
        }
    }

    /// Removes registered mock.
    func remove(id: UUID) {
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
    func clear() {
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

