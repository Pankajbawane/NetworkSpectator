//
//  Test.swift
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
public final class Test: Sendable {
    
    // MARK: - Lifecycle
    
    /// Enables network interception with the test logger.
    /// Call once before your tests make network requests.
    public static func setUp() {
        NetworkURLProtocol.logger = LogItemStoreTests()
        NetworkInterceptor.shared.enable()
    }
    
    /// Disables interception and removes all mocks.
    /// Call after your tests complete.
    public static func tearDown() {
        NetworkInterceptor.shared.disable()
        MockServer.shared.clear()
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
    public static func mock(
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
        MockServer.shared.register(Mock(rule: rule, response: response))
    }
    
    /// Mocks a raw `Data` response for requests matching the given rule.
    ///
    /// - Parameters:
    ///   - rule: The ``MatchRule`` that determines which requests are intercepted.
    ///   - data: Raw bytes returned as the response body.
    ///   - statusCode: HTTP status code (default `200`).
    ///   - headers: Additional response headers (default empty).
    ///   - delay: Simulated network delay in seconds (default `0`).
    public static func mock(
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
        MockServer.shared.register(Mock(rule: rule, response: response))
    }
    
    /// Mocks a network failure for requests matching the given rule.
    ///
    /// - Parameters:
    ///   - rule: The ``MatchRule`` that determines which requests are intercepted.
    ///   - error: The error to surface (default `URLError(.notConnectedToInternet)`).
    public static func mockError(
        rule: MatchRule,
        error: Error = URLError(.notConnectedToInternet)
    ) {
        let response = HTTPResponse(
            headers: [:],
            statusCode: 0,
            responseData: nil,
            error: error
        )
        MockServer.shared.register(Mock(rule: rule, response: response))
    }
    
    // MARK: - Mock Removal
    
    /// Removes all registered mocks.
    public static func removeAllMocks() {
        MockServer.shared.clear()
    }
}
