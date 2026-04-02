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
    
    private static let jsonLineRegex = /"[^"]*"|-?\d+\.?\d*([eE][+-]?\d+)?|[:\[\]{},]|true|false|null|\s+|[^\s":\[\]{},]+/
    
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
            for string in lines {
                let text = isJSON ? styledSegments(from: string) : Text(string)
                texts.append(text)
            }
            return texts
        }.value
        
        texts = formattedTexts
        isProcessing = false
    }
    
    func styledSegments(from input: String) -> Text {
        let matches = input.matches(of: Self.jsonLineRegex)

        var result = Text("")
        var expectValue = false

        for match in matches {
            let segment = String(match.output.0)

            let attribute: JSONAttributeType = {
                if segment.hasPrefix("\"") {
                    return expectValue ? .stringValue : .key
                } else if segment == ":" {
                    return .colon
                } else if "[]{}".contains(segment) {
                    return .bracketOrBrace
                } else if segment == "," {
                    return .comma
                } else if segment.first?.isNumber == true || (segment.first == "-" && segment.count > 1) {
                    return .number
                } else if segment == "true" || segment == "false" {
                    return .boolean
                } else if segment == "null" {
                    return .null
                } else {
                    return .whitespaceOrOther
                }
            }()

            result = result + Text(segment).foregroundColor(attribute.color).font(attribute.font)

            switch attribute {
            case .colon:
                expectValue = true
            case .comma, .stringValue, .number, .boolean, .null:
                expectValue = false
            default:
                break
            }
        }

        return result
    }
}

extension ResponseBodyLineView {
    private enum JSONAttributeType {
        case key, stringValue, number, boolean, null, colon, bracketOrBrace, comma, whitespaceOrOther
        
        var color: Color {
            switch self {
            case .key: return Color(red: 0.7490196078431373, green: 0.5215686274509804, blue: 0.3333333333333333)
            case .stringValue: return Color(red: 0.9882352941176471, green: 0.41568627450980394, blue: 0.36470588235294116)
            case .number: return Color.yellow
            case .boolean, .null: return Color(red: 0.9882352941176471, green: 0.37254901960784315, blue: 0.6392156862745098)
            case .colon, .bracketOrBrace, .comma: return .primary
            case .whitespaceOrOther: return .secondary
            }
        }
        
        var font: Font {
            switch self {
            case .colon, .bracketOrBrace, .comma:
                return .callout.monospaced()
            default:
                return .callout.monospaced().bold()
            }
        }
    }
}

