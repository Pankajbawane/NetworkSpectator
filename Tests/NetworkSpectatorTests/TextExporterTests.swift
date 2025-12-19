import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - Text Exporter Tests
@Suite("Text Exporter Tests")
struct TextExporterTests {

    @Test("Text export format")
    func testTextExportFormat() async throws {
        let item = LogItem(
            url: "https://example.com/api/users",
            method: "GET",
            headers: "Content-Type: application/json",
            statusCode: 200,
            responseBody: #"{"users": []}"#,
            responseHeaders: "Content-Length: 100"
        )
        let exporter = TextExporter(item: item)

        let url = try await exporter.export()
        let content = try String(contentsOf: url, encoding: .utf8)

        #expect(content.contains("URL"))
        #expect(content.contains("https://example.com/api/users"))
        #expect(content.contains("Method"))
        #expect(content.contains("GET"))
        #expect(content.contains("Status Code"))
        #expect(content.contains("200"))
        #expect(content.contains("Headers"))
        #expect(content.contains("Response"))
    }

    @Test("Text export file extension")
    func testTextExportFileExtension() async throws {
        let item = LogItem(url: "https://example.com/api")
        let exporter = TextExporter(item: item)

        #expect(exporter.fileExtension == "txt")
    }
}
