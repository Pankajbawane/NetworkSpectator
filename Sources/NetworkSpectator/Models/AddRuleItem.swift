//
//  AddRuleItem.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 23/12/25.
//

import Foundation


struct AddRuleItem: Identifiable {
    typealias Rule = AddRuleItemView.Rule
    
        let id: UUID
        let text: String
        let response: String
        let statusCode: String
        let headers: String
        let rule: Rule
        let isMock: Bool

        init(id: UUID, text: String, response: String = "", statusCode: String = "", headers: String = "", rule: Rule, isMock: Bool) {
            self.id = id
            self.text = text
            self.response = response
            self.statusCode = statusCode
            self.headers = headers
            self.rule = rule
            self.isMock = isMock
        }

        init?(mock: Mock) {
            guard let matchRule = mock.rules.first else { return nil }
            self.id = mock.id

            switch matchRule {
            case .url(let value):
                self.text = value
                self.rule = .url
            case .path(let value):
                self.text = value
                self.rule = .path
            case .endPath(let value):
                self.text = value
                self.rule = .endPath
            case .pathComponent(let value):
                self.text = value
                self.rule = .pathComponent
            default:
                return nil
            }

            self.response = mock.response.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            self.statusCode = String(mock.statusCode)
            self.headers = mock.headers.map { "\($0.key)===\($0.value)" }.joined(separator: "\n")
            self.isMock = true
        }

        init?(skipRequest: SkipRequestForLogging) {
            guard let matchRule = skipRequest.rules.first else { return nil }
            self.id = skipRequest.id

            switch matchRule {
            case .url(let value):
                self.text = value
                self.rule = .url
            case .path(let value):
                self.text = value
                self.rule = .path
            case .endPath(let value):
                self.text = value
                self.rule = .endPath
            case .pathComponent(let value):
                self.text = value
                self.rule = .pathComponent
            default:
                return nil
            }

            self.response = ""
            self.statusCode = ""
            self.headers = ""
            self.isMock = false
        }
    }
