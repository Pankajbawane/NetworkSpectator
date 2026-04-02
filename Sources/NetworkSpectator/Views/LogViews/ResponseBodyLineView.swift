//
//  ResponseBodyLineView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 20/02/26.
//

import SwiftUI

struct ResponseBodyLineView: View {
    private let responseBody: String
    private let isJSON: Bool

    @State private var isProcessing = true
    @State private var texts: [Text] = []
    
    private static let jsonLineRegex = /"[^"]*"|-?[\d.eE+-]+|[\[\]{}:,]|(?:true|false|null)|\s+|\S+/
    
    init (responseBody: String, mimetype: String) {
        self.responseBody = responseBody
        isJSON = mimetype.lowercased().contains("json")
    }

    var body: some View {
        Group {
            if isProcessing {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(Array(texts.enumerated()), id: \.offset) { index, line in
                    line
                        .textSelection(.enabled)
                        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
            }
        }
        .task {
            await processContent()
        }
    }

    private func processContent() async {
        // Process on background task to avoid blocking UI
        let formattedTexts = await Task(priority: .userInitiated) {
            let lines = responseBody.components(separatedBy: .newlines)
            var texts: [Text] = []
            texts.reserveCapacity(lines.count + 1)
            for (i, string) in lines.enumerated() {
                let lineNumber: Text = Text("\(i + 1)".padding(toLength: 4,
                                                               withPad: " ",
                                                               startingAt: 0)).foregroundColor(.secondary.opacity(0.8)).font(.callout.monospaced())
                
                let text = isJSON ? styledSegments(from: string) : Text(string)
                texts.append(lineNumber + text)
            }
            return texts
        }.value
        
        texts = formattedTexts
        isProcessing = false
    }
    
    private func styledSegments(from input: String) -> Text {
        let matches = input.matches(of: Self.jsonLineRegex)

        var result = Text("")
        var expectValue = false

        for match in matches {
            let segment = String(match.output)
            let attribute = JSONAttributeType(segment: segment, expectingValue: expectValue)

            result = result + Text(segment).foregroundColor(attribute.color).font(attribute.font)

            if let next = attribute.expectsValueNext {
                expectValue = next
            }
        }

        return result
    }
}

extension ResponseBodyLineView {
    private enum JSONAttributeType {
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
            } else if "[]{}" .contains(segment) {
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
        
        var color: Color {
            switch self {
            case .key: return Color(red: 191/255.0, green: 133/255.0, blue: 85/255.0)
            case .stringValue: return Color(red: 252/255.0, green: 106/255.0, blue: 93/255.0)
            case .number: return Color.yellow
            case .boolean, .null: return Color(red: 252/255.0, green: 95/255.0, blue: 163/255.0)
            case .colon, .bracketOrBrace, .comma: return .primary
            case .whitespaceOrOther: return .secondary
            }
        }
        
        var font: Font {
            switch self {
            case .colon, .bracketOrBrace, .comma:
                return .callout.monospaced().bold()
            default:
                return .callout.monospaced()
            }
        }
        
        var expectsValueNext: Bool? {
            switch self {
            case .colon: return true
            case .comma, .stringValue, .number, .boolean, .null: return false
            default: return nil
            }
        }
    }
}
