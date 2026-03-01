//
//  ManageRuleItemTests.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 28/02/26.
//

import Testing
import Foundation
@testable import NetworkSpectator

@Suite("ManageRuleItem Tests")
struct ManageRuleItemTests {

    @Test("Init from Mock uses mock id and rule name")
    func testInitFromMock() async throws {
        let mock = Mock(rule: .url("https://example.com/api"), response: nil as Data?, statusCode: 200)
        let item = ManageRuleItem(mock: mock)

        #expect(item.id == mock.id)
        #expect(item.text == mock.rule.ruleName)
    }

    @Test("Init from SkipRequestForLogging uses skip request id and rule name")
    func testInitFromSkipRequest() async throws {
        let skipRequest = SkipRequestForLogging(rule: .hostName("analytics.com"), saveLocally: false)
        let item = ManageRuleItem(skipRequest: skipRequest)

        #expect(item.id == skipRequest.id)
        #expect(item.text == skipRequest.rule.ruleName)
    }
}
