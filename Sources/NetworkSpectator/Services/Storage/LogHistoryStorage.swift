//
//  LogHistoryStorage.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 03/03/26.
//

import Foundation

/// Protocol for file system operations, enabling testability.
protocol FileStoreable: Sendable {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws
    func write(_ data: Data, to url: URL) throws
    func contentsOfFile(at url: URL) throws -> Data
    func removeItem(at url: URL) throws
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options: FileManager.DirectoryEnumerationOptions) throws -> [URL]
}

extension FileManager: FileStoreable {
    func write(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }

    func contentsOfFile(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
}

/// File-based key-value storage for log history.
/// Each key (timestamp range string) maps to a separate JSON file containing an array of LogItems.
struct LogHistoryStorage {

    private let fileManager: FileStoreable
    private let baseURL: URL

    init(fileManager: FileStoreable = FileManager.default) {
        self.fileManager = fileManager
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.baseURL = appSupport.appendingPathComponent("NetworkSpectator").appendingPathComponent("LogHistory")
        ensureDirectoryExists()
    }

    /// Initializer for testing with a custom base URL.
    init(fileManager: FileStoreable, baseURL: URL) {
        self.fileManager = fileManager
        self.baseURL = baseURL
        ensureDirectoryExists()
    }

    // MARK: - Save and retrieve.

    /// Saves pre-encoded data for the given key. Avoids double encoding when the caller
    /// has already serialized the items (e.g. to compute byte size).
    func save(_ data: Data, forKey key: String) {
        do {
            let fileURL = url(forKey: key)
            try fileManager.write(data, to: fileURL)
        } catch {
            DebugPrint.log("NETWORK SPECTATOR: Failed to save for key '\(key)': \(error)")
        }
    }

    /// Saves an array of log items for the given key.
    func save(_ items: [LogItem], forKey key: String) {
        do {
            let logData = try JSONEncoder().encode(items)
            save(logData, forKey: key)
        } catch {
            DebugPrint.log("NETWORK SPECTATOR: Failed to encode for key '\(key)': \(error)")
        }
    }

    /// Retrieves log items for the given key. Returns an empty array if the key doesn't exist.
    func retrieve(forKey key: String) -> [LogItem] {
        let fileURL = url(forKey: key)
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try fileManager.contentsOfFile(at: fileURL)
            return try JSONDecoder().decode([LogItem].self, from: data)
        } catch {
            DebugPrint.log("NETWORK SPECTATOR: Failed to retrieve for key '\(key)': \(error)")
            return []
        }
    }

    /// Deletes the log history entry for the given key.
    func delete(forKey key: String) {
        let fileURL = url(forKey: key)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            DebugPrint.log("NETWORK SPECTATOR: Failed to delete for key '\(key)': \(error)")
        }
    }

    /// Returns all stored keys (timestamp range strings).
    func listKeys() -> [HistoryItem] {
        do {
            let contents = try fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)
            return contents
                .filter { $0.pathExtension == "json" }
                .compactMap { url in
                    if let key = decodedKey(from: url.deletingPathExtension().lastPathComponent) {
                        let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
                        let params = key.split(separator: "|").map { String($0) }
                        var startTimestamp = key
                        var endTimestamp = ""
                        var count = ""
                        if params.count >= 3 {
                            startTimestamp = params[0]
                            endTimestamp = params[1]
                            count = params[2]
                        }
                        return HistoryItem(key: key,
                                           url: url,
                                           startTimestamp: startTimestamp,
                                           endTimestamp: endTimestamp,
                                           count: count,
                                           size: size ?? 0)
                    }
                    return nil
                }
                .sorted(by: { $0.key > $1.key })
        } catch {
            DebugPrint.log("NETWORK SPECTATOR: Failed to list keys: \(error)")
            return []
        }
    }

    /// Deletes all stored log history entries.
    func clearAll() {
        for key in listKeys() {
            delete(forKey: key.key)
        }
    }

    // MARK: - Helpers

    private func url(forKey key: String) -> URL {
        let safeFilename = encodedFilename(for: key)
        return baseURL.appendingPathComponent(safeFilename).appendingPathExtension("json")
    }

    /// Encodes a key into a filesystem-safe filename using Base64.
    private func encodedFilename(for key: String) -> String {
        Data(key.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Decodes a filename back to the original key.
    private func decodedKey(from filename: String) -> String? {
        var base64 = filename
            .replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+")
        // Re-add padding
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: baseURL.path) {
            do {
                try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                DebugPrint.log("NETWORK SPECTATOR: Failed to create directory: \(error)")
            }
        }
    }
}
