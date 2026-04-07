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
    @State private var texts: [(number: Text, line: Text)] = []
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
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
                    HStack(alignment: .firstTextBaseline) {
                        line.number
                            .textSelection(.disabled)
                        
                        line.line
                            .textSelection(.enabled)
                    }
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
            let textFont: Font
            #if os(iOS)
            textFont = .caption.monospaced()
            #else
            textFont = .callout.monospaced()
            #endif
            let lines = responseBody.components(separatedBy: .newlines)
            var texts: [(Text, Text)] = []
            texts.reserveCapacity(lines.count + 1)
            for (i, string) in lines.enumerated() {
                let lineNumber: Text = Text("\(i + 1)".padding(toLength: 4,
                                                               withPad: " ",
                                                               startingAt: 0)).foregroundColor(.secondary.opacity(0.8)).font(textFont)
                
                let text = isJSON ? styledSegments(from: string) : Text(string)
                texts.append((lineNumber, text))
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

            result = result + Text(segment).foregroundColor(attribute.color(colorScheme)).font(attribute.font)

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
        
        func color(_ scheme: ColorScheme) -> Color {
            switch self {
            case .key: return Color(red: 191/255.0, green: 133/255.0, blue: 85/255.0)
            case .stringValue: return Color(red: 252/255.0, green: 106/255.0, blue: 93/255.0)
            case .number: return scheme == .dark ? Color.yellow : Color.blue
            case .boolean, .null: return Color(red: 252/255.0, green: 95/255.0, blue: 163/255.0)
            case .colon, .bracketOrBrace, .comma: return .primary
            case .whitespaceOrOther: return .secondary
            }
        }
        
        var font: Font {
            let textFont: Font
            #if os(iOS)
            textFont = .caption.monospaced()
            #else
            textFont = .callout.monospaced()
            #endif
            switch self {
            case .colon, .bracketOrBrace, .comma:
                return textFont.bold()
            default:
                return textFont
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
