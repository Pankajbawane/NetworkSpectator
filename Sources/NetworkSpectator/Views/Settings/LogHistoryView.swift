//
//  LogHistoryView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 03/03/26.
//

import SwiftUI

struct LogHistoryView: View {
    
    let storage: LogHistoryStorage
    @State var logs: [HistoryItem]
    @State var presentSheet: Bool = false
    @State var key = ""
    
    init() {
        storage = LogHistoryStorage()
        logs = storage.listKeys()
        key = logs[0].key
    }
    
    var body: some View {
        
        List(logs, id: \.key) { log in
            Button(log.key) {
                presentSheet = true
                key = log.key
            }
        }.sheet(isPresented: $presentSheet) {
            let items = storage.retrieve(forKey: key)
            RootView(isLoggingLive: false, logsHistory: items)
        }
    }
}
