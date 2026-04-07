//
//  NetworkItemLogger.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 29/03/26.
//

import Foundation

protocol NetworkItemLogger: Sendable {
    func logging(_ item: LogItem)
}

struct UIItemLogger: NetworkItemLogger {
    func logging(_ item: LogItem) {
        DebugPrint.log(item)
        Task {
            await NetworkLogStore.shared.add(item)
        }
    }
}

struct TestItemLogger: NetworkItemLogger {
    let loggingEnabled: Bool

    func logging(_ item: LogItem) {
        guard loggingEnabled else { return }
        // Implement logging.
    }
}
