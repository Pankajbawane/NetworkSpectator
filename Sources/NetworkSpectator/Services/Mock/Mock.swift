//
//  Mock.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//


import Foundation

/// Represents a mock HTTP response for network request interception.
public struct Mock: Identifiable {
    public let id: UUID = UUID()
    let headers: [String: String]
    let statusCode: Int
    let response: Data?
    let error: Error?
    let rules: [MatchRule]

    private init(response: Data?,
                 headers: [String: String],
                 statusCode: Int,
                 error: Error?,
                 rules: [MatchRule]) {
        self.headers = headers
        self.statusCode = statusCode
        self.response = response
        self.error = error
        self.rules = rules
    }

    internal func urlResponse(_ request: URLRequest) -> HTTPURLResponse? {
        guard let url = request.url else { return nil }

        return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
    }

    /// Creates a mock with rule-based matching and JSON response.
    /// - Parameters:
    ///   - rules: Array of rules to match against the request URL.
    ///   - response: JSON object to be serialized as the response body.
    ///   - headers: HTTP headers to include in the response.
    ///   - statusCode: HTTP status code for the response.
    ///   - error: Optional error to return instead of a successful response.
    public init(rules: [MatchRule],
                response: [AnyHashable: Any]?,
                headers: [String: String] = [:],
                statusCode: Int = 200,
                error: Error? = nil) throws {
        let responseData = try response.map { try JSONSerialization.data(withJSONObject: $0, options: []) }
        self.init(response: responseData, headers: headers, statusCode: statusCode, error: error, rules: rules)
    }

    /// Creates a mock with rule-based matching and raw data response.
    /// - Parameters:
    ///   - rules: Array of rules to match against the request URL.
    ///   - response: Raw data to return as the response body.
    ///   - headers: HTTP headers to include in the response.
    ///   - statusCode: HTTP status code for the response.
    ///   - error: Optional error to return instead of a successful response.
    public init(rules: [MatchRule],
                response: Data?,
                headers: [String: String] = [:],
                statusCode: Int = 200,
                error: Error? = nil) {
        self.init(response: response, headers: headers, statusCode: statusCode, error: error, rules: rules)
    }
}

extension Mock: Equatable {
    public static func == (lhs: Mock, rhs: Mock) -> Bool {
        lhs.headers == rhs.headers &&
        lhs.statusCode == rhs.statusCode &&
        lhs.response == rhs.response &&
        lhs.rules == rhs.rules &&
        lhs.error?.localizedDescription == rhs.error?.localizedDescription
    }
}

extension Mock: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(headers)
        hasher.combine(statusCode)
        hasher.combine(response)
        hasher.combine(rules)
        hasher.combine(error?.localizedDescription)
    }
}
