import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - CSV Exporter Tests
@Suite("CSV Exporter Tests")
struct CSVExporterTests {

    @Test("CSV export with single item")
    func testCSVExportSingleItem() async throws {
        let item = LogItem(
            url: "https://example.com/api/users",
            method: "GET",
            statusCode: 200,
            responseBody: "test response"
        )
        let exporter = CSVExporter(items: [item])

        let url = try await exporter.export()
        let content = try String(contentsOf: url, encoding: .utf8)

        #expect(content.contains("HTTP Method"))
        #expect(content.contains("Status Code"))
        #expect(content.contains("URL"))
        #expect(content.contains("GET"))
        #expect(content.contains("200"))
        #expect(content.contains("example.com"))
    }

    @Test("CSV export with multiple items")
    func testCSVExportMultipleItems() async throws {
        let items = [
            LogItem(url: "https://example.com/api/users", method: "GET", statusCode: 200),
            LogItem(url: "https://example.com/api/posts", method: "POST", statusCode: 201),
            LogItem(url: "https://example.com/api/data", method: "DELETE", statusCode: 204)
        ]
        let exporter = CSVExporter(items: items)

        let url = try await exporter.export()
        let content = try String(contentsOf: url, encoding: .utf8)

        let lines = content.components(separatedBy: "\n")
        #expect(lines.count >= 4) // Header + 3 items + possible trailing newline
    }

    @Test("CSV export escapes special characters")
    func testCSVExportEscaping() async throws {
        let item = LogItem(
            url: "https://example.com/api/test",
            method: "POST",
            headers: "Content-Type: application/json\nAuthorization: Bearer token",
            statusCode: 200,
            responseBody: #"{"name": "John, Doe", "quote": "He said \"hello\""}"#
        )
        let exporter = CSVExporter(items: [item])

        let url = try await exporter.export()
        let content = try String(contentsOf: url, encoding: .utf8)

        // Should have quoted fields with commas and quotes
        #expect(content.contains("\""))
    }
}
