//
//  JSONBodyLineView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 20/02/26.
//

import SwiftUI

struct JSONBodyLineView: View {
    private let viewModel: JSONBodyLineViewModel

    @State private var isProcessing = true
    @State private var lines: [JSONBodyLineViewModel.Line] = []
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    init(responseBody: String, mimetype: String) {
        viewModel = JSONBodyLineViewModel(responseBody: responseBody, mimetype: mimetype)
    }

    var body: some View {
        Group {
            if isProcessing {
                loadingView
            } else {
                lineList
            }
        }
        .task(id: viewModel.processingID) {
            await processContent()
        }
    }

    private var loadingView: some View {
        HStack {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var lineList: some View {
        List(lines) { line in
            HStack(alignment: .firstTextBaseline) {
                Text(line.numberText)
                    .foregroundColor(.secondary.opacity(0.8))
                    .font(textFont)
                    .textSelection(.disabled)

                styledText(from: line.segments)
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

    private var textFont: Font {
        #if os(iOS)
        return .caption.monospaced()
        #else
        return .callout.monospaced()
        #endif
    }

    private func processContent() async {
        isProcessing = true
        let preparedLines = await viewModel.makeLines()
        guard !Task.isCancelled else { return }
        lines = preparedLines
        isProcessing = false
    }

    private func styledText(from segments: [JSONBodyLineViewModel.Segment]) -> Text {
        segments.reduce(Text("")) { result, segment in
            result + Text(segment.text)
                .foregroundColor(segment.attribute.color(colorScheme))
                .font(segment.attribute.font(textFont))
        }
    }
}

private extension JSONBodyLineViewModel.JSONAttributeType {
    func color(_ scheme: ColorScheme) -> Color {
        switch self {
        case .plain:
            return .primary
        case .key:
            return Color(red: 191/255.0, green: 133/255.0, blue: 85/255.0)
        case .stringValue:
            return Color(red: 252/255.0, green: 106/255.0, blue: 93/255.0)
        case .number:
            return scheme == .dark ? Color.yellow : Color.blue
        case .boolean, .null:
            return Color(red: 252/255.0, green: 95/255.0, blue: 163/255.0)
        case .colon, .bracketOrBrace, .comma:
            return .primary
        case .whitespaceOrOther:
            return .secondary
        }
    }

    func font(_ baseFont: Font) -> Font {
        switch self {
        case .colon, .bracketOrBrace, .comma:
            return baseFont.bold()
        case .plain, .key, .stringValue, .number, .boolean, .null, .whitespaceOrOther:
            return baseFont
        }
    }
}
