//
//  NetworkLogStorable.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 29/03/26.
//

import Foundation

protocol LogItemStorable: Sendable {
    func logging(_ item: LogItem)
}

struct LogItemStoreUI: LogItemStorable {
    func logging(_ item: LogItem) {
        DebugPrint.log(item)
        Task {
            await NetworkLogStore.shared.add(item)
        }
    }
}

struct LogItemStoreTests: LogItemStorable {
    func logging(_ item: LogItem) {
        Task {
            await TestLogStore.shared.add(item)
        }
    }
}
