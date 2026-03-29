//
//  Test.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 29/03/26.
//

public final class Test: @unchecked Sendable {
    
    func setupMock(for rule: MatchRule, response: HTTPResponse) {
        let mock = Mock(rule: rule, response: response)
        MockServer.shared.register(mock)
    }
    
    func tearDown() {
        MockServer.shared.clear()
    }
    
}
