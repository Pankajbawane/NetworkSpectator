import Testing
import Foundation
@testable import NetworkSpectator

// MARK: - MatchRule Tests
@Suite("MatchRule Tests")
struct MatchRuleTests {

    @Test("Host name exact match")
    func testHostNameExactMatch() async throws {
        let rule = MatchRule.hostName("example.com")
        let url = URL(string: "https://example.com/api/users")!
        #expect(rule.matches(url))
    }

    @Test("Host name case insensitive match")
    func testHostNameCaseInsensitive() async throws {
        let rule = MatchRule.hostName("EXAMPLE.COM")
        let url = URL(string: "https://example.com/api/users")!
        #expect(rule.matches(url))
    }

    @Test("Host name wildcard match")
    func testHostNameWildcard() async throws {
        let rule = MatchRule.hostName("*.example.com")
        let url1 = URL(string: "https://api.example.com/users")!
        let url2 = URL(string: "https://test.example.com/data")!
        let url3 = URL(string: "https://example.com/users")!

        #expect(rule.matches(url1))
        #expect(rule.matches(url2))
        #expect(!rule.matches(url3)) // Exact match should not work with wildcard
    }

    @Test("Host name no match")
    func testHostNameNoMatch() async throws {
        let rule = MatchRule.hostName("example.com")
        let url = URL(string: "https://different.com/api")!
        #expect(!rule.matches(url))
    }

    @Test("URL exact match")
    func testURLExactMatch() async throws {
        let rule = MatchRule.url("https://example.com/api/users")
        let url = URL(string: "https://example.com/api/users")!
        #expect(rule.matches(url))
    }

    @Test("URL wildcard match")
    func testURLWildcard() async throws {
        let rule = MatchRule.url("https://example.com/api/*")
        let url1 = URL(string: "https://example.com/api/users")!
        let url2 = URL(string: "https://example.com/api/posts")!
        let url3 = URL(string: "https://example.com/other/data")!

        #expect(rule.matches(url1))
        #expect(rule.matches(url2))
        #expect(!rule.matches(url3))
    }

    @Test("Path exact match")
    func testPathExactMatch() async throws {
        let rule = MatchRule.path("/api/users")
        let url = URL(string: "https://example.com/api/users")!
        #expect(rule.matches(url))
    }

    @Test("Path wildcard match")
    func testPathWildcard() async throws {
        let rule = MatchRule.path("/api/*")
        let url1 = URL(string: "https://example.com/api/users")!
        let url2 = URL(string: "https://example.com/api/posts")!
        let url3 = URL(string: "https://example.com/other")!

        #expect(rule.matches(url1))
        #expect(rule.matches(url2))
        #expect(!rule.matches(url3))
    }

    @Test("End path match")
    func testEndPathMatch() async throws {
        let rule = MatchRule.endPath("users")
        let url1 = URL(string: "https://example.com/api/users")!
        let url2 = URL(string: "https://example.com/v2/users")!
        let url3 = URL(string: "https://example.com/api/posts")!

        #expect(rule.matches(url1))
        #expect(rule.matches(url2))
        #expect(!rule.matches(url3))
    }

    @Test("Path component match")
    func testPathComponentMatch() async throws {
        let rule = MatchRule.pathComponent("api")
        let url1 = URL(string: "https://example.com/api/users")!
        let url2 = URL(string: "https://example.com/v1/api/posts")!
        let url3 = URL(string: "https://example.com/users")!

        #expect(rule.matches(url1))
        #expect(rule.matches(url2))
        #expect(!rule.matches(url3))
    }

    @Test("Regex valid pattern match")
    func testRegexValidPattern() async throws {
        let rule = MatchRule.regex("https://.*\\.com/api/\\d+")
        let url1 = URL(string: "https://example.com/api/123")!
        let url2 = URL(string: "https://test.com/api/456")!
        let url3 = URL(string: "https://example.com/api/users")!

        #expect(rule.matches(url1))
        #expect(rule.matches(url2))
        #expect(!rule.matches(url3))
    }

    @Test("Regex invalid pattern returns false")
    func testRegexInvalidPattern() async throws {
        let rule = MatchRule.regex("[invalid(regex")
        let url = URL(string: "https://example.com/api")!
        #expect(!rule.matches(url))
    }

    @Test("Query parameter key only match")
    func testQueryParameterKeyOnly() async throws {
        let rule = MatchRule.queryParameter(key: "userId")
        let url1 = URL(string: "https://example.com/api?userId=123")!
        let url2 = URL(string: "https://example.com/api?userId=456")!
        let url3 = URL(string: "https://example.com/api?other=value")!

        #expect(rule.matches(url1))
        #expect(rule.matches(url2))
        #expect(!rule.matches(url3))
    }

    @Test("Query parameter key and value match")
    func testQueryParameterKeyAndValue() async throws {
        let rule = MatchRule.queryParameter(key: "userId", value: "123")
        let url1 = URL(string: "https://example.com/api?userId=123")!
        let url2 = URL(string: "https://example.com/api?userId=456")!

        #expect(rule.matches(url1))
        #expect(!rule.matches(url2))
    }

    @Test("Query parameter no query string")
    func testQueryParameterNoQueryString() async throws {
        let rule = MatchRule.queryParameter(key: "userId")
        let url = URL(string: "https://example.com/api")!
        #expect(!rule.matches(url))
    }

    @Test("Rule name generation")
    func testRuleName() async throws {
        #expect(MatchRule.hostName("example.com").ruleName == "Host Name example.com")
        #expect(MatchRule.url("https://example.com").ruleName == "URL https://example.com")
        #expect(MatchRule.path("/api").ruleName == "Path /api")
        #expect(MatchRule.endPath("users").ruleName == "End Path users")
        #expect(MatchRule.pathComponent("api").ruleName == "Path Component api")
        #expect(MatchRule.regex(".*").ruleName == "Regex .*")
        #expect(MatchRule.queryParameter(key: "id").ruleName == "Query Parameter")
    }
}
