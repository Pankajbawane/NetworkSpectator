//
//  MockTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - Mock Tests
@Suite("Mock Tests")
struct MockTests {

    @Test("Mock with rule and JSON response")
    func testMockWithRuleAndJSON() async throws {
        let response: [AnyHashable: Any] = ["status": "success", "data": ["id": 123]]

        let mock = try Mock(rule: .hostName("example.com"), response: response, statusCode: 200)

        #expect(mock.statusCode == 200)
        #expect(mock.response != nil)
        #expect(mock.rule == .hostName("example.com"))
    }

    @Test("Mock with rule and data response")
    func testMockWithRuleAndData() async throws {
        let data = "Test response".data(using: .utf8)

        let mock = Mock(rule: .path("/api/users"), response: data as Data?, statusCode: 404, error: nil)

        #expect(mock.statusCode == 404)
        #expect(mock.response == data)
    }

    @Test("Mock with rule and JSON")
    func testMockWithRuleAndJSON2() async throws {
        let response: [AnyHashable: Any] = ["message": "matched"]
        let mock = try Mock(rule: .hostName("example.com"), response: response, statusCode: 200)

        #expect(mock.statusCode == 200)
        #expect(mock.rule == .hostName("example.com"))
    }

    @Test("Mock with rule and data")
    func testMockWithRuleAndData2() async throws {
        let data = "Custom data".data(using: .utf8)
        let mock = Mock(rule: .path("/test"), response: data, statusCode: 201)

        #expect(mock.statusCode == 201)
        #expect(mock.response == data)
    }

    @Test("Mock with headers")
    func testMockWithHeaders() async throws {
        let headers = ["Content-Type": "application/json", "X-Custom": "value"]
        let mock = Mock(rule: .hostName("example.com"), response: nil as Data?, headers: headers, statusCode: 200)

        #expect(mock.headers["Content-Type"] == "application/json")
        #expect(mock.headers["X-Custom"] == "value")
    }

    @Test("Mock with error")
    func testMockWithError() async throws {
        let error = NSError(domain: "test", code: -1, userInfo: nil)
        let mock = Mock(rule: .hostName("example.com"), response: nil as Data?, statusCode: 500, error: error)

        #expect(mock.error != nil)
        #expect(mock.statusCode == 500)
    }

    @Test("Mock URL response generation")
    func testMockURLResponse() async throws {
        let url = URL(string: "https://example.com/api")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let mock = Mock(rule: .hostName("example.com"), response: nil as Data?, headers: ["X-Test": "value"], statusCode: 201)
        let response = mock.urlResponse(request)

        #expect(response?.statusCode == 201)
        let headerValue = response?.allHeaderFields["X-Test"] as? String
        #expect(headerValue == "value")
    }

    @Test("Mock equality")
    func testMockEquality() async throws {
        let mock1 = Mock(rule: .hostName("example.com"), response: nil as Data?, statusCode: 200)
        let mock2 = Mock(rule: .hostName("example.com"), response: nil as Data?, statusCode: 200)
        let mock3 = Mock(rule: .hostName("different.com"), response: nil as Data?, statusCode: 404)

        // Equality is based on ID, not content
        #expect(mock1 != mock2) // Different IDs
        #expect(mock1 != mock3) // Different IDs
        #expect(mock1 == mock1) // Same instance
    }

    @Test("Mock default delay is zero")
    func testMockDefaultDelayIsZero() async throws {
        let mock = Mock(rule: .hostName("example.com"), response: nil as Data?, statusCode: 200)

        #expect(mock.delay == 0)
    }

    @Test("Mock with custom delay")
    func testMockWithCustomDelay() async throws {
        let mock = Mock(rule: .url("https://api.example.com/slow"), response: nil as Data?, statusCode: 200, delay: 2.5)

        #expect(mock.delay == 2.5)
    }

    @Test("Mock with delay and JSON response")
    func testMockWithDelayAndJSONResponse() async throws {
        let response: [AnyHashable: Any] = ["status": "ok"]
        let mock = try Mock(rule: .path("/delayed"), response: response, statusCode: 200, delay: 1.0)

        #expect(mock.delay == 1.0)
        #expect(mock.response != nil)
        #expect(mock.statusCode == 200)
    }

    @Test("Mock delay persists through Codable round-trip")
    func testMockDelayCodable() async throws {
        let original = Mock(rule: .url("https://api.example.com/data"), response: nil as Data?, statusCode: 200, delay: 3.0)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Mock.self, from: encoded)

        #expect(decoded.delay == 3.0)
        #expect(decoded.statusCode == original.statusCode)
        #expect(decoded.id == original.id)
    }
}
