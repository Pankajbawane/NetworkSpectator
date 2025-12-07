//
//  LogListItemView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogListItemView: View {
    
    @Binding var item: LogItem
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if item.isLoading {
                    Text("\(item.startTime.formatted(date: .numeric, time: .standard))")
                        .font(.caption)
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 5, height: 5)
                        .padding(.leading, 5)
                } else {
                    Text("\(item.startTime.formatted(date: .numeric, time: .standard)) - \( item.finishTime?.formatted(date: .omitted, time: .standard) ?? "")")
                        .font(.caption)
                }
                
            }
            Text("\(item.url)")
                .lineLimit(1)
                .font(.caption)
                .fontWeight(.medium)
        }
        .listRowSeparator(.hidden)
    }
}
