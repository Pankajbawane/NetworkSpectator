//
//  Test.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 29/03/26.
//

public final class Test: @unchecked Sendable {
    
    static func enableTestMode() {
        NetworkURLProtocol.logger = LogItemStoreTests()
        NetworkInterceptor.shared.enable()
    }
    
    static func setupResponse(for rule: MatchRule, response: HTTPResponse) {
        let mock = Mock(rule: rule, response: response)
        MockServer.shared.register(mock)
    }
    
    static func tearDown() {
        MockServer.shared.clear()
    }
    
}
