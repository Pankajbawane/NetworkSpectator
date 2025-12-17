//
//  LogItem.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import Foundation

// MARK: - LogItem
// Represents a single network log entry.
struct LogItem: Identifiable, Codable, Equatable, Sendable, Hashable {
    // Identity & timing
    let id: UUID
    let startTime: Date
    let url: String

    // Request
    let method: String
    let headers: String
    let requestBody: String

    // Response
    let statusCode: Int
    let responseBody: String
    let responseHeaders: String
    let mimetype: String?
    let textEncodingName: String?

    // Error & state
    let errorDescription: String?
    let errorLocalizedDescription: String?
    let finishTime: Date?
    let responseTime: TimeInterval
    let isLoading: Bool

    // MARK: - Derived
    var host: String {
        URLComponents(string: url)?.host ?? url
    }

    var path: String {
        URLComponents(string: url)?.percentEncodedPath ?? ""
    }

    var scheme: String? {
        URLComponents(string: url)?.scheme
    }

    var statusCategory: String {
        switch statusCode {
        case 100..<200: return "Informational"
        case 200..<300: return "Success"
        case 300..<400: return "Redirection"
        case 400..<500: return "Client Error"
        case 500..<600: return "Server Error"
        default: return statusCode == 0 ? "Unknown" : "Other"
        }
    }

    var isError: Bool { (400..<600).contains(statusCode) || errorDescription != nil }

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        url: String,
        method: String = "",
        headers: String = "",
        requestBody: String = "",
        statusCode: Int = 0,
        responseBody: String = "",
        responseHeaders: String = "",
        mimetype: String? = nil,
        textEncodingName: String? = nil,
        errorDescription: String? = nil,
        errorLocalizedDescription: String? = nil,
        finishTime: Date? = nil,
        responseTime: TimeInterval = 0,
        isLoading: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.url = url
        self.method = method
        self.headers = headers
        self.requestBody = requestBody
        self.statusCode = statusCode
        self.responseBody = responseBody
        self.responseHeaders = responseHeaders
        self.mimetype = mimetype
        self.textEncodingName = textEncodingName
        self.errorDescription = errorDescription
        self.errorLocalizedDescription = errorLocalizedDescription
        self.finishTime = finishTime
        self.responseTime = responseTime
        self.isLoading = isLoading
    }
}

// MARK: - Convinience Object Factory Methods.
extension LogItem {
    /// Create a LogItem initialized with request information.
    static func fromRequest(_ request: URLRequest) -> LogItem {
        let urlString = request.url?.absoluteString ?? ""
        let method = request.httpMethod ?? ""
        let headers = request.allHTTPHeaderFields.flatMap { prettyPrintedHeaders($0) } ?? ""
        let body = prettyPrintedBody(request.httpBody)
        return LogItem(url: urlString, method: method, headers: headers, requestBody: body)
    }

    /// Returns a new LogItem by attaching response information to an existing request LogItem.
    func withResponse(response: URLResponse?, data: Data?, error: Error?) -> LogItem {
        let finish = Date()
        var statusCode = 0
        var responseHeaders = ""
        var mimetype: String?
        var textEncodingName: String?

        if let http = response as? HTTPURLResponse {
            statusCode = http.statusCode
            responseHeaders = Self.prettyPrintedHeaders(http.allHeaderFields)
            mimetype = http.mimeType
            textEncodingName = http.textEncodingName
        }

        let responseBody = Self.prettyPrintedBody(data)
        let elapsed = finish.timeIntervalSince(startTime)

        return LogItem(
            id: id,
            startTime: startTime,
            url: url,
            method: method,
            headers: headers,
            requestBody: requestBody,
            statusCode: statusCode,
            responseBody: responseBody,
            responseHeaders: responseHeaders,
            mimetype: mimetype,
            textEncodingName: textEncodingName,
            errorDescription: error.map { String(describing: $0) },
            errorLocalizedDescription: (error as? NSError).flatMap { $0.localizedDescription },
            finishTime: finish,
            responseTime: elapsed,
            isLoading: false
        )
    }
}

// MARK: - Pretty Printing Helpers
private extension LogItem {
    static func prettyPrintedHeaders(_ headers: [AnyHashable: Any]) -> String {
        // Convert header values to strings and sort keys for stable output
        let mapped = headers.reduce(into: [String: String]()) { partial, pair in
            let key = String(describing: pair.key)
            let value = String(describing: pair.value)
            partial[key] = value
        }
        let sorted = mapped.keys.sorted()
        let lines = sorted.map { "\($0): \(mapped[$0] ?? "")" }
        return lines.joined(separator: "\n")
    }

    static func prettyPrintedBody(_ data: Data?) -> String {
        guard let data = data, !data.isEmpty else { return "" }
        // Try JSON first
        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
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
