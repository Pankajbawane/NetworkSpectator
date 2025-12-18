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
              let host = urlComponents.host else { throw ExportError.invalidData }
        
        // 1. Convert host and path for Postman URL format
        let urlDict: [String: Any] = [
            "raw": item.url,
            "protocol": urlComponents.scheme ?? "https",
            "host": host.components(separatedBy: "."),
            "path": urlComponents.path
                .split(separator: "/")
                .map(String.init),
            "query": urlComponents.queryItems?.map {
                ["key": $0.name, "value": $0.value ?? ""]
            } ?? []
        ]
        
        // 2. Convert headers dictionary into Postman format
        var headers: [[String: String]] = []
        if let headersData = item.headers.data(using: .utf8),
           let headersDict = try? JSONDecoder().decode([String: String].self, from: headersData) {
            headers = headersDict.map {
                ["key": $0.key, "value": $0.value]
            }
        }
        
        // 3. Build request dictionary
        var requestDict: [String: Any] = [
            "method": item.method.uppercased(),
            "header": headers,
            "url": urlDict
        ]
        
        // 4. Add body if applicable
        if !item.requestBody.isEmpty {
            requestDict["body"] = [
                "mode": "raw",
                "raw": item.requestBody,
                "options": [
                    "raw": ["language": "json"] // You can adjust this if needed
                ]
            ]
        }
        
        // 5. Create item (one API request)
        let collectionItem: [[String: Any]] = [
            [
                "name": "\(item.method.uppercased()) \(urlComponents.path)",
                "request": requestDict
            ]
        ]
        
        // 6. Build collection JSON
        let collection: [String: Any] = [
            "info": [
                "name": "Exported Network Logs",
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
            ],
            "item": collectionItem
        ]
        
        // 7. Serialize to JSON and write to disk
        return try JSONSerialization.data(withJSONObject: collection, options: [.prettyPrinted])
    }
}
