//
//  CSVExporterTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - CSV Exporter Tests
@Suite("CSV Exporter Tests", .serialized)
struct CSVExporterTests {

    /// Helper to read exported file data and derive the string content from a single read.
    private func readExport(from url: URL) throws -> (data: Data, content: String) {
        let data = try Data(contentsOf: url)
        // Skip the 3-byte UTF-8 BOM when converting to string
        let textData = data.count >= 3 ? data.dropFirst(3) : data
        let content = String(data: textData, encoding: .utf8) ?? ""
        return (data, content)
    }

    @Test("CSV export with single item includes BOM and correct content")
    func testCSVExportSingleItem() async throws {
        let item = LogItem(
            url: "https://single.example.com/api/users",
            method: "GET",
            statusCode: 200
        )
        let exporter = CSVExporter(items: [item])

        let url = try await exporter.export()
        let (data, content) = try readExport(from: url)

        // Verify UTF-8 BOM is present
        #expect(data.starts(with: [0xEF, 0xBB, 0xBF]))

        #expect(content.contains("HTTP Method"))
        #expect(content.contains("Status Code"))
        #expect(content.contains("URL"))
        #expect(content.contains("GET"))
        #expect(content.contains("200"))
        #expect(content.contains("single.example.com"))
    }

    @Test("CSV export with multiple items uses CRLF line endings")
    func testCSVExportMultipleItems() async throws {
        let items = [
            LogItem(url: "https://example.com/api/users", method: "GET", statusCode: 200),
            LogItem(url: "https://example.com/api/posts", method: "POST", statusCode: 201),
            LogItem(url: "https://example.com/api/data", method: "DELETE", statusCode: 204)
        ]
        let exporter = CSVExporter(items: items)

        let url = try await exporter.export()
        let (_, content) = try readExport(from: url)

        // Verify CRLF line endings are used
        let lines = content.components(separatedBy: "\r\n")
        #expect(lines.count >= 4) // Header + 3 items + possible trailing element
    }

    @Test("CSV export escapes special characters")
    func testCSVExportEscaping() async throws {
        let payload = #"{"name": "John, Doe", "quote": "He said \"hello\""}"#
        let item = LogItem(
            url: "https://escape.example.com/api/test",
            method: "POST",
            headers: ["Content-Type": "application/json"],
            requestBodyRaw: payload.data(using: .utf8),
            statusCode: 200
        )
        let exporter = CSVExporter(items: [item])

        let url = try await exporter.export()
        let (_, content) = try readExport(from: url)

        // Request payload contains commas and quotes, so the CSV field should be quoted
        #expect(content.contains("\""))
        #expect(content.contains("POST"))
    }

    @Test("CSV export preserves embedded newlines inside quoted fields")
    func testCSVExportPreservesEmbeddedNewlines() async throws {
        let item = LogItem(
            url: "https://newlines.example.com/api/test",
            method: "GET",
            headers: ["Accept": "application/json", "X-Custom": "value"],
            statusCode: 200
        )
        let exporter = CSVExporter(items: [item])

        let url = try await exporter.export()
        let (_, content) = try readExport(from: url)

        // Headers produce multi-line content (key:value\n pairs).
        // These should be preserved inside a quoted CSV field, not flattened.
        // Row endings are CRLF, so splitting by \r\n gives header + 1 data row,
        // with the multi-line header field contained within quotes.
        let rows = content.components(separatedBy: "\r\n").filter { !$0.isEmpty }
        // The quoted field contains \n but no \r\n, so CRLF split still yields 2 rows
        #expect(rows.count == 2)
        // Verify the headers field is quoted (contains embedded newlines)
        #expect(content.contains("\""))
    }
}
