//
//  LogHistoryStorageTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 03/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

/// In-memory mock file system for testing LogHistoryStorage without touching disk.
final class MockFileStorage: FileStoreable, @unchecked Sendable {
    var files: [String: Data] = [:]
    var directories: Set<String> = []

    func fileExists(atPath path: String) -> Bool {
        files[path] != nil || directories.contains(path)
    }

    func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws {
        directories.insert(url.path)
    }

    func write(_ data: Data, to url: URL) throws {
        files[url.path] = data
    }

    func contentsOfFile(at url: URL) throws -> Data {
        guard let data = files[url.path] else {
            throw NSError(domain: "MockFileStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "File not found"])
        }
        return data
    }

    func removeItem(at url: URL) throws {
        files.removeValue(forKey: url.path)
    }

    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        let prefix = url.path.hasSuffix("/") ? url.path : url.path + "/"
        return files.keys
            .filter { $0.hasPrefix(prefix) }
            .map { URL(fileURLWithPath: $0) }
    }
}

// MARK: - LogHistoryStorage Tests
@Suite("LogHistoryStorage Tests")
struct LogHistoryStorageTests {

    private func makeStorage() -> (LogHistoryStorage, MockFileStorage) {
        let mockFS = MockFileStorage()
        let baseURL = URL(fileURLWithPath: "/tmp/test-log-history")
        let storage = LogHistoryStorage(fileManager: mockFS, baseURL: baseURL)
        return (storage, mockFS)
    }

    private func sampleLogItem(url: String = "https://api.example.com/users", statusCode: Int = 200) -> LogItem {
        LogItem(
            url: url,
            method: "GET",
            headers: ["Content-Type": "application/json"],
            requestBodyRaw: nil,
            statusCode: statusCode,
            responseBody: "{\"ok\":true}",
            responseHeaders: ["Content-Type": "application/json"],
            responseTime: 0.5,
            isLoading: false
        )
    }

    @Test("Save and retrieve log items for a key")
    func testSaveAndRetrieve() {
        let (storage, _) = makeStorage()
        let key = "2026-03-01 - 2026-03-03"
        let items = [sampleLogItem(), sampleLogItem(url: "https://api.example.com/posts", statusCode: 201)]

        storage.save(items, forKey: key)
        let retrieved = storage.retrieve(forKey: key)

        #expect(retrieved.count == 2)
        #expect(retrieved[0].url == "https://api.example.com/users")
        #expect(retrieved[1].statusCode == 201)
    }

    @Test("Retrieve non-existent key returns empty array")
    func testRetrieveNonExistentKey() {
        let (storage, _) = makeStorage()
        let retrieved = storage.retrieve(forKey: "non-existent-key")
        #expect(retrieved.isEmpty)
    }

    @Test("Delete removes log items for a key")
    func testDelete() {
        let (storage, _) = makeStorage()
        let key = "2026-03-01 - 2026-03-03"

        storage.save([sampleLogItem()], forKey: key)
        #expect(storage.retrieve(forKey: key).count == 1)

        storage.delete(forKey: key)
        #expect(storage.retrieve(forKey: key).isEmpty)
    }

    @Test("Delete non-existent key does not throw")
    func testDeleteNonExistentKey() {
        let (storage, _) = makeStorage()
        storage.delete(forKey: "does-not-exist")
        // No error expected
    }

    @Test("List keys returns all stored keys")
    func testListKeys() {
        let (storage, _) = makeStorage()
        let key1 = "2026-03-01 - 2026-03-03"
        let key2 = "2026-02-01 - 2026-02-28"

        storage.save([sampleLogItem()], forKey: key1)
        storage.save([sampleLogItem()], forKey: key2)

        let keys = storage.listKeys()
        #expect(keys.count == 2)
        let keyStrings = keys.map(\.key)
        #expect(keyStrings.contains(key1))
        #expect(keyStrings.contains(key2))
    }

    @Test("Clear all removes all entries")
    func testClearAll() {
        let (storage, _) = makeStorage()

        storage.save([sampleLogItem()], forKey: "key1")
        storage.save([sampleLogItem()], forKey: "key2")
        #expect(storage.listKeys().count == 2)

        storage.clearAll()
        #expect(storage.listKeys().isEmpty)
    }

    @Test("Overwrite existing key replaces data")
    func testOverwrite() {
        let (storage, _) = makeStorage()
        let key = "2026-03-01 - 2026-03-03"

        storage.save([sampleLogItem(statusCode: 200)], forKey: key)
        #expect(storage.retrieve(forKey: key).first?.statusCode == 200)

        storage.save([sampleLogItem(statusCode: 404)], forKey: key)
        let retrieved = storage.retrieve(forKey: key)
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.statusCode == 404)
    }

    @Test("Keys with special characters are handled correctly")
    func testSpecialCharacterKeys() {
        let (storage, _) = makeStorage()
        let key = "2026/03/01 12:00 - 2026/03/03 23:59"

        storage.save([sampleLogItem()], forKey: key)
        let retrieved = storage.retrieve(forKey: key)
        #expect(retrieved.count == 1)

        let keys = storage.listKeys()
        #expect(keys.map(\.key).contains(key))
    }

    @Test("Preserves LogItem properties through save/retrieve cycle")
    func testPropertyPreservation() {
        let (storage, _) = makeStorage()
        let key = "test-key"
        let responseData = "{\"id\":1}".data(using: .utf8)
        let item = LogItem(
            url: "https://api.example.com/data",
            method: "POST",
            headers: ["Authorization": "Bearer token123", "Content-Type": "application/json"],
            requestBodyRaw: "{\"name\":\"test\"}".data(using: .utf8),
            statusCode: 201,
            responseHeaders: ["X-Request-Id": "abc-123"],
            mimetype: "application/json",
            textEncodingName: "utf-8",
            responseRaw: responseData,
            errorDescription: nil,
            errorLocalizedDescription: nil,
            finishTime: Date(),
            responseTime: 1.25,
            isLoading: false
        )

        storage.save([item], forKey: key)
        let retrieved = storage.retrieve(forKey: key)

        #expect(retrieved.count == 1)
        if let saved = retrieved.first {
            #expect(saved.id == item.id)
            #expect(saved.url == "https://api.example.com/data")
            #expect(saved.method == "POST")
            #expect(saved.statusCode == 201)
            #expect(saved.headers["Authorization"] == "Bearer token123")
            #expect(saved.requestBody == "{\n  \"name\" : \"test\"\n}")
            #expect(saved.responseRaw == responseData)
            #expect(saved.mimetype == "application/json")
            #expect(saved.responseTime == 1.25)
            #expect(saved.isLoading == false)
        }
    }
}
