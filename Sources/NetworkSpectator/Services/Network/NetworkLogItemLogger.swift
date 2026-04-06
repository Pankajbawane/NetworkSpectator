//
//  NetworkLogItemLogger.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 29/03/26.
//

import Foundation

protocol LogItemLogger: Sendable {
    func logging(_ item: LogItem)
}

struct UILogItemLogger: LogItemLogger {
    func logging(_ item: LogItem) {
        DebugPrint.log(item)
        Task {
            await NetworkLogStore.shared.add(item)
        }
    }
}

struct TestLogItemLogger: LogItemLogger {
    func logging(_ item: LogItem) {
        guard NetworkSpectator.Test.isLoggingEnabled else {
            return
        }
        Task {
            await TestLogStore.shared.add(item)
        }
    }
}
