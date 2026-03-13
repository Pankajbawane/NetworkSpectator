//
//  HistoryItemTests.swift
//  NetworkSpectator
//
//  Created by Claude on 13/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - HistoryItem Tests
@Suite("HistoryItem Tests")
struct HistoryItemTests {

    @Test("id returns the key")
    func testIdReturnsKey() {
        let item = HistoryItem(
            key: "2026-03-01 10:00:00|2026-03-01 10:30:00|5",
            url: URL(fileURLWithPath: "/tmp/test.json"),
            startTimestamp: "2026-03-01 10:00:00",
            endTimestamp: "2026-03-01 10:30:00",
            count: "5",
            size: 1024
        )
        #expect(item.id == item.key)
    }

    @Test("isCurrentSession defaults to false")
    func testIsCurrentSessionDefaultsFalse() {
        let item = HistoryItem(
            key: "test",
            url: URL(fileURLWithPath: "/tmp/test.json"),
            startTimestamp: "2026-03-01 10:00:00",
            endTimestamp: "2026-03-01 10:30:00",
            count: "5",
            size: 0
        )
        #expect(item.isCurrentSession == false)
    }

    @Test("isCurrentSession can be set to true")
    func testIsCurrentSessionMutable() {
        var item = HistoryItem(
            key: "test",
            url: URL(fileURLWithPath: "/tmp/test.json"),
            startTimestamp: "2026-03-01 10:00:00",
            endTimestamp: "2026-03-01 10:30:00",
            count: "5",
            size: 0
        )
        item.isCurrentSession = true
        #expect(item.isCurrentSession == true)
    }

    @Test("formattedTitle combines start and end times")
    func testFormattedTitle() {
        let item = HistoryItem(
            key: "2026-03-01 14:30:00|2026-03-01 14:45:00|10",
            url: URL(fileURLWithPath: "/tmp/test.json"),
            startTimestamp: "2026-03-01 14:30:00",
            endTimestamp: "2026-03-01 14:45:00",
            count: "10",
            size: 2048
        )
        let title = item.formattedTitle
        // The title should contain formatted date parts — exact format depends on locale
        // but it should contain a dash separator and non-empty content
        #expect(title.contains(" - "))
        #expect(!title.isEmpty)
    }

    @Test("formattedTitle handles invalid timestamps gracefully")
    func testFormattedTitleInvalidTimestamps() {
        let item = HistoryItem(
            key: "invalid|also-invalid|0",
            url: URL(fileURLWithPath: "/tmp/test.json"),
            startTimestamp: "invalid",
            endTimestamp: "also-invalid",
            count: "0",
            size: 0
        )
        let title = item.formattedTitle
        // Should still produce a string (with empty formatted parts) without crashing
        #expect(title == " - ")
    }

    @Test("shortTitle returns formatted start time")
    func testShortTitle() {
        let item = HistoryItem(
            key: "2026-03-01 14:30:00|2026-03-01 14:45:00|10",
            url: URL(fileURLWithPath: "/tmp/test.json"),
            startTimestamp: "2026-03-01 14:30:00",
            endTimestamp: "2026-03-01 14:45:00",
            count: "10",
            size: 0
        )
        let title = item.shortTitle
        #expect(!title.isEmpty)
        // Should NOT contain a dash (it's only the start time)
        #expect(!title.contains(" - "))
    }

    @Test("shortTitle falls back to raw timestamp on invalid input")
    func testShortTitleFallback() {
        let item = HistoryItem(
            key: "invalid-key",
            url: URL(fileURLWithPath: "/tmp/test.json"),
            startTimestamp: "not-a-date",
            endTimestamp: "",
            count: "",
            size: 0
        )
        #expect(item.shortTitle == "not-a-date")
    }

    @Test("Codable round-trip excludes isCurrentSession")
    func testCodableExcludesIsCurrentSession() throws {
        var original = HistoryItem(
            key: "2026-03-01 10:00:00|2026-03-01 10:30:00|5",
            url: URL(fileURLWithPath: "/tmp/test.json"),
            startTimestamp: "2026-03-01 10:00:00",
            endTimestamp: "2026-03-01 10:30:00",
            count: "5",
            size: 1024
        )
        original.isCurrentSession = true

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HistoryItem.self, from: data)

        #expect(decoded.key == original.key)
        #expect(decoded.startTimestamp == original.startTimestamp)
        #expect(decoded.endTimestamp == original.endTimestamp)
        #expect(decoded.count == original.count)
        #expect(decoded.size == original.size)
        // isCurrentSession should revert to default (false) after decode
        #expect(decoded.isCurrentSession == false)
    }

    @Test("Codable round-trip preserves all coded properties")
    func testCodablePreservesProperties() throws {
        let original = HistoryItem(
            key: "2026-06-15 09:00:00|2026-06-15 09:45:00|42",
            url: URL(fileURLWithPath: "/data/logs/session.json"),
            startTimestamp: "2026-06-15 09:00:00",
            endTimestamp: "2026-06-15 09:45:00",
            count: "42",
            size: 8192
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HistoryItem.self, from: data)

        #expect(decoded.key == "2026-06-15 09:00:00|2026-06-15 09:45:00|42")
        #expect(decoded.url == URL(fileURLWithPath: "/data/logs/session.json"))
        #expect(decoded.startTimestamp == "2026-06-15 09:00:00")
        #expect(decoded.endTimestamp == "2026-06-15 09:45:00")
        #expect(decoded.count == "42")
        #expect(decoded.size == 8192)
    }
}

// MARK: - LogHistoryStorage Key Encoding Tests
@Suite("LogHistoryStorage Key Encoding Tests")
struct LogHistoryStorageKeyEncodingTests {

    private func makeStorage() -> (LogHistoryStorage, MockFileStorage) {
        let mockFS = MockFileStorage()
        let baseURL = URL(fileURLWithPath: "/tmp/test-key-encoding")
        let storage = LogHistoryStorage(fileManager: mockFS, baseURL: baseURL)
        return (storage, mockFS)
    }

    @Test("Key with pipe-delimited session format round-trips")
    func testPipeDelimitedKeyRoundTrip() {
        let (storage, _) = makeStorage()
        let key = "2026-03-01 14:30:00|2026-03-01 14:45:00|10"
        let item = LogItem(url: "https://example.com", statusCode: 200)

        storage.save([item], forKey: key)
        let retrieved = storage.retrieve(forKey: key)

        #expect(retrieved.count == 1)
        #expect(retrieved.first?.url == "https://example.com")
    }

    @Test("listKeys correctly parses pipe-delimited components")
    func testListKeysParsesPipeComponents() {
        let (storage, _) = makeStorage()
        let key = "2026-03-13 10:00:00|2026-03-13 10:30:00|15"
        let item = LogItem(url: "https://example.com")

        storage.save([item], forKey: key)

        let keys = storage.listKeys()
        #expect(keys.count == 1)

        if let historyItem = keys.first {
            #expect(historyItem.startTimestamp == "2026-03-13 10:00:00")
            #expect(historyItem.endTimestamp == "2026-03-13 10:30:00")
            #expect(historyItem.count == "15")
        }
    }

    @Test("listKeys with key missing pipe delimiters uses full key as startTimestamp")
    func testListKeysFallbackForNonPipeKey() {
        let (storage, _) = makeStorage()
        let key = "simple-key-no-pipes"
        let item = LogItem(url: "https://example.com")

        storage.save([item], forKey: key)

        let keys = storage.listKeys()
        #expect(keys.count == 1)

        if let historyItem = keys.first {
            #expect(historyItem.startTimestamp == "simple-key-no-pipes")
            #expect(historyItem.endTimestamp == "")
            #expect(historyItem.count == "")
        }
    }

    @Test("listKeys returns sorted descending by key")
    func testListKeysSortedDescending() {
        let (storage, _) = makeStorage()

        storage.save([LogItem(url: "https://a.com")], forKey: "2026-01-01 00:00:00|2026-01-01 01:00:00|1")
        storage.save([LogItem(url: "https://c.com")], forKey: "2026-03-01 00:00:00|2026-03-01 01:00:00|1")
        storage.save([LogItem(url: "https://b.com")], forKey: "2026-02-01 00:00:00|2026-02-01 01:00:00|1")

        let keys = storage.listKeys()
        #expect(keys.count == 3)
        #expect(keys[0].startTimestamp == "2026-03-01 00:00:00")
        #expect(keys[1].startTimestamp == "2026-02-01 00:00:00")
        #expect(keys[2].startTimestamp == "2026-01-01 00:00:00")
    }
}
