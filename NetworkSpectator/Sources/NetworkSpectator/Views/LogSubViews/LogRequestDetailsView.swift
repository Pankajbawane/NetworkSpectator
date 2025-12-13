//
//  Untitled.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogRequestDetailsView: View {
    
    @Binding var item: LogItem
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal) {
                Text(item.requestBody)
                    .font(.caption)
                    .textSelection(.enabled)
                    .padding(6)
                    .cornerRadius(4)
                    .contextMenu {
                        Button("Copy", action: {
                            #if canImport(UIKit)
                            UIPasteboard.general.string = item.responseBody
                            #elseif canImport(AppKit)
                            NSPasteboard.general.setString(item.responseBody, forType: .string)
                            #endif
                        })
                    }
            }
            Spacer()
        }
    }
}
