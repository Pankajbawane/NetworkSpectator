//
//  NetworkSpectatorMocking.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 06/07/26.
//

import Foundation
@_exported import NetworkSpectatorCore

/// Public entry point for mock-only NetworkSpectator integrations.
///
/// Import `NetworkSpectatorMocking` when you only need in-memory mock responses and do not
/// want to import logging, persistence, exports, or UI presentation.
public enum NetworkSpectatorMocking {

    /// Starts mock-only network interception.
    ///
    /// Registered mocks are served from `MockServer.shared`. Logging remains disabled unless
    /// the logging module is started separately.
    public static func start() {
        NetworkURLProtocol.logger = DefaultItemLogger()
        NetworkURLProtocol.mockServer = MockServer.shared
        NetworkInterceptor.shared.enable(for: .mocking)
    }

    /// Stops mock-only network interception.
    ///
    /// If logging is still active, URL interception remains registered for logging and mock
    /// responses are disabled until mocking or full logging setup installs a mock server again.
    public static func stop() {
        NetworkURLProtocol.mockServer = DefaultMockServer()
        NetworkInterceptor.shared.disable(for: .mocking)
    }

    /// Registers an in-memory mock response.
    public static func register(_ mock: Mock) {
        MockServer.shared.register(mock)
    }

    /// Removes a registered in-memory mock response.
    public static func remove(id: UUID) {
        MockServer.shared.remove(id: id)
    }

    /// Removes all registered in-memory mock responses.
    public static func clearMocks() {
        MockServer.shared.clear()
    }

    /// The current in-memory mock set.
    public static var mocks: Set<Mock> {
        MockServer.shared.mocks
    }
}
