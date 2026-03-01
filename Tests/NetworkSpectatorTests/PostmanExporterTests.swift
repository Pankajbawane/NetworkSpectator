//
//  PostmanExporterTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - Postman Exporter Tests
@Suite("Postman Exporter Tests")
struct PostmanExporterTests {

    @Test("Postman export structure")
    func testPostmanExportStructure() async throws {
        let item = LogItem(
            url: "https://api.example.com/v1/users?page=1",
            method: "GET",
            headers: ["Content-Type": "application/json"],
            statusCode: 200
        )
        let exporter = PostmanExporter(item: item)

        let data = try exporter.exportToPostmanCollection()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)

        // Verify info section
        let info = json?["info"] as? [String: Any]
        #expect(info?["name"] as? String == "Exported Network Logs")
        #expect((info?["schema"] as? String)?.contains("postman.com") == true)

        // Verify item section
        let items = json?["item"] as? [[String: Any]]
        #expect(items?.count == 1)
    }

    @Test("Postman export URL components")
    func testPostmanExportURLComponents() async throws {
        let item = LogItem(
            url: "https://api.example.com/v1/users?page=1&limit=10",
            method: "POST"
        )
        let exporter = PostmanExporter(item: item)

        let data = try exporter.exportToPostmanCollection()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["item"] as? [[String: Any]]
        let request = items?.first?["request"] as? [String: Any]
        let url = request?["url"] as? [String: Any]

        #expect(url?["protocol"] as? String == "https")

        let host = url?["host"] as? [String]
        #expect(host == ["api", "example", "com"])

        let path = url?["path"] as? [String]
        #expect(path?.contains("v1") == true)
        #expect(path?.contains("users") == true)

        let query = url?["query"] as? [[String: String]]
        #expect(query?.contains(where: { $0["key"] == "page" && $0["value"] == "1" }) == true)
    }

    @Test("Postman export with request body")
    func testPostmanExportWithBody() async throws {
        let item = LogItem(
            url: "https://api.example.com/users",
            method: "POST",
            requestBody: #"{"name": "John Doe"}"#
        )
        let exporter = PostmanExporter(item: item)

        let data = try exporter.exportToPostmanCollection()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["item"] as? [[String: Any]]
        let request = items?.first?["request"] as? [String: Any]
        let body = request?["body"] as? [String: Any]

        #expect(body?["mode"] as? String == "raw")
        #expect((body?["raw"] as? String)?.contains("John Doe") == true)
    }

    @Test("Postman export file extension")
    func testPostmanExportFileExtension() async throws {
        let item = LogItem(url: "https://example.com")
        let exporter = PostmanExporter(item: item)

        #expect(exporter.fileExtension == "json")
    }
}
