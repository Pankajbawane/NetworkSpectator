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
    let headers: [String: String]
    let requestBody: String

    // Response
    let statusCode: Int
    let responseBody: String
    let responseHeaders: [String: String]
    let mimetype: String?
    let textEncodingName: String?

    // Raw response data (for binary content like images)
    let responseRaw: Data?

    // Error & state
    let errorDescription: String?
    let errorLocalizedDescription: String?
    let finishTime: Date?
    let responseTime: TimeInterval
    let isLoading: Bool
    
    // If request is mocked
    let mockId: UUID?

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
    
    var requestHeadersPrettyPrinted: String {
        Self.prettyPrintedHeaders(headers)
    }
    
    var responseHeadersPrettyPrinted: String {
        Self.prettyPrintedHeaders(responseHeaders)
    }
    
    var isMocked: Bool { mockId != nil }

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
    
    var statusCodeRange: String {
        switch statusCode {
        case 100..<200: return "100..<200"
        case 200..<300: return "200..<300"
        case 300..<400: return "300..<400"
        case 400..<500: return "400..<500"
        case 500..<600: return "500..<600"
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
        headers: [String: String] = [:],
        requestBody: String = "",
        statusCode: Int = 0,
        responseBody: String = "",
        responseHeaders: [String: String] = [:],
        mimetype: String? = nil,
        textEncodingName: String? = nil,
        responseRaw: Data? = nil,
        errorDescription: String? = nil,
        errorLocalizedDescription: String? = nil,
        finishTime: Date? = nil,
        responseTime: TimeInterval = 0,
        isLoading: Bool = true,
        mockId: UUID? = nil
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
        self.responseRaw = responseRaw
        self.errorDescription = errorDescription
        self.errorLocalizedDescription = errorLocalizedDescription
        self.finishTime = finishTime
        self.responseTime = responseTime
        self.isLoading = isLoading
        self.mockId = mockId
    }
}

// MARK: - Convinience Object Factory Methods.
extension LogItem {
    /// Create a LogItem initialized with request information.
    static func fromRequest(_ request: URLRequest, _ mockId: UUID? = nil) -> LogItem {
        let urlString = request.url?.absoluteString ?? ""
        let method = request.httpMethod ?? ""
        let headers = request.allHTTPHeaderFields ?? [:]
        let body = prettyPrintedBody(request.httpBody)
        return LogItem(url: urlString, method: method, headers: headers, requestBody: body, mockId: mockId)
    }

    /// Returns a new LogItem by attaching response information to an existing request LogItem.
    func withResponse(response: URLResponse?, data: Data?, error: Error?) -> LogItem {
        let finish = Date()
        var statusCode = 0
        var responseHeaders = [String: String]()
        var mimetype: String?
        var textEncodingName: String?

        if let http = response as? HTTPURLResponse {
            statusCode = http.statusCode
            responseHeaders = http.allHeaderFields.reduce(into: [String: String]()) { partial, pair in
                let key = String(describing: pair.key)
                let value = String(describing: pair.value)
                partial[key] = value
            }
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
            responseRaw: data,
            errorDescription: error.map { String(describing: $0) },
            errorLocalizedDescription: (error as? NSError).flatMap { $0.localizedDescription },
            finishTime: finish,
            responseTime: elapsed,
            isLoading: false,
            mockId: mockId
        )
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
