//
//  LogItem.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import Foundation

// MARK: - LogItem
// Represents a single network log entry.
package struct LogItem: Identifiable, Codable, Equatable, Sendable, Hashable {
    // Identity & timing
    package let id: UUID
    package let url: String
    private let logStartTime: Date
    private var logFinishTime: Date?
    private var logInterval: TimeInterval

    // Request
    package let method: String
    package let headers: [String: String]
    package let requestBodyRaw: Data?

    // Response
    package private(set) var statusCode: Int
    package private(set) var responseHeaders: [String: String]
    package private(set) var mimetype: String?
    package private(set) var textEncodingName: String?

    // Raw response data (for binary content like images)
    package private(set) var responseRaw: Data?

    // Error & state
    package private(set) var errorDescription: String?
    package private(set) var errorLocalizedDescription: String?
    package private(set) var isLoading: Bool
    
    // If request is mocked
    package private(set) var mockId: UUID?
    
    // Network metrics
    package private(set) var metrics: NetworkLogMetrics?

    // MARK: - Derived
    package var host: String {
        URLComponents(string: url)?.host ?? url
    }

    package var path: String {
        URLComponents(string: url)?.percentEncodedPath ?? ""
    }

    package var scheme: String? {
        URLComponents(string: url)?.scheme
    }
    
    package var requestBody: String {
       Self.prettyPrintedBody(requestBodyRaw)
   }
    
    package var requestHeadersPrettyPrinted: String {
        Self.prettyPrintedHeaders(headers)
    }
    
    package var responseHeadersPrettyPrinted: String {
        Self.prettyPrintedHeaders(responseHeaders)
    }
    
    package var responseBody: String {
        Self.prettyPrintedBody(responseRaw)
    }
    
    // Helper timeline properties.
    // When network metrics unavailable, fallbacks to logging timings.
    package var startTime: Date {
        metrics?.responseInterval.start ?? logStartTime
    }
    
    package var finishTime: Date? {
        metrics?.responseInterval.end ?? logFinishTime
    }
    
    package var responseTime: TimeInterval {
        metrics?.responseInterval.duration ?? logInterval
    }
    
    package var isMocked: Bool { mockId != nil }

    package var statusCategory: String {
        switch statusCode {
        case 100..<200: return "Informational"
        case 200..<300: return "Success"
        case 300..<400: return "Redirection"
        case 400..<500: return "Client Error"
        case 500..<600: return "Server Error"
        default: return "NA"
        }
    }
    
    package var statusCodeRange: String {
        switch statusCode {
        case 100..<200: return "100..<200"
        case 200..<300: return "200..<300"
        case 300..<400: return "300..<400"
        case 400..<500: return "400..<500"
        case 500..<600: return "500..<600"
        default: return "NA"
        }
    }

    package var isError: Bool { (400..<600).contains(statusCode) || errorDescription != nil }

    // MARK: - Initializer
    package init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        url: String,
        method: String = "",
        headers: [String: String] = [:],
        requestBodyRaw: Data? = nil,
        statusCode: Int = 0,
        responseHeaders: [String: String] = [:],
        mimetype: String? = nil,
        textEncodingName: String? = nil,
        responseRaw: Data? = nil,
        errorDescription: String? = nil,
        errorLocalizedDescription: String? = nil,
        finishTime: Date? = nil,
        responseTime: TimeInterval = 0,
        isLoading: Bool = true,
        mockId: UUID? = nil,
        metrics: NetworkLogMetrics? = nil
    ) {
        self.id = id
        self.logStartTime = startTime
        self.url = url
        self.method = method
        self.headers = headers
        self.requestBodyRaw = requestBodyRaw
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.mimetype = mimetype
        self.textEncodingName = textEncodingName
        self.responseRaw = responseRaw
        self.errorDescription = errorDescription
        self.errorLocalizedDescription = errorLocalizedDescription
        self.logFinishTime = finishTime
        self.logInterval = responseTime
        self.isLoading = isLoading
        self.mockId = mockId
        self.metrics = metrics
    }
}

// MARK: - Convinience Object Factory Methods.
package extension LogItem {
    /// Create a LogItem initialized with request information.
    init(_ request: URLRequest, _ mockId: UUID? = nil) {
        let urlString = request.url?.absoluteString ?? ""
        let method = request.httpMethod ?? ""
        let headers = request.allHTTPHeaderFields ?? [:]
        let body = request.httpBody
        self.init(url: urlString, method: method, headers: headers, requestBodyRaw: body, mockId: mockId)
    }
    
    /// Update log item if the mock ID if the request was mocked.
    mutating func updateMockID(_ mockId: UUID? = nil) {
        self.mockId = mockId
    }

    /// Attaches response information to this log item.
    mutating func updateResponse(response: URLResponse?, data: Data?, error: Error?) {
        let finish = Date()
        var responseStatusCode = 0
        var headers = [String: String]()
        var responseMimetype: String?
        var responseTextEncodingName: String?

        if let http = response as? HTTPURLResponse {
            responseStatusCode = http.statusCode
            headers = http.allHeaderFields.reduce(into: [String: String]()) { partial, pair in
                let key = String(describing: pair.key)
                let value = String(describing: pair.value)
                partial[key] = value
            }
            responseMimetype = http.mimeType
            responseTextEncodingName = http.textEncodingName
        }

        statusCode = responseStatusCode
        responseHeaders = headers
        mimetype = responseMimetype
        textEncodingName = responseTextEncodingName
        responseRaw = data
        errorDescription = error.map { String(describing: $0) }
        errorLocalizedDescription = (error as? NSError).flatMap { $0.localizedDescription }
        logFinishTime = finish
        logInterval = finish.timeIntervalSince(logStartTime)
        isLoading = false
    }
    
    /// Attaches URL session task metrics to this log item.
    mutating func updateMetrics(_ metrics: NetworkLogMetrics) {
        self.metrics = metrics
    }
}

// MARK: - Pretty Printing Helpers
private extension LogItem {
    static func prettyPrintedHeaders(_ headers: [AnyHashable: Any]) -> String {
        // Convert header values to strings
        let mapped = headers.reduce(into: "") { partial, pair in
            let key = String(describing: pair.key)
            let value = String(describing: pair.value)
            partial += "\(key):\(value)\n"
        }
        return mapped
    }

    static func prettyPrintedBody(_ data: Data?) -> String {
        guard let data = data, !data.isEmpty else { return "" }
        // Try JSON first
        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .withoutEscapingSlashes]),
           let pretty = String(data: jsonData, encoding: .utf8) {
            return pretty
        }
        // Fallback to UTF-8 text
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        // Last resort, return the description.
        return data.description
    }
}
