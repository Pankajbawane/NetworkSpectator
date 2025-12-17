//
//  LogListItemView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct LogListItemView: View {
    
    let item: LogItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(item.url)")
                    .lineLimit(1)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("\(item.startTime.formatted(date: .abbreviated, time: .standard)) \(!item.isLoading ? "| Response Time: \(item.responseTime, specifier: "%.2f") sec" : "")")
                        .font(.caption)
                    
                    Spacer()
                }
                
                if let error = item.errorLocalizedDescription {
                    Text("Error: \(error)")
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }
            }
            
            Spacer()
            
            if item.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 5, height: 5)
                    .padding(.leading, 5)
            }
        }
    }
}
