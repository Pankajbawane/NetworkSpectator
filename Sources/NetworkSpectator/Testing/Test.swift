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
/// the convenience `setResponse(…)` methods.
///
/// ```swift
/// // One time setup in Tests.
/// NetworkSpectator.test.setUp()
///
/// server.setResponse(
///     method: .GET,
///     rule: .path("/api/users"),
///     json: ["name": "pankaj"],
///     statusCode: 200
/// )
///
/// // … run your networking code …
///
/// ```

public class TestServer: @unchecked Sendable {
    
    // MARK: - Lifecycle
    
    internal init() {}
    
    private(set) var isLoggingEnabled: Bool = false
    private var setupComplete: Bool = false
    
    /// Enables request interception for test execution.
    ///
    /// Call this once before the code under test creates network requests.
    /// When `logging` is `true`, intercepted requests are also recorded by the
    /// test logger.
    func setUp(logging: Bool = false) {
        guard !setupComplete else { return }
        defer { setupComplete = true }
        isLoggingEnabled = logging
        NetworkURLProtocol.logger = TestItemLogger(loggingEnabled: logging)
        NetworkURLProtocol.mockServer = .testServer
        NetworkURLProtocol.mockServer.clear()
        NetworkInterceptor.shared.enable()
    }
    
    /// Disables request interception and clears all registered test mocks.
    ///
    /// Call this after each test, or from shared teardown code, to restore the
    /// default interceptor configuration.
     func tearDown() {
        guard setupComplete else { return }
        defer { setupComplete = false }
        isLoggingEnabled = false
        NetworkInterceptor.shared.disable()
        NetworkURLProtocol.mockServer.clear()
        NetworkURLProtocol.mockServer = .shared
    }
    
    // MARK: - Mock Registration
    
    /// Registers a mocked JSON response for requests that match the given method and rule.
    ///
    /// - Parameters:
    ///   - method: The HTTP method that the intercepted request must use.
    ///   - rule: The ``MatchRule`` that determines which requests are intercepted.
    ///   - json: A JSON-serializable dictionary returned as the response body.
    ///   - statusCode: HTTP status code (default `200`).
    ///   - headers: Additional response headers (default empty).
    ///   - delay: Simulated network delay in seconds (default `0`).
    func setResponse(
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
        NetworkURLProtocol.mockServer.register(Mock(method: method,
                                                    rule: rule,
                                                    response: response,
                                                    oneShot: true))
    }
    
    /// Registers a mocked raw-data response for requests that match the given method and rule.
    ///
    /// - Parameters:
    ///   - method: The HTTP method that the intercepted request must use.
    ///   - rule: The ``MatchRule`` that determines which requests are intercepted.
    ///   - data: Raw bytes returned as the response body.
    ///   - statusCode: HTTP status code (default `200`).
    ///   - headers: Additional response headers (default empty).
    ///   - delay: Simulated network delay in seconds (default `0`).
    func setResponse(
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
        NetworkURLProtocol.mockServer.register(Mock(method: method,
                                                    rule: rule,
                                                    response: response,
                                                    oneShot: true))
    }
    
    /// Registers a mocked network failure for requests that match the given method and rule.
    ///
    /// - Parameters:
    ///   - method: The HTTP method that the intercepted request must use.
    ///   - rule: The ``MatchRule`` that determines which requests are intercepted.
    ///   - error: The error to surface (default `URLError(.notConnectedToInternet)`).
    func setErrorResponse(
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
        NetworkURLProtocol.mockServer.register(Mock(method: method,
                                                    rule: rule,
                                                    response: response,
                                                    oneShot: true))
    }
    
    // MARK: - Mock Removal
    
    /// Removes every mock currently registered with the test server.
    func removeAllMocks() {
        NetworkURLProtocol.mockServer.clear()
    }
}
