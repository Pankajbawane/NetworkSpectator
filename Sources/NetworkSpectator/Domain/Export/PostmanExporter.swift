//
//  PostmanExporter.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 11/07/25.
//

import Foundation

// Build and export Postman Collection using schema: https://schema.postman.com/json/collection/v2.1.0/collection.json
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
        let collectionItemDict: [String: Any] = [
            "name": generateItemName(method: item.method, path: urlComponents.path),
            "request": requestDict
        ]

        // 6. Add response example if available

        let collectionItem: [[String: Any]] = [collectionItemDict]

        // 7. Build collection JSON
        let collection: [String: Any] = [
            "info": [
                "name": "Exported from NetworkSpectator",
                "schema": "https://schema.postman.com/json/collection/v2.1.0/collection.json"
            ],
            "item": collectionItem
        ]

        // 8. Serialize to JSON
        return try JSONSerialization.data(withJSONObject: collection, options: [.prettyPrinted, .withoutEscapingSlashes])
    }

    // MARK: - Helpers

    private func parseHeaders(from headers: [String: String]) -> [[String: String]] {
        guard !headers.isEmpty else { return [] }
        
        return headers.map { header -> [String: String] in
                return ["key": header.key, "value": header.value]
            }
    }

    private func detectBodyMode(from body: String, headers: [String: String]) -> String {
        let contentTypeHeader = headers.first(where: { $0.key.lowercased() == "content-type" })?.value ?? ""

        if contentTypeHeader.contains("application/json") {
            return "json"
        } else if contentTypeHeader.contains("application/x-www-form-urlencoded") {
            return "urlencoded"
        } else if contentTypeHeader.contains("application/xml") {
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
        let cleanPath = path.isEmpty ? "/" : path.prefix(15)
        return "NetworkSpectator - \(method.uppercased()) \(cleanPath)"
    }
}
