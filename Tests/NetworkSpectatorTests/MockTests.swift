import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - Mock Tests
@Suite("Mock Tests")
struct MockTests {

    @Test("Mock with rules and JSON response")
    func testMockWithRulesAndJSON() async throws {
        let rules = [MatchRule.hostName("example.com")]
        let response: [AnyHashable: Any] = ["status": "success", "data": ["id": 123]]

        let mock = try Mock(rules: rules, response: response, statusCode: 200)

        #expect(mock.statusCode == 200)
        #expect(mock.response != nil)
        #expect(mock.rules?.count == 1)
    }

    @Test("Mock with rules and data response")
    func testMockWithRulesAndData() async throws {
        let rules = [MatchRule.path("/api/users")]
        let data = "Test response".data(using: .utf8)

        let mock = Mock(rules: rules, response: data as Data?, statusCode: 404, error: nil)

        #expect(mock.statusCode == 404)
        #expect(mock.response == data)
    }

    @Test("Mock with custom matcher and JSON")
    func testMockWithCustomMatcherAndJSON() async throws {
        let response: [AnyHashable: Any] = ["message": "matched"]
        let mock = try Mock(response: response, statusCode: 200) { request in
            request.httpMethod == "POST"
        }

        #expect(mock.statusCode == 200)
        #expect(mock.matches != nil)
    }

    @Test("Mock with custom matcher and data")
    func testMockWithCustomMatcherAndData() async throws {
        let data = "Custom data".data(using: .utf8)
        let mock = Mock(response: data, statusCode: 201) { request in
            request.url?.absoluteString.contains("test") ?? false
        }

        #expect(mock.statusCode == 201)
        #expect(mock.response == data)
    }

    @Test("Mock with headers")
    func testMockWithHeaders() async throws {
        let headers = ["Content-Type": "application/json", "X-Custom": "value"]
        let mock = Mock(rules: [.hostName("example.com")], response: nil as Data?, headers: headers, statusCode: 200)

        #expect(mock.headers["Content-Type"] == "application/json")
        #expect(mock.headers["X-Custom"] == "value")
    }

    @Test("Mock with error")
    func testMockWithError() async throws {
        let error = NSError(domain: "test", code: -1, userInfo: nil)
        let mock = Mock(rules: [.hostName("example.com")], response: nil as Data?, statusCode: 500, error: error)

        #expect(mock.error != nil)
        #expect(mock.statusCode == 500)
    }

    @Test("Mock URL response generation")
    func testMockURLResponse() async throws {
        let url = URL(string: "https://example.com/api")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let mock = Mock(rules: [.hostName("example.com")], response: nil as Data?, headers: ["X-Test": "value"], statusCode: 201)
        let response = mock.urlResponse(request)

        #expect(response?.statusCode == 201)
        let headerValue = response?.allHeaderFields["X-Test"] as? String
        #expect(headerValue == "value")
    }

    @Test("Mock equality by id")
    func testMockEquality() async throws {
        let mock1 = Mock(rules: [.hostName("example.com")], response: nil as Data?, statusCode: 200)
        let mock2 = Mock(rules: [.hostName("example.com")], response: nil as Data?, statusCode: 200)

        #expect(mock1 == mock1)
        #expect(mock1 != mock2) // Different IDs
    }
}
