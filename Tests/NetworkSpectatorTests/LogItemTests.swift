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
        #expect(item.statusCategory == "NA")
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
        #expect(item.statusCodeRange == "NA")
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

    // MARK: - withMockID Tests
    
    @Test("withMockID sets mock ID and preserves all other fields")
    func testWithMockIDSetsID() async throws {
        let mockId = UUID()
        let item = LogItem(
            url: "https://example.com/api",
            method: "POST",
            headers: ["Content-Type": "application/json"],
            requestBodyRaw: "{\"key\":\"val\"}".data(using: .utf8)
        )
        

        let updated = item.withMockID(mockId)

        #expect(updated.mockId == mockId)
        #expect(updated.id == item.id)
        #expect(updated.startTime == item.startTime)
        #expect(updated.url == item.url)
        #expect(updated.method == item.method)
        #expect(updated.headers == item.headers)
        #expect(updated.requestBody == item.requestBody)
    }

    @Test("withMockID with nil clears mock ID")
    func testWithMockIDNilClearsMockID() async throws {
        let item = LogItem(url: "https://example.com", mockId: UUID())
        let updated = item.withMockID(nil)
        #expect(updated.mockId == nil)
        #expect(updated.isMocked == false)
    }

    @Test("withMockID default parameter is nil")
    func testWithMockIDDefaultParamIsNil() async throws {
        let item = LogItem(url: "https://example.com", mockId: UUID())
        let updated = item.withMockID()
        #expect(updated.mockId == nil)
    }

    @Test("LogItem codable encoding and decoding")
    func testCodable() async throws {
        let responseData = #"{"key":"value"}"#.data(using: .utf8)
        let original = LogItem(
            url: "https://example.com/api",
            method: "GET",
            statusCode: 200,
            responseRaw: responseData
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LogItem.self, from: data)

        #expect(decoded.url == original.url)
        #expect(decoded.method == original.method)
        #expect(decoded.statusCode == original.statusCode)
        #expect(decoded.responseRaw == original.responseRaw)
        #expect(decoded.responseBody == original.responseBody)
    }

    // MARK: - responseBody Tests

    @Test("responseBody returns pretty printed JSON from responseRaw")
    func testResponseBodyPrettyPrintsJSON() async throws {
        let jsonData = #"{"name":"John","age":30}"#.data(using: .utf8)
        let item = LogItem(url: "https://example.com", responseRaw: jsonData)

        let body = item.responseBody
        #expect(body.contains("name"))
        #expect(body.contains("John"))
        #expect(body.contains("age"))
        #expect(body.contains("30"))
    }

    @Test("responseBody returns empty string when responseRaw is nil")
    func testResponseBodyEmptyWhenNil() async throws {
        let item = LogItem(url: "https://example.com", responseRaw: nil)
        #expect(item.responseBody == "")
    }

    @Test("responseBody returns empty string when responseRaw is empty")
    func testResponseBodyEmptyWhenEmpty() async throws {
        let item = LogItem(url: "https://example.com", responseRaw: Data())
        #expect(item.responseBody == "")
    }

    @Test("responseBody returns plain text for non-JSON data")
    func testResponseBodyPlainText() async throws {
        let textData = "Hello, World!".data(using: .utf8)
        let item = LogItem(url: "https://example.com", responseRaw: textData)
        #expect(item.responseBody == "Hello, World!")
    }

    // MARK: - Status Category Edge Cases

    @Test("LogItem status category Other for 600+")
    func testStatusCategoryOther() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 600)
        #expect(item.statusCategory == "NA")
    }

    @Test("LogItem status code range Other for 600+")
    func testStatusCodeRangeOther() async throws {
        let item = LogItem(url: "https://example.com", statusCode: 600)
        #expect(item.statusCodeRange == "NA")
    }

    // MARK: - Pretty Printed Headers

    @Test("requestHeadersPrettyPrinted formats headers correctly")
    func testRequestHeadersPrettyPrinted() async throws {
        let item = LogItem(
            url: "https://example.com",
            headers: ["Content-Type": "application/json"]
        )
        let pretty = item.requestHeadersPrettyPrinted
        #expect(pretty.contains("Content-Type"))
        #expect(pretty.contains("application/json"))
    }

    @Test("responseHeadersPrettyPrinted formats headers correctly")
    func testResponseHeadersPrettyPrinted() async throws {
        let item = LogItem(
            url: "https://example.com",
            responseHeaders: ["X-Request-Id": "abc123"]
        )
        let pretty = item.responseHeadersPrettyPrinted
        #expect(pretty.contains("X-Request-Id"))
        #expect(pretty.contains("abc123"))
    }

    @Test("requestHeadersPrettyPrinted returns empty for no headers")
    func testRequestHeadersPrettyPrintedEmpty() async throws {
        let item = LogItem(url: "https://example.com", headers: [:])
        #expect(item.requestHeadersPrettyPrinted == "")
    }

    // MARK: - Host with invalid URL

    @Test("LogItem host returns URL string when parsing fails")
    func testHostWithInvalidURL() async throws {
        let item = LogItem(url: "not a valid url with spaces")
        // URLComponents will fail, so host should return the raw url
        #expect(item.host == "not a valid url with spaces")
    }

    // MARK: - fromRequest preserves mock ID

    @Test("fromRequest with mockId preserves it")
    func testFromRequestWithMockId() async throws {
        let mockId = UUID()
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let item = LogItem.fromRequest(request, mockId)
        #expect(item.mockId == mockId)
        #expect(item.isMocked == true)
    }

    @Test("fromRequest without mockId has nil mockId")
    func testFromRequestWithoutMockId() async throws {
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let item = LogItem.fromRequest(request)
        #expect(item.mockId == nil)
        #expect(item.isMocked == false)
    }
}
