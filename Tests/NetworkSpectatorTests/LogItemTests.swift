//
//  LogItemTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - LogItem Tests
@Suite("LogItem Tests")
struct LogItemTests {

    @Test("LogItem initialization with defaults")
    func testLogItemInitialization() async throws {
        let item = LogItem(url: "https://example.com/api/users")

        #expect(item.url == "https://example.com/api/users")
        #expect(item.method == "")
        #expect(item.statusCode == 0)
        #expect(item.isLoading == true)
        #expect(item.responseTime == 0)
    }

    @Test("LogItem host extraction")
    func testLogItemHost() async throws {
        let item = LogItem(url: "https://example.com/api/users")
        #expect(item.host == "example.com")
    }

    @Test("LogItem path extraction")
    func testLogItemPath() async throws {
        let item = LogItem(url: "https://example.com/api/users")
        #expect(item.path == "/api/users")
    }

    @Test("LogItem scheme extraction")
    func testLogItemScheme() async throws {
        let item = LogItem(url: "https://example.com/api/users")
        #expect(item.scheme == "https")
    }

    @Test("LogItem status category informational")
    func testStatusCategoryInformational() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 100)
        #expect(item.statusCategory == "Informational")
    }

    @Test("LogItem status category success")
    func testStatusCategorySuccess() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 200)
        #expect(item.statusCategory == "Success")
    }

    @Test("LogItem status category redirection")
    func testStatusCategoryRedirection() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 301)
        #expect(item.statusCategory == "Redirection")
    }

    @Test("LogItem status category client error")
    func testStatusCategoryClientError() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 404)
        #expect(item.statusCategory == "Client Error")
    }

    @Test("LogItem status category server error")
    func testStatusCategoryServerError() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 500)
        #expect(item.statusCategory == "Server Error")
    }

    @Test("LogItem status category unknown")
    func testStatusCategoryUnknown() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 0)
        #expect(item.statusCategory == "Unknown")
    }

    @Test("LogItem status code range informational")
    func testStatusCodeRangeInformational() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 100)
        #expect(item.statusCodeRange == "100..<200")
    }

    @Test("LogItem status code range success")
    func testStatusCodeRangeSuccess() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 200)
        #expect(item.statusCodeRange == "200..<300")
    }

    @Test("LogItem status code range redirection")
    func testStatusCodeRangeRedirection() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 301)
        #expect(item.statusCodeRange == "300..<400")
    }

    @Test("LogItem status code range client error")
    func testStatusCodeRangeClientError() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 404)
        #expect(item.statusCodeRange == "400..<500")
    }

    @Test("LogItem status code range server error")
    func testStatusCodeRangeServerError() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 500)
        #expect(item.statusCodeRange == "500..<600")
    }

    @Test("LogItem status code range unknown")
    func testStatusCodeRangeUnknown() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 0)
        #expect(item.statusCodeRange == "Unknown")
    }

    @Test("LogItem is error with 4xx status")
    func testIsErrorWith4xx() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 404)
        #expect(item.isError == true)
    }

    @Test("LogItem is error with 5xx status")
    func testIsErrorWith5xx() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 500)
        #expect(item.isError == true)
    }

    @Test("LogItem is error with error description")
    func testIsErrorWithErrorDescription() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 200, errorDescription: "Network error")
        #expect(item.isError == true)
    }

    @Test("LogItem is not error with success status")
    func testIsNotErrorWithSuccess() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 200)
        #expect(item.isError == false)
    }

    @Test("LogItem from request")
    func testFromRequest() async throws {
        var request = URLRequest(url: URL(string: "https://example.com/api/users")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = #"{"name": "John"}"#.data(using: .utf8)

        let item = LogItem.fromRequest(request)

        #expect(item.url == "https://example.com/api/users")
        #expect(item.method == "POST")
        #expect(item.headers["Content-Type"] != nil)
        #expect(item.requestBody.contains("name"))
    }

    @Test("LogItem with response")
    func testWithResponse() async throws {
        let startItem = LogItem(url: "https://example.com/api/users", method: "GET")

        let url = URL(string: "https://example.com/api/users")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])
        let data = #"{"result": "success"}"#.data(using: .utf8)

        let finishedItem = startItem.withResponse(response: response, data: data, error: nil)

        #expect(finishedItem.statusCode == 200)
        #expect(finishedItem.isLoading == false)
        #expect(finishedItem.finishTime != nil)
        #expect(finishedItem.responseTime > 0)
        #expect(finishedItem.responseBody.contains("result"))
    }

    @Test("LogItem with response error")
    func testWithResponseError() async throws {
        let startItem = LogItem(url: "https://example.com/api/users")
        let error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])

        let finishedItem = startItem.withResponse(response: nil, data: nil, error: error)

        #expect(finishedItem.errorDescription != nil)
        #expect(finishedItem.errorLocalizedDescription == "Connection failed")
        #expect(finishedItem.isLoading == false)
    }

    @Test("LogItem isMocked is true when mockId is set")
    func testIsMockedWithMockId() async throws {
        let mockId = UUID()
        let item = LogItem(url: "https://example.com", mockId: mockId)
        #expect(item.isMocked == true)
        #expect(item.mockId == mockId)
    }

    @Test("LogItem isMocked is false when mockId is nil")
    func testIsMockedWithoutMockId() async throws {
        let item = LogItem(url: "https://example.com")
        #expect(item.isMocked == false)
        #expect(item.mockId == nil)
    }

    @Test("LogItem withResponse preserves mockId and sets responseRaw")
    func testWithResponsePreservesMockIdAndSetsResponseRaw() async throws {
        let mockId = UUID()
        let startItem = LogItem(url: "https://example.com", mockId: mockId)

        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let data = "response body".data(using: .utf8)

        let finishedItem = startItem.withResponse(response: response, data: data, error: nil)

        #expect(finishedItem.mockId == mockId)
        #expect(finishedItem.isMocked == true)
        #expect(finishedItem.responseRaw == data)
    }

    @Test("LogItem codable encoding and decoding")
    func testCodable() async throws {
        let original = LogItem(
            url: "https://example.com/api",
            method: "GET",
            statusCode: 200,
            responseBody: "test"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LogItem.self, from: data)

        #expect(decoded.url == original.url)
        #expect(decoded.method == original.method)
        #expect(decoded.statusCode == original.statusCode)
        #expect(decoded.responseBody == original.responseBody)
    }
}
