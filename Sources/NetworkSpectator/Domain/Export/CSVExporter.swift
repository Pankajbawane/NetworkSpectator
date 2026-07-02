//
//  CSVExporter.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 11/07/25.
//

import Foundation

struct CSVExporter: FileExportable {
    let headerItems: [String] = [
        "HTTP Method", "Status Code", "URL",
        "Start time", "End time", "Response Time",
        "Mime Type", "Text Encoding", "Request Headers",
        "Response Headers", "Request Payload", "Response",
        "Error"
    ]
    let items: [LogItem]
    let fileExtension: String = "csv"
    var filePrefix: String {
        if items.count == 1, let name = items.first?.host {
            return "log_csv_\(name)"
        } else {
            return "log_csv_list"
        }
    }

    func export() async throws -> URL {
        let csv = generateCSV()
        // Prepend UTF-8 BOM so MS Excel correctly interprets the encoding
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(csv.utf8))
        return try await save(content: data)
    }

    private func generateCSV() -> String {
        // Build CSV header with proper escaping
        let header = headerItems.map { escapeCSV($0) }.joined(separator: ",")

        // Pre-allocate array for better performance
        var rows: [String] = [header]
        rows.reserveCapacity(items.count + 1)

        for request in items {
            let method = escapeCSV(request.method)
            let statusCode = request.statusCode == 0 ? "" : "\(request.statusCode)"
            let url = escapeCSV(request.url)
            let requestHeaders = escapeCSV(request.requestHeadersPrettyPrinted)
            let responseHeaders = escapeCSV(request.responseHeadersPrettyPrinted)
            let requestPayload = escapeCSV(request.requestBody)
            let startTime = escapeCSV(request.startTime.formatted(date: .abbreviated, time: .complete))
            let endTime = escapeCSV(request.finishTime?.formatted(date: .abbreviated, time: .complete) ?? "")
            let duration = request.responseTime == 0 ? "" : "\(request.responseTime)"
            let mimeType = escapeCSV(request.mimetype ?? "")
            let encoding = escapeCSV(request.textEncodingName ?? "")
            let response = escapeCSV(request.responseBody)
            let errorLocalizedDesc = escapeCSV(request.errorLocalizedDescription ?? "")

            let row = [
                method, statusCode, url,
                startTime, endTime, duration, mimeType,
                encoding, requestHeaders, responseHeaders,
                requestPayload, response, errorLocalizedDesc
            ].joined(separator: ",")

            rows.append(row)
        }

        // Use CRLF line endings for MS Excel compatibility
        let crlf = "\r\n"
        return rows.joined(separator: crlf)
    }

    private func escapeCSV(_ value: String) -> String {
        // Normalize any \r or \r\n to plain \n so embedded newlines are consistent.
        // Row endings use \r\n (CRLF), so plain \n inside a quoted field is unambiguous.
        let normalized = value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var escaped = normalized.replacingOccurrences(of: "\"", with: "\"\"")

        // Wrap in quotes if contains: comma, quote, or newline
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            escaped = "\"\(escaped)\""
        }

        return escaped
    }
}
