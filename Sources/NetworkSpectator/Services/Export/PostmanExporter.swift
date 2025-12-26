//
//  PostmanExporter.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 11/07/25.
//

import Foundation

struct PostmanExporter: FileExportable {

    let item: LogItem
    let fileExtension: String = "json"
    var filePrefix: String {
        item.host
    }

    func export() async throws -> URL {
        let data = try exportToPostmanCollection()
        return try await save(content: data)
    }

    func exportToPostmanCollection() throws -> Data {

        guard let urlComponents = URLComponents(string: item.url),
              let host = urlComponents.host else {
            throw ExportError.invalidData
        }

        // 1. Convert host and path for Postman URL format
        let pathComponents = urlComponents.path
            .split(separator: "/")
            .map(String.init)

        let urlDict: [String: Any] = [
            "raw": item.url,
            "protocol": urlComponents.scheme ?? "https",
            "host": host.components(separatedBy: "."),
            "path": pathComponents.isEmpty ? [] : pathComponents,
            "query": urlComponents.queryItems?.map {
                ["key": $0.name, "value": $0.value ?? ""]
            } ?? []
        ]

        // 2. Parse headers from "key:value" format into Postman format
        let requestHeaders = parseHeaders(from: item.headers)

        // 3. Build request dictionary
        var requestDict: [String: Any] = [
            "method": item.method.uppercased(),
            "header": requestHeaders,
            "url": urlDict
        ]

        // 4. Add body if applicable
        if !item.requestBody.isEmpty {
            let bodyMode = detectBodyMode(from: item.requestBody, headers: item.headers)
            requestDict["body"] = createBodyDict(content: item.requestBody, mode: bodyMode)
        }

        // 5. Create item (one API request) with response data
        var collectionItemDict: [String: Any] = [
            "name": generateItemName(method: item.method, path: urlComponents.path),
            "request": requestDict
        ]

        // 6. Add response example if available

        let collectionItem: [[String: Any]] = [collectionItemDict]

        // 7. Build collection JSON
        let collection: [String: Any] = [
            "info": [
                "name": "Exported Network Logs",
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
            ],
            "item": collectionItem
        ]

        // 8. Serialize to JSON
        return try JSONSerialization.data(withJSONObject: collection, options: [.prettyPrinted])
    }

    // MARK: - Private Helpers

    private func parseHeaders(from headersString: String) -> [[String: String]] {
        guard !headersString.isEmpty else { return [] }

        return headersString
            .split(separator: "\n")
            .compactMap { line -> [String: String]? in
                let parts = line.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { return nil }

                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)

                return ["key": key, "value": value]
            }
    }

    private func detectBodyMode(from body: String, headers: String) -> String {
        let lowercasedHeaders = headers.lowercased()

        if lowercasedHeaders.contains("content-type:application/json") ||
           lowercasedHeaders.contains("content-type: application/json") {
            return "json"
        } else if lowercasedHeaders.contains("content-type:application/x-www-form-urlencoded") ||
                  lowercasedHeaders.contains("content-type: application/x-www-form-urlencoded") {
            return "urlencoded"
        } else if lowercasedHeaders.contains("content-type:application/xml") ||
                  lowercasedHeaders.contains("content-type: application/xml") {
            return "xml"
        }

        return "raw"
    }

    private func createBodyDict(content: String, mode: String) -> [String: Any] {
        var bodyDict: [String: Any] = [
            "mode": mode,
            mode: content
        ]

        if mode == "json" || mode == "raw" {
            bodyDict["options"] = [
                mode: ["language": mode == "json" ? "json" : "text"]
            ]
        }

        return bodyDict
    }

    private func generateItemName(method: String, path: String) -> String {
        let cleanPath = path.isEmpty ? "/" : path
        return "\(method.uppercased()) \(cleanPath)"
    }

    private func createResponseExample() -> [String: Any]? {
        guard item.statusCode > 0 else { return nil }

        let responseHeaders = parseHeaders(from: item.responseHeaders)

        var responseDict: [String: Any] = [
            "name": "Example Response",
            "originalRequest": [:],
            "status": "Status \(item.statusCode)",
            "code": item.statusCode,
            "header": responseHeaders
        ]

        if !item.responseBody.isEmpty {
            responseDict["body"] = item.responseBody
        }

        return responseDict
    }
}
