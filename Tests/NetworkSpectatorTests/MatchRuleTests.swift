//
//  MatchRuleTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/12/25.
//

import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - MatchRule Tests
@Suite("MatchRule Tests")
struct MatchRuleTests {

    @Test("Host name exact match")
    func testHostNameExactMatch() async throws {
        let rule = MatchRule.hostName("example.com")
        let request = URLRequest(url: URL(string: "https://example.com/api/users")!)
        #expect(rule.matches(request))
    }

    @Test("Host name case insensitive match")
    func testHostNameCaseInsensitive() async throws {
        let rule = MatchRule.hostName("EXAMPLE.COM")
        let request = URLRequest(url: URL(string: "https://example.com/api/users")!)
        #expect(rule.matches(request))
    }

    @Test("Host name wildcard match")
    func testHostNameWildcard() async throws {
        let rule = MatchRule.hostName("*.example.com")
        let request1 = URLRequest(url: URL(string: "https://api.example.com/users")!)
        let request2 = URLRequest(url: URL(string: "https://test.example.com/data")!)
        let request3 = URLRequest(url: URL(string: "https://example.com/users")!)

        #expect(rule.matches(request1))
        #expect(rule.matches(request2))
        #expect(!rule.matches(request3)) // Exact match should not work with wildcard
    }

    @Test("Host name no match")
    func testHostNameNoMatch() async throws {
        let rule = MatchRule.hostName("example.com")
        let request = URLRequest(url: URL(string: "https://different.com/api")!)
        #expect(!rule.matches(request))
    }

    @Test("URL exact match")
    func testURLExactMatch() async throws {
        let rule = MatchRule.url("https://example.com/api/users")
        let request = URLRequest(url: URL(string: "https://example.com/api/users")!)
        #expect(rule.matches(request))
    }

    @Test("URL wildcard match")
    func testURLWildcard() async throws {
        let rule = MatchRule.url("https://example.com/api/*")
        let request1 = URLRequest(url: URL(string: "https://example.com/api/users")!)
        let request2 = URLRequest(url: URL(string: "https://example.com/api/posts")!)
        let request3 = URLRequest(url: URL(string: "https://example.com/other/data")!)

        #expect(rule.matches(request1))
        #expect(rule.matches(request2))
        #expect(!rule.matches(request3))
    }

    @Test("Path exact match")
    func testPathExactMatch() async throws {
        let rule = MatchRule.path("/api/users")
        let request = URLRequest(url: URL(string: "https://example.com/api/users")!)
        #expect(rule.matches(request))
    }

    @Test("Path wildcard match")
    func testPathWildcard() async throws {
        let rule = MatchRule.path("/api/*")
        let request1 = URLRequest(url: URL(string: "https://example.com/api/users")!)
        let request2 = URLRequest(url: URL(string: "https://example.com/api/posts")!)
        let request3 = URLRequest(url: URL(string: "https://example.com/other")!)

        #expect(rule.matches(request1))
        #expect(rule.matches(request2))
        #expect(!rule.matches(request3))
    }

    @Test("End path match")
    func testEndPathMatch() async throws {
        let rule = MatchRule.endPath("users")
        let request1 = URLRequest(url: URL(string: "https://example.com/api/users")!)
        let request2 = URLRequest(url: URL(string: "https://example.com/v2/users")!)
        let request3 = URLRequest(url: URL(string: "https://example.com/api/posts")!)

        #expect(rule.matches(request1))
        #expect(rule.matches(request2))
        #expect(!rule.matches(request3))
    }

    @Test("Sub path match")
    func testSubPathMatch() async throws {
        let rule = MatchRule.subPath("api")
        let request1 = URLRequest(url: URL(string: "https://example.com/api/users")!)
        let request2 = URLRequest(url: URL(string: "https://example.com/v1/api/posts")!)
        let request3 = URLRequest(url: URL(string: "https://example.com/users")!)

        #expect(rule.matches(request1))
        #expect(rule.matches(request2))
        #expect(!rule.matches(request3))
    }

    @Test("Regex valid pattern match")
    func testRegexValidPattern() async throws {
        let rule = MatchRule.regex("https://.*\\.com/api/\\d+")
        let request1 = URLRequest(url: URL(string: "https://example.com/api/123")!)
        let request2 = URLRequest(url: URL(string: "https://test.com/api/456")!)
        let request3 = URLRequest(url: URL(string: "https://example.com/api/users")!)

        #expect(rule.matches(request1))
        #expect(rule.matches(request2))
        #expect(!rule.matches(request3))
    }

    @Test("Regex invalid pattern returns false")
    func testRegexInvalidPattern() async throws {
        let rule = MatchRule.regex("[invalid(regex")
        let request = URLRequest(url: URL(string: "https://example.com/api")!)
        #expect(!rule.matches(request))
    }

    @Test("Query parameter key and value match")
    func testQueryParameterKeyAndValue() async throws {
        let rule = MatchRule.queryParameter(key: "userId", value: "123")
        let request1 = URLRequest(url: URL(string: "https://example.com/api?userId=123")!)
        let request2 = URLRequest(url: URL(string: "https://example.com/api?userId=456")!)

        #expect(rule.matches(request1))
        #expect(!rule.matches(request2))
    }

    @Test("Rule name generation")
    func testRuleName() async throws {
        #expect(MatchRule.hostName("example.com").ruleName == "Rule_Host Name: example.com")
        #expect(MatchRule.url("https://example.com").ruleName == "Rule_URL: https://example.com")
        #expect(MatchRule.path("/api").ruleName == "Rule_Path: /api")
        #expect(MatchRule.endPath("users").ruleName == "Rule_End Path: users")
        #expect(MatchRule.subPath("api").ruleName == "Rule_Sub Path: api")
        #expect(MatchRule.regex(".*").ruleName == "Rule_Regex: .*")
        #expect(MatchRule.queryParameter(key: "id", value: "value").ruleName == "Rule_Query Parameter")
    }
}
