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
        let showDelete: Bool
        let method: HTTPMethod

        init(id: UUID,
             text: String,
             response: String = "",
             statusCode: String = "",
             headers: String = "",
             method: HTTPMethod = .GET,
             rule: Rule,
             isMock: Bool,
             saveLocally: Bool = false) {
            self.id = id
            self.text = text
            self.response = response
            self.statusCode = statusCode
            self.headers = headers
            self.method = method
            self.rule = rule
            self.isMock = isMock
            self.saveLocally = saveLocally
            self.showDelete = false
        }

        init?(mock: Mock) {
            self.id = mock.id
            self.method = mock.method

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

            self.response = mock.response.responseData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            self.statusCode = String(mock.response.statusCode)
            self.headers = mock.response.headers.map { "\($0.key)===\($0.value)" }.joined(separator: "\n")
            self.isMock = true
            self.saveLocally = mock.saveLocally
            self.showDelete = true
        }

        init?(skipRequest: LogSkipRequest) {
            self.id = skipRequest.id
            self.method = .GET

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
            self.showDelete = true
        }
    }
