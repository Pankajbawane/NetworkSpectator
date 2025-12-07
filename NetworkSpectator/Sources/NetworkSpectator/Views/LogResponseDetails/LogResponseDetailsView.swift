//
//  LogResponseDetailsView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogResponseDetailsView: View {
    
    @Binding var item: LogItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.responseBody)
                .font(.caption)
            Spacer()
        }
        .padding(.horizontal)
    }
}
