//
//  CSVExporter.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 11/07/25.
//

import Foundation

struct CSVExporter: FileExportable {
    let headerItems: [String] = [
        "HTTP Method", "Status Code", "URL", "Request Headers", "Response Headers",
        "Start time", "End time", "Response Duration", "Mime Type", "Text Encoding"
    ]
    let items: [LogItem]
    let fileExtension: String = "csv"
    
    func export() async throws -> URL {
        let csv = await generateCSV()
        return await try save(content: csv)
    }

    private func generateCSV() async -> String {
        var csv = headerItems.joined(separator: ",") + "\n"

        for request in items {
            let method = escapeCSV(request.method)
            let statusCode = "\(request.statusCode)"
            let url = escapeCSV(request.url)
            let requestHeaders = escapeCSV(request.headers)
            let responseHeaders = escapeCSV(request.responseHeaders)
            let requestPayload = escapeCSV(request.requestBody)
            let startTime = escapeCSV(request.startTime.formatted(date: .abbreviated, time: .complete))
            let endTime = escapeCSV(request.finishTime?.formatted(date: .abbreviated, time: .complete) ?? "")
            let duration = "\(request.responseTime)"
            let mimeType = escapeCSV(request.mimetype ?? "")
            let encoding = escapeCSV(request.textEncodingName ?? "")
            let response = escapeCSV(request.responseBody)

            let row = [
                method, statusCode, url,
                startTime, endTime, duration, mimeType,
                encoding, requestHeaders, responseHeaders,
                requestPayload, response
            ].joined(separator: ",") + "\n"

            csv += row
        }

        return csv
    }

    private func escapeCSV(_ value: String) -> String {
        var escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }
}
