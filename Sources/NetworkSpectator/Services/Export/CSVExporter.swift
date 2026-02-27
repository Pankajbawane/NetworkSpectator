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
        "Start time", "End time", "Response Time", "Mime Type", "Text Encoding",
        "Request Headers", "Response Headers", "Request Payload", "Response",
        "Error Description", "Error Localized Description"
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
        return try await save(content: csv)
    }

    private func generateCSV() -> String {
        // Build CSV header with proper escaping
        let header = headerItems.map { escapeCSV($0) }.joined(separator: ",") + "\n"

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
            let errorDesc = escapeCSV(request.errorDescription ?? "")
            let errorLocalizedDesc = escapeCSV(request.errorLocalizedDescription ?? "")

            let row = [
                method, statusCode, url,
                startTime, endTime, duration, mimeType,
                encoding, requestHeaders, responseHeaders,
                requestPayload, response, errorDesc, errorLocalizedDesc
            ].joined(separator: ",")

            rows.append(row)
        }

        return rows.joined(separator: "\n")
    }

    private func escapeCSV(_ value: String) -> String {
        var escaped = value.replacingOccurrences(of: "\"", with: "\"\"")

        // Wrap in quotes if contains: comma, quote, newline, or carriage return
        if escaped.contains(",") || escaped.contains("\"") ||
           escaped.contains("\n") || escaped.contains("\r") {
            escaped = "\"\(escaped)\""
        }

        return escaped
    }
}
