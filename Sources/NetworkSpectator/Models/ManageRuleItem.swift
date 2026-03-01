//
//  ManageRuleItem.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 27/02/26.
//

import Foundation

struct ManageRuleItem: Identifiable {
    let id: UUID
    let text: String

    init(id: UUID, text: String) {
        self.id = id
        self.text = text
    }

    init(mock: Mock) {
        id = mock.id
        text = mock.rule.ruleName
    }
    
    init(skipRequest: SkipRequestForLogging) {
        id = skipRequest.id
        text = skipRequest.rule.ruleName
    }
}
