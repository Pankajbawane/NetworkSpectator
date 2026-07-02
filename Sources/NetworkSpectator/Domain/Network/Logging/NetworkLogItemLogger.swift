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
        guard let session = NetworkLogStore.shared.currentSession() else { return }
        DebugPrint.log(item)
        Task(priority: .userInitiated) {
            await NetworkLogStore.shared.add(item, session: session)
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
