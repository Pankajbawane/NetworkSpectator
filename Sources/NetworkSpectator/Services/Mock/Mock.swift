//
//  Mock.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//


import Foundation

/// Represents a mock HTTP response for network request interception.
public struct Mock: Identifiable, Sendable {
    public let id: UUID
    let headers: [String: String]
    let statusCode: Int
    let response: Data?
    let error: Error?
    let rule: MatchRule
    let saveLocally: Bool
    let delay: Double

    private init(response: Data?,
                 headers: [String: String],
                 statusCode: Int,
                 error: Error?,
                 rule: MatchRule,
                 saveLocally: Bool,
                 delay: Double = 0) {
        self.id = UUID()
        self.headers = headers
        self.statusCode = statusCode
        self.response = response
        self.error = error
        self.rule = rule
        self.saveLocally = saveLocally
        self.delay = delay
    }

    internal func urlResponse(_ request: URLRequest) -> HTTPURLResponse? {
        guard let url = request.url else { return nil }

        return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
    }

    /// Creates a mock with rule-based matching and JSON response.
    /// - Parameters:
    ///   - rule: Rule to match against the request URL.
    ///   - response: JSON object to be serialized as the response body.
    ///   - headers: HTTP headers to include in the response.
    ///   - statusCode: HTTP status code for the response.
    ///   - error: Optional error to return instead of a successful response.
    ///   - saveLocally: Store mock on device.
    ///   - delay: delay in response.
    public init(rule: MatchRule,
                response: [AnyHashable: Any]?,
                headers: [String: String] = [:],
                statusCode: Int = 200,
                error: Error? = nil,
                saveLocally: Bool = false,
                delay: Double = 0) throws {
        let responseData = try response.map { try JSONSerialization.data(withJSONObject: $0, options: []) }
        self.init(response: responseData,
                  headers: headers,
                  statusCode: statusCode,
                  error: error,
                  rule: rule,
                  saveLocally: saveLocally,
                  delay: delay)
    }

    /// Creates a mock with rule-based matching and raw data response.
    /// - Parameters:
    ///   - rule: Rule to match against the request URL.
    ///   - response: Raw data to return as the response body.
    ///   - headers: HTTP headers to include in the response.
    ///   - statusCode: HTTP status code for the response.
    ///   - error: Optional error to return instead of a successful response.
    ///   - saveLocally: Store mock on device.
    ///   - delay: delay in response.
    public init(rule: MatchRule,
                response: Data?,
                headers: [String: String] = [:],
                statusCode: Int = 200,
                error: Error? = nil,
                saveLocally: Bool = false,
                delay: Double = 0) {
        self.init(response: response,
                  headers: headers,
                  statusCode: statusCode,
                  error: error,
                  rule: rule,
                  saveLocally: saveLocally,
                  delay: delay)
    }
}

extension Mock: Equatable {
    public static func == (lhs: Mock, rhs: Mock) -> Bool {
        lhs.id == rhs.id
    }
}

extension Mock: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Mock: Codable {
    enum CodingKeys: String, CodingKey {
        case id, headers, statusCode, response, saveLocally, rule, delay
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        headers = try container.decode([String: String].self, forKey: .headers)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        response = try container.decodeIfPresent(Data.self, forKey: .response)
        saveLocally = try container.decode(Bool.self, forKey: .saveLocally)
        rule = try container.decode(MatchRule.self, forKey: .rule)
        delay = try container.decode(Double.self, forKey: .delay)
        self.error = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(headers, forKey: .headers)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(response, forKey: .response)
        try container.encode(rule, forKey: .rule)
        try container.encode(saveLocally, forKey: .saveLocally)
        try container.encode(delay, forKey: .delay)
    }
}
