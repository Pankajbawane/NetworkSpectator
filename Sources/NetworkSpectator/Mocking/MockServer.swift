//
//  MockServer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation
import os
import NetworkSpectatorCore

/// Manages in-memory mocks for network request interception.
package final class MockServer: MockServerProvider, Sendable {

    private let state: OSAllocatedUnfairLock<Set<Mock>>

    package static let shared: MockServer = .init()

    public var mocks: Set<Mock> {
        state.withLock { $0 }
    }

    package init(state: OSAllocatedUnfairLock<Set<Mock>> = OSAllocatedUnfairLock(initialState: [])) {
        self.state = state
    }

    /// Registers a mock to intercept matching network requests.
    /// - Parameter mock: The mock configuration to register.
    package func register(_ mock: Mock) {
        state.withLock { _ = $0.insert(mock) }
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
        state.withLock { mocks in
            if let mock = mocks.first(where: { $0.id == id }) {
                mocks.remove(mock)
            }
        }
    }

    /// Removes all registered mocks.
    package func clear() {
        state.withLock { $0.removeAll() }
    }
}

extension Mock: Mockable { }
