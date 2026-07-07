//
//  ExportManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 11/07/25.
//

import Foundation
import NetworkSpectatorCore

package enum ExportManager {
    
    case csv([LogItem])
    case txt(LogItem)
    case postman(LogItem)
    
    package var exporter: FileExportable {
        switch self {
        case .csv(let items):
            return CSVExporter(items: items)
        case .txt(let item):
            return TextExporter(item: item)
        case .postman(let item):
            return PostmanExporter(item: item)
        }
    }
}

package protocol FileExportable: Sendable {
    var fileExtension: String { get }
    var filePrefix: String { get }
    func export() async throws -> URL
}

package extension FileExportable {
    // Use a safe and unique filename
    var makeFilename: String {
        let prefix: String = "export_" + filePrefix
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let date = formatter.string(from: Date())
        return "\(prefix)_\(date).\(fileExtension)"
    }
    
    func save(content: some StringProtocol) async throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(makeFilename)
        do {
            try String(content).write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            DebugConsoleLogger.log("FileExportable failed to write text file: \(fileURL.lastPathComponent), error: \(error)")
            throw ExportError.writeFailed
        }
    }

    func save(content: Data) async throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(makeFilename)
        do {
            try content.write(to: fileURL)
            return fileURL
        } catch {
            DebugConsoleLogger.log("FileExportable failed to write data file: \(fileURL.lastPathComponent), error: \(error)")
            throw ExportError.writeFailed
        }
    }
}

package enum ExportError: Error {
    case writeFailed
    case invalidData
}
