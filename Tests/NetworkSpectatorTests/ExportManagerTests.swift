//
//  ExportManagerTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectator
@testable import NetworkSpectatorCore
@testable import NetworkSpectatorLogging
@testable import NetworkSpectatorUI

// MARK: - ExportManager Tests
@Suite("ExportManager Tests")
struct ExportManagerTests {

    // MARK: - Helpers

    private func makeItem(
        url: String = "https://example.com/api",
        method: String = "GET",
        statusCode: Int = 200
    ) -> LogItem {
        LogItem(url: url, method: method, statusCode: statusCode)
    }

    // MARK: - Exporter Factory

    @Test("CSV case returns CSVExporter")
    func testCSVExporter() {
        let items = [makeItem()]
        let exporter = ExportManager.csv(items).exporter
        #expect(exporter is CSVExporter)
    }

    @Test("TXT case returns TextExporter")
    func testTXTExporter() {
        let item = makeItem()
        let exporter = ExportManager.txt(item).exporter
        #expect(exporter is TextExporter)
    }

    @Test("Postman case returns PostmanExporter")
    func testPostmanExporter() {
        let item = makeItem()
        let exporter = ExportManager.postman(item).exporter
        #expect(exporter is PostmanExporter)
    }

    // MARK: - FileExportable Filename

    @Test("CSV exporter has csv file extension")
    func testCSVFileExtension() {
        let exporter = CSVExporter(items: [makeItem()])
        #expect(exporter.fileExtension == "csv")
    }

    @Test("Text exporter has txt file extension")
    func testTxtFileExtension() {
        let exporter = TextExporter(item: makeItem())
        #expect(exporter.fileExtension == "txt")
    }

    @Test("makeFilename contains export prefix, file prefix, and extension")
    func testMakeFilename() {
        let exporter = CSVExporter(items: [makeItem()])
        let filename = exporter.makeFilename

        #expect(filename.hasPrefix("export_"))
        #expect(filename.hasSuffix(".csv"))
        #expect(filename.contains("log_csv_"))
    }

    // MARK: - CSV filePrefix

    @Test("CSV filePrefix uses host for single item")
    func testCSVFilePrefixSingleItem() {
        let exporter = CSVExporter(items: [makeItem(url: "https://example.com/api")])
        #expect(exporter.filePrefix == "log_csv_example.com")
    }

    @Test("CSV filePrefix uses list for multiple items")
    func testCSVFilePrefixMultipleItems() {
        let exporter = CSVExporter(items: [makeItem(), makeItem()])
        #expect(exporter.filePrefix == "log_csv_list")
    }

    @Test("CSV filePrefix uses list for empty items")
    func testCSVFilePrefixEmptyItems() {
        let exporter = CSVExporter(items: [])
        #expect(exporter.filePrefix == "log_csv_list")
    }

    // MARK: - Text filePrefix

    @Test("Text filePrefix returns host")
    func testTextFilePrefix() {
        let exporter = TextExporter(item: makeItem(url: "https://api.example.com/data"))
        #expect(exporter.filePrefix == "api.example.com")
    }

    // MARK: - Export writes file

    @Test("CSV export writes file to temp directory")
    func testCSVExportWritesFile() async throws {
        let item = makeItem()
        let exporter = CSVExporter(items: [item])
        let url = try await exporter.export()

        #expect(FileManager.default.fileExists(atPath: url.path))
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("HTTP Method"))
        #expect(content.contains("GET"))
        #expect(url.pathExtension == "csv")

        try? FileManager.default.removeItem(at: url)
    }

    @Test("Text export writes file to temp directory")
    func testTextExportWritesFile() async throws {
        let item = makeItem()
        let exporter = TextExporter(item: item)
        let url = try await exporter.export()

        #expect(FileManager.default.fileExists(atPath: url.path))
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("URL:"))
        #expect(content.contains("example.com"))
        #expect(url.pathExtension == "txt")

        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - ExportError

    @Test("ExportError cases exist")
    func testExportErrorCases() {
        let writeFailed = ExportError.writeFailed
        let invalidData = ExportError.invalidData
        #expect(writeFailed != invalidData)
    }
}
