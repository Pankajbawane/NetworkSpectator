//
//  JSONBodyLineViewModel.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 04/07/26.
//

import Foundation

struct JSONBodyLineViewModel: Sendable {
    let responseBody: String
    let isJSON: Bool
    let processingID: Int

    init(responseBody: String, mimetype: String) {
        self.responseBody = responseBody
        isJSON = mimetype.lowercased().contains("json")
        processingID = Self.makeProcessingID(responseBody: responseBody, isJSON: isJSON)
    }

    func makeLines() async -> [Line] {
        let responseBody = responseBody
        let isJSON = isJSON

        return await Task.detached(priority: .userInitiated) {
            let strings = responseBody.components(separatedBy: .newlines)
            return strings.enumerated().map { index, string in
                Line(number: index + 1,
                     segments: Self.makeSegments(from: string, isJSON: isJSON))
            }
        }.value
    }

    private static func makeSegments(from input: String, isJSON: Bool) -> [Segment] {
        guard isJSON else {
            return [Segment(text: input, attribute: .plain)]
        }

        let jsonLineRegex = /"[^"]*"|-?[\d.eE+-]+|[\[\]{}:,]|(?:true|false|null)|\s+|\S+/
        var segments = [Segment]()
        var expectValue = false

        for match in input.matches(of: jsonLineRegex) {
            let text = String(match.output)
            let attribute = JSONAttributeType(segment: text, expectingValue: expectValue)
            segments.append(Segment(text: text, attribute: attribute))

            if let next = attribute.expectsValueNext {
                expectValue = next
            }
        }

        return segments
    }

    private static func makeProcessingID(responseBody: String, isJSON: Bool) -> Int {
        var hasher = Hasher()
        hasher.combine(responseBody)
        hasher.combine(isJSON)
        return hasher.finalize()
    }

    struct Line: Identifiable, Sendable {
        let id: Int
        let numberText: String
        let segments: [Segment]

        init(number: Int, segments: [Segment]) {
            id = number
            numberText = "\(number)".padding(toLength: 4, withPad: " ", startingAt: 0)
            self.segments = segments
        }
    }

    struct Segment: Sendable {
        let text: String
        let attribute: JSONAttributeType
    }

    enum JSONAttributeType: Sendable {
        case plain
        case key
        case stringValue
        case number
        case boolean
        case null
        case colon
        case bracketOrBrace
        case comma
        case whitespaceOrOther

        init(segment: String, expectingValue: Bool) {
            if segment.hasPrefix("\"") {
                self = expectingValue ? .stringValue : .key
            } else if segment == ":" {
                self = .colon
            } else if "[]{}".contains(segment) {
                self = .bracketOrBrace
            } else if segment == "," {
                self = .comma
            } else if segment.first?.isNumber == true || (segment.first == "-" && segment.count > 1) {
                self = .number
            } else if segment == "true" || segment == "false" {
                self = .boolean
            } else if segment == "null" {
                self = .null
            } else {
                self = .whitespaceOrOther
            }
        }

        var expectsValueNext: Bool? {
            switch self {
            case .colon:
                return true
            case .comma, .stringValue, .number, .boolean, .null:
                return false
            case .plain, .key, .bracketOrBrace, .whitespaceOrOther:
                return nil
            }
        }
    }
}
