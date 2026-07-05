//
//  NetworkItemLogger.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 29/03/26.
//

import Foundation
import NetworkSpectatorCore
import NetworkSpectatorMocking

struct UIItemLogger: NetworkItemLogger {
    
    typealias T = Mock
    
    func responseIfMocked(_ urlRequest: URLRequest) -> Mock? {
        MockServer.shared.responseIfMocked(urlRequest)
    }
    
    var isEnabled: Bool {
        NetworkLogStore.shared.currentSession() != nil
    }

    func shouldIgnore(_ request: URLRequest) -> Bool {
        LoggingExclusionManager.shared.shouldExcludeLogging(request)
    }

    func logging(_ item: LogItem) {
        guard let session = NetworkLogStore.shared.currentSession() else { return }
        DebugPrint.log(item)
        Task(priority: .userInitiated) {
            await NetworkLogStore.shared.add(item, session: session)
        }
    }
}
