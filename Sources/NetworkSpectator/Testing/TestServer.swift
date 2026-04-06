//
//  TestServer.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 29/03/26.
//

import Foundation

/// Entry point for using NetworkSpectator in unit tests.
///
/// Call ``setUp()`` at the start of your test (or in a shared setup method)
/// and ``tearDown()`` when done.  Between those calls, register mocks with
/// the convenience `mock(…)` methods.
///
/// ```swift
/// // In your test setUp
/// NetworkSpectator.Test.setUp()
///
/// // Register a mock
/// NetworkSpectator.Test.mock(
///     rule: .path("/api/users"),
///     json: ["name": "pankaj"],
///     statusCode: 200
/// )
///
/// // … run your networking code …
///
/// // In your test tearDown
/// NetworkSpectator.Test.tearDown()
/// ```

public extension NetworkSpectator {
    final class TestServer: Sendable { }
}

public extension NetworkSpectator.TestServer {
    
    // MARK: - Lifecycle
    
    /// Enables network interception with the test logger.
    /// Call once before your tests make network requests.
    static func setUp() {
        NetworkURLProtocol.logger = TestLogItemLogger()
        NetworkURLProtocol.mockServer = .testServer()
        NetworkInterceptor.shared.enable()
    }
    
    /// Disables interception and removes all mocks.
    /// Call after your tests complete.
    static func tearDown() {
        NetworkInterceptor.shared.disable()
        NetworkURLProtocol.mockServer.clear()
        NetworkURLProtocol.mockServer = .shared
    }
    
    // MARK: - Mock Registration
    
    /// Mocks a JSON response for requests matching the given rule.
    ///
    /// - Parameters:
    ///   - rule: The ``MatchRule`` that determines which requests are intercepted.
    ///   - json: A JSON-serializable dictionary returned as the response body.
    ///   - statusCode: HTTP status code (default `200`).
    ///   - headers: Additional response headers (default empty).
    ///   - delay: Simulated network delay in seconds (default `0`).
    static func mock(
        method: HTTPMethod,
        rule: MatchRule,
        json: [String: Any],
        statusCode: Int = 200,
        headers: [String: String] = [:],
        delay: Double = 0
    ) {
        let data = try? JSONSerialization.data(withJSONObject: json)
        let response = HTTPResponse(
            headers: headers,
            statusCode: statusCode,
            responseData: data,
            error: nil,
            responseTime: delay,
            mimeType: .json
        )
        NetworkURLProtocol.mockServer.register(Mock(method: method, rule: rule, response: response))
    }
    
    /// Mocks a raw `Data` response for requests matching the given rule.
    ///
    /// - Parameters:
    ///   - rule: The ``MatchRule`` that determines which requests are intercepted.
    ///   - data: Raw bytes returned as the response body.
    ///   - statusCode: HTTP status code (default `200`).
    ///   - headers: Additional response headers (default empty).
    ///   - delay: Simulated network delay in seconds (default `0`).
    static func mock(
        method: HTTPMethod,
        rule: MatchRule,
        data: Data?,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        delay: Double = 0
    ) {
        let response = HTTPResponse(
            headers: headers,
            statusCode: statusCode,
            responseData: data,
            error: nil,
            responseTime: delay
        )
        NetworkURLProtocol.mockServer.register(Mock(method: method, rule: rule, response: response))
    }
    
    /// Mocks a network failure for requests matching the given rule.
    ///
    /// - Parameters:
    ///   - rule: The ``MatchRule`` that determines which requests are intercepted.
    ///   - error: The error to surface (default `URLError(.notConnectedToInternet)`).
    static func mockError(
        method: HTTPMethod,
        rule: MatchRule,
        error: Error = URLError(.notConnectedToInternet)
    ) {
        let response = HTTPResponse(
            headers: [:],
            statusCode: 0,
            responseData: nil,
            error: error
        )
        NetworkURLProtocol.mockServer.register(Mock(method: method, rule: rule, response: response))
    }
    
    // MARK: - Mock Removal
    
    /// Removes all registered mocks.
    static func removeAllMocks() {
        NetworkURLProtocol.mockServer.clear()
    }
}
