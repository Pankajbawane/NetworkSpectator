//
//  PersistentMockServer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 05/07/26.
//

import Foundation
import NetworkSpectatorMocking

/// Persists mocks for logging/UI integrations while keeping Mocking memory-only.
package final class PersistentMockServer: Sendable {

    package static let shared = PersistentMockServer()

    private let storage: RuleStorage<Mock>
    private let mockServer: MockServer

    package init(storage: RuleStorage<Mock> = RuleStorage<Mock>(key: .mockRules),
                 mockServer: MockServer = .shared) {
        self.storage = storage
        self.mockServer = mockServer
        load()
    }

    package var mocks: Set<Mock> {
        mockServer.mocks
    }

    package func load() {
        storage.retrieve().forEach(mockServer.register)
    }

    package func register(_ mock: Mock) {
        mockServer.register(mock)
        persistIfNeeded(for: mock)
    }

    package func remove(id: UUID) {
        let removedMock = mockServer.mocks.first { $0.id == id }
        mockServer.remove(id: id)
        if removedMock?.saveLocally == true {
            persistCurrentMocks()
        }
    }

    package func clear() {
        mockServer.clear()
        storage.clear()
    }

    private func persistIfNeeded(for mock: Mock) {
        guard mock.saveLocally else { return }
        persistCurrentMocks()
    }

    private func persistCurrentMocks() {
        let mocksToSave = mockServer.mocks.filter { $0.saveLocally }
        if mocksToSave.isEmpty {
            storage.clear()
        } else {
            storage.save(Array(mocksToSave))
        }
    }
}
