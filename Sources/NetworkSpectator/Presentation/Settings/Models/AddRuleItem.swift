//
//  AddRuleItem.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 23/12/25.
//

import Foundation
import NetworkSpectatorCore
import NetworkSpectatorLogging

struct AddRuleItem: Identifiable {
    enum Rule: String, CaseIterable, Identifiable {
        case url = "URL"
        case host = "Host"
        case path = "Path"
        case endPath = "EndPath"
        case pathComponent = "Path Component"

        var id: Self { self }

        var title: String {
            rawValue
        }
    }

    let id: UUID
    let text: String
    let response: String
    let statusCode: String
    let headers: String
    let delay: String
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
         delay: String = "",
         method: HTTPMethod = .GET,
         rule: Rule,
         isMock: Bool,
         saveLocally: Bool = false) {
        self.id = id
        self.text = text
        self.response = response
        self.statusCode = statusCode
        self.headers = headers
        self.delay = delay
        self.method = method
        self.rule = rule
        self.isMock = isMock
        self.saveLocally = saveLocally
        self.showDelete = false
    }

    init?(mock: Mock) {
        id = mock.id
        method = mock.method

        switch mock.rule {
        case .url(let value):
            text = value
            rule = .url
        case .path(let value):
            text = value
            rule = .path
        case .endPath(let value):
            text = value
            rule = .endPath
        case .subPath(let value):
            text = value
            rule = .pathComponent
        default:
            return nil
        }

        response = mock.response.responseData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        statusCode = String(mock.response.statusCode)
        headers = mock.response.headers.map { "\($0.key)===\($0.value)" }.joined(separator: "\n")
        delay = String(format: "%g", mock.response.responseTime)
        isMock = true
        saveLocally = mock.saveLocally
        showDelete = true
    }

    init?(exclusion: LoggingExclusionRule) {
        id = exclusion.id
        method = exclusion.method

        switch exclusion.rule {
        case .url(let value):
            text = value
            rule = .url
        case .path(let value):
            text = value
            rule = .path
        case .endPath(let value):
            text = value
            rule = .endPath
        case .subPath(let value):
            text = value
            rule = .pathComponent
        default:
            return nil
        }

        response = ""
        statusCode = ""
        headers = ""
        delay = ""
        isMock = false
        saveLocally = exclusion.saveLocally
        showDelete = true
    }
}
