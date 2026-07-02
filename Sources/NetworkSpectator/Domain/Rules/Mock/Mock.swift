//
//  Mock.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//

import Foundation

/// Represents a mock HTTP response for network request interception.
public struct Mock: Identifiable, Sendable {
    /// Unique identifier for this mock instance.
    public let id: UUID
    
    /// HTTP Method to match with.
    public let method: HTTPMethod

    /// The rule used to match incoming requests against this mock (e.g., URL contains, exact match).
    public let rule: MatchRule

    /// The HTTP response to return when a matching request is intercepted.
    public let response: HTTPResponse

    /// Whether this mock should be persisted to local storage across sessions.
    let saveLocally: Bool
    
    /// Mock deregisters when consumed.
    let oneShot: Bool

    /// Creates a mock with rule-based matching and JSON response.
    /// - Parameters:
    ///   - rule: Rule to match against the request URL.
    ///   - response: JSON object to be serialized as the response body.
    ///   - headers: HTTP headers to include in the response.
    ///   - statusCode: HTTP status code for the response.
    ///   - error: Optional error to return instead of a successful response.
    ///   - saveLocally: Store mock on device.
    ///   - delay: delay in response.
    internal init(method: HTTPMethod,
                  rule: MatchRule,
                  response: Data?,
                  headers: [String: String],
                  statusCode: Int,
                  error: Error?,
                  saveLocally: Bool,
                  delay: Double = 0,
                  oneShot: Bool = false) {
        let httpResponse = HTTPResponse(headers: headers,
                                    statusCode: statusCode,
                                    responseData: response,
                                    error: error,
                                    responseTime: delay)
        self.init(method: method, rule: rule, response: httpResponse, saveLocally: saveLocally)
    }
    
    /// Designated initializer that all other initializers delegate to.
    internal init(method: HTTPMethod,
                  rule: MatchRule,
                  response: HTTPResponse,
                  saveLocally: Bool = false,
                  oneShot: Bool = false) {
        self.id = UUID()
        self.method = method
        self.rule = rule
        self.response = response
        self.saveLocally = saveLocally
        self.oneShot = oneShot
    }
    
    /// Creates a mock with a pre-built ``HTTPResponse``. The mock is not persisted to local storage.
    public init(method: HTTPMethod = .GET,
                rule: MatchRule,
                response: HTTPResponse) {
        self.init(method: method, rule: rule, response: response, saveLocally: false)
    }
    
    /// Creates a mock with raw `Data` as the response body.
    /// - Parameters:
    ///   - rule: Rule to match against the request URL.
    ///   - response: Raw data to return as the response body, or `nil` for an empty body.
    ///   - headers: HTTP headers to include in the response. Defaults to empty.
    ///   - statusCode: HTTP status code for the response. Defaults to `200`.
    ///   - error: Optional error to simulate a network failure.
    ///   - delay: Simulated response delay in seconds. Defaults to `0`.
    public init(method: HTTPMethod = .GET,
                rule: MatchRule,
                response: Data?,
                headers: [String: String] = [:],
                statusCode: Int = 200,
                error: Error? = nil,
                delay: Double = 0) {
        let httpResponse = HTTPResponse(headers: headers,
                                        statusCode: statusCode,
                                        responseData: response,
                                        error: error,
                                        responseTime: delay)
        self.init(method: method, rule: rule, response: httpResponse, saveLocally: false)
    }
    
    /// Creates a mock with a JSON dictionary as the response body.
    /// - Parameters:
    ///   - rule: Rule to match against the request URL.
    ///   - response: A JSON-compatible dictionary to serialize as the response body.
    ///   - headers: HTTP headers to include in the response. Defaults to empty.
    ///   - statusCode: HTTP status code for the response. Defaults to `200`.
    ///   - error: Optional error to simulate a network failure.
    ///   - delay: Simulated response delay in seconds. Defaults to `0`.
    /// - Throws: An error if `response` cannot be serialized to JSON.
    public init(method: HTTPMethod = .GET,
                rule: MatchRule,
                response: [AnyHashable: Any],
                headers: [String: String] = [:],
                statusCode: Int = 200,
                error: Error? = nil,
                delay: Double = 0) throws {
        let respnseData = try JSONSerialization.data(withJSONObject: response)
        let response = HTTPResponse(headers: headers,
                                    statusCode: statusCode,
                                    responseData: respnseData,
                                    error: error,
                                    responseTime: delay)
        self.init(method: method, rule: rule, response: response, saveLocally: false)
    }
    
    /// Builds an `HTTPURLResponse` from this mock's response for the given request.
    /// Automatically injects a `Content-Type` header when the response has a known MIME type.
    /// - Parameter request: The intercepted URL request to generate a response for.
    /// - Returns: An `HTTPURLResponse`, or `nil` if the request has no URL.
    internal func urlResponse(_ request: URLRequest) -> HTTPURLResponse? {
        guard let url = request.url else { return nil }
        
        var httpHeaders = response.headers
        if response.mimeType != .empty {
            httpHeaders["Content-Type"] = response.mimeType.raw
        }
        return HTTPURLResponse(url: url,
                               statusCode: response.statusCode,
                               httpVersion: nil,
                               headerFields: httpHeaders)
    }
}

// MARK: - Equatable & Hashable
// Identity is based on `rule` and `response`, not `id`, so two mocks with
// the same matching rule and response are considered equal regardless of UUID.
extension Mock: Equatable {
    public static func == (lhs: Mock, rhs: Mock) -> Bool {
        lhs.method == rhs.method &&
        lhs.rule == rhs.rule &&
        lhs.response == rhs.response
    }
}

extension Mock: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(method)
        hasher.combine(rule)
        hasher.combine(response)
    }
}

// MARK: - Codable
// Enables persistence to local storage.
extension Mock: Codable {
}
