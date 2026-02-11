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
        let saveLocally: Bool

        init(id: UUID,
             text: String,
             response: String = "",
             statusCode: String = "",
             headers: String = "",
             rule: Rule,
             isMock: Bool,
             saveLocally: Bool = false) {
            self.id = id
            self.text = text
            self.response = response
            self.statusCode = statusCode
            self.headers = headers
            self.rule = rule
            self.isMock = isMock
            self.saveLocally = saveLocally
        }

        init?(mock: Mock) {
            self.id = mock.id

            switch mock.rule {
            case .url(let value):
                self.text = value
                self.rule = .url
            case .path(let value):
                self.text = value
                self.rule = .path
            case .endPath(let value):
                self.text = value
                self.rule = .endPath
            case .subPath(let value):
                self.text = value
                self.rule = .pathComponent
            default:
                return nil
            }

            self.response = mock.response.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            self.statusCode = String(mock.statusCode)
            self.headers = mock.headers.map { "\($0.key)===\($0.value)" }.joined(separator: "\n")
            self.isMock = true
            self.saveLocally = mock.saveLocally
        }

        init?(skipRequest: SkipRequestForLogging) {
            self.id = skipRequest.id

            switch skipRequest.rule {
            case .url(let value):
                self.text = value
                self.rule = .url
            case .path(let value):
                self.text = value
                self.rule = .path
            case .endPath(let value):
                self.text = value
                self.rule = .endPath
            case .subPath(let value):
                self.text = value
                self.rule = .pathComponent
            default:
                return nil
            }

            self.response = ""
            self.statusCode = ""
            self.headers = ""
            self.isMock = false
            self.saveLocally = skipRequest.saveLocally
        }
    }
