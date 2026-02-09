//
//  Mock.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 15/12/25.
//


import Foundation

/// Represents a mock HTTP response for network request interception.
public struct Mock: Identifiable {
    public let id: UUID
    let headers: [String: String]
    let statusCode: Int
    let response: Data?
    let error: Error?
    let rules: [MatchRule]
    let saveLocally: Bool

    private init(response: Data?,
                 headers: [String: String],
                 statusCode: Int,
                 error: Error?,
                 rules: [MatchRule],
                 saveLocally: Bool) {
        self.id = UUID()
        self.headers = headers
        self.statusCode = statusCode
        self.response = response
        self.error = error
        self.rules = rules
        self.saveLocally = saveLocally
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
                error: Error? = nil,
                saveLocally: Bool = false) throws {
        let responseData = try response.map { try JSONSerialization.data(withJSONObject: $0, options: []) }
        self.init(response: responseData, headers: headers, statusCode: statusCode, error: error, rules: rules, saveLocally: saveLocally)
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
                error: Error? = nil,
                saveLocally: Bool = false) {
        self.init(response: response, headers: headers, statusCode: statusCode, error: error, rules: rules, saveLocally: saveLocally)
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
        case id, headers, statusCode, response, saveLocally, rules
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        headers = try container.decode([String: String].self, forKey: .headers)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        response = try container.decodeIfPresent(Data.self, forKey: .response)
        saveLocally = try container.decode(Bool.self, forKey: .saveLocally)
        rules = try container.decode([MatchRule].self, forKey: .rules)
        self.error = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(headers, forKey: .headers)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(response, forKey: .response)
        try container.encode(rules, forKey: .rules)
        try container.encode(saveLocally, forKey: .saveLocally)
    }
}
