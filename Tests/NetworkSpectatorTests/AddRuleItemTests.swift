//
//  AddRuleItemTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 14/03/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - AddRuleItem Tests
@Suite("AddRuleItem Tests")
struct AddRuleItemTests {

    // MARK: - Standard Init

    @Test("Standard init sets all fields correctly")
    func testStandardInit() {
        let id = UUID()
        let item = AddRuleItem(
            id: id,
            text: "https://example.com",
            response: "{\"key\": \"value\"}",
            statusCode: "200",
            headers: "Content-Type===application/json",
            rule: .url,
            isMock: true,
            saveLocally: true
        )

        #expect(item.id == id)
        #expect(item.text == "https://example.com")
        #expect(item.response == "{\"key\": \"value\"}")
        #expect(item.statusCode == "200")
        #expect(item.headers == "Content-Type===application/json")
        #expect(item.rule == .url)
        #expect(item.isMock == true)
        #expect(item.saveLocally == true)
        #expect(item.showDelete == false)
    }

    @Test("Standard init defaults showDelete to false")
    func testStandardInitShowDeleteFalse() {
        let item = AddRuleItem(id: UUID(), text: "test", rule: .url, isMock: false)
        #expect(item.showDelete == false)
    }

    @Test("Standard init defaults empty strings for optional fields")
    func testStandardInitDefaults() {
        let item = AddRuleItem(id: UUID(), text: "test", rule: .path, isMock: true)
        #expect(item.response == "")
        #expect(item.statusCode == "")
        #expect(item.headers == "")
        #expect(item.saveLocally == false)
    }

    // MARK: - Init from Mock with supported rules

    @Test("Init from Mock with .url rule succeeds")
    func testInitFromMockURLRule() {
        let noData: Data? = nil
        let mock = Mock(method: .GET, rule: .url("https://example.com"), response: noData)
        let item = AddRuleItem(mock: mock)

        #expect(item != nil)
        #expect(item?.text == "https://example.com")
        #expect(item?.rule == .url)
        #expect(item?.isMock == true)
        #expect(item?.showDelete == true)
    }

    @Test("Init from Mock with .path rule succeeds")
    func testInitFromMockPathRule() {
        let noData: Data? = nil
        let mock = Mock(method: .GET, rule: .path("/api/users"), response: noData)
        let item = AddRuleItem(mock: mock)

        #expect(item != nil)
        #expect(item?.text == "/api/users")
        #expect(item?.rule == .path)
    }

    @Test("Init from Mock with .endPath rule succeeds")
    func testInitFromMockEndPathRule() {
        let noData: Data? = nil
        let mock = Mock(method: .GET, rule: .endPath("users"), response: noData)
        let item = AddRuleItem(mock: mock)

        #expect(item != nil)
        #expect(item?.text == "users")
        #expect(item?.rule == .endPath)
    }

    @Test("Init from Mock with .subPath rule maps to pathComponent")
    func testInitFromMockSubPathRule() {
        let noData: Data? = nil
        let mock = Mock(method: .GET, rule: .subPath("api"), response: noData)
        let item = AddRuleItem(mock: mock)

        #expect(item != nil)
        #expect(item?.text == "api")
        #expect(item?.rule == .pathComponent)
    }

    @Test("Init from Mock populates response, statusCode, and headers")
    func testInitFromMockPopulatesFields() {
        let responseData = "{\"key\": \"value\"}".data(using: .utf8)
        let mock = Mock(
            method: .GET,
            rule: .url("https://example.com"),
            response: responseData,
            headers: ["Content-Type": "application/json"],
            statusCode: 201
        )
        let item = AddRuleItem(mock: mock)

        #expect(item != nil)
        #expect(item?.response == "{\"key\": \"value\"}")
        #expect(item?.statusCode == "201")
        #expect(item?.headers.contains("Content-Type===application/json") == true)
    }

    @Test("Init from Mock preserves saveLocally")
    func testInitFromMockSaveLocally() {
        let noData: Data? = nil
        let mock = Mock(method: .GET, rule: .url("https://example.com"), response: noData, headers: [:], statusCode: 200, error: nil, saveLocally: true)
        let item = AddRuleItem(mock: mock)

        #expect(item?.saveLocally == true)
    }

    // MARK: - Init from Mock with unsupported rules

    @Test("Init from Mock with .hostName returns nil")
    func testInitFromMockHostNameReturnsNil() {
        let noData: Data? = nil
        let mock = Mock(method: .GET, rule: .hostName("example.com"), response: noData)
        let item = AddRuleItem(mock: mock)
        #expect(item == nil)
    }

    @Test("Init from Mock with .regex returns nil")
    func testInitFromMockRegexReturnsNil() {
        let noData: Data? = nil
        let mock = Mock(method: .GET, rule: .regex(".*"), response: noData)
        let item = AddRuleItem(mock: mock)
        #expect(item == nil)
    }

    @Test("Init from Mock with .queryParameter returns nil")
    func testInitFromMockQueryParameterReturnsNil() {
        let noData: Data? = nil
        let mock = Mock(method: .GET, rule: .queryParameter(key: "id", value: "1"), response: noData)
        let item = AddRuleItem(mock: mock)
        #expect(item == nil)
    }

    @Test("Init from Mock with .urlRequest returns nil")
    func testInitFromMockURLRequestReturnsNil() {
        let noData: Data? = nil
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let mock = Mock(method: .GET, rule: .urlRequest(request), response: noData)
        let item = AddRuleItem(mock: mock)
        #expect(item == nil)
    }

    // MARK: - Init from SkipRequestForLogging with supported rules

    @Test("Init from SkipRequest with .url rule succeeds")
    func testInitFromSkipRequestURLRule() {
        let skip = LogSkipRequest(method: .GET, rule: .url("https://example.com"))
        let item = AddRuleItem(skipRequest: skip)

        #expect(item != nil)
        #expect(item?.text == "https://example.com")
        #expect(item?.rule == .url)
        #expect(item?.isMock == false)
        #expect(item?.showDelete == true)
    }

    @Test("Init from SkipRequest with .path rule succeeds")
    func testInitFromSkipRequestPathRule() {
        let skip = LogSkipRequest(method: .GET, rule: .path("/api"))
        let item = AddRuleItem(skipRequest: skip)

        #expect(item != nil)
        #expect(item?.text == "/api")
        #expect(item?.rule == .path)
    }

    @Test("Init from SkipRequest with .endPath rule succeeds")
    func testInitFromSkipRequestEndPathRule() {
        let skip = LogSkipRequest(method: .GET, rule: .endPath("users"))
        let item = AddRuleItem(skipRequest: skip)

        #expect(item != nil)
        #expect(item?.text == "users")
        #expect(item?.rule == .endPath)
    }

    @Test("Init from SkipRequest with .subPath rule maps to pathComponent")
    func testInitFromSkipRequestSubPathRule() {
        let skip = LogSkipRequest(method: .GET, rule: .subPath("api"))
        let item = AddRuleItem(skipRequest: skip)

        #expect(item != nil)
        #expect(item?.text == "api")
        #expect(item?.rule == .pathComponent)
    }

    @Test("Init from SkipRequest has empty response fields")
    func testInitFromSkipRequestEmptyResponseFields() {
        let skip = LogSkipRequest(method: .GET, rule: .url("https://example.com"))
        let item = AddRuleItem(skipRequest: skip)

        #expect(item?.response == "")
        #expect(item?.statusCode == "")
        #expect(item?.headers == "")
    }

    @Test("Init from SkipRequest preserves saveLocally")
    func testInitFromSkipRequestSaveLocally() {
        let skip = LogSkipRequest(method: .GET, rule: .url("https://example.com"), saveLocally: true)
        let item = AddRuleItem(skipRequest: skip)

        #expect(item?.saveLocally == true)
    }

    // MARK: - Init from SkipRequest with unsupported rules

    @Test("Init from SkipRequest with .hostName returns nil")
    func testInitFromSkipRequestHostNameReturnsNil() {
        let skip = LogSkipRequest(method: .GET, rule: .hostName("example.com"))
        let item = AddRuleItem(skipRequest: skip)
        #expect(item == nil)
    }

    @Test("Init from SkipRequest with .regex returns nil")
    func testInitFromSkipRequestRegexReturnsNil() {
        let skip = LogSkipRequest(method: .GET, rule: .regex(".*"))
        let item = AddRuleItem(skipRequest: skip)
        #expect(item == nil)
    }

    @Test("Init from SkipRequest with .queryParameter returns nil")
    func testInitFromSkipRequestQueryParameterReturnsNil() {
        let skip = LogSkipRequest(method: .GET, rule: .queryParameter(key: "id", value: "1"))
        let item = AddRuleItem(skipRequest: skip)
        #expect(item == nil)
    }
}
