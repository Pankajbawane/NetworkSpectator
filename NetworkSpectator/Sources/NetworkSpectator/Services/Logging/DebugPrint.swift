//
//  DebugPrint.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 08/12/25.
//

struct DebugPrint {
    
    private let enabled: Bool
    nonisolated(unsafe) static var shared: DebugPrint = .init(enabled: true)
    
    init(enabled: Bool) {
        // DEBUG check to ensure logs are printed only while debugging.
        #if DEBUG
        self.enabled = enabled
        #else
        self.enabled = false
        #endif
    }
    
    fileprivate func log(_ logItem: LogItem) {
        // DEBUG check to ensure logs are printed only while debugging.
        #if DEBUG
        guard enabled else { return }
        log(logItem.isLoading ? .initatedLine : .finishedLine)
        log(.url, logItem.method + " " + logItem.url)
        if !logItem.requestBody.isEmpty {
            log(.request, logItem.requestBody)
        }
        if !logItem.headers.isEmpty {
            log(.headers, logItem.headers)
        }
        if !logItem.isLoading {
            log(.response, logItem.responseBody)
        }
        log(.endline)
        #endif
    }
    
    fileprivate func log(_ type: LogComponent = .none, _ message: String = "") {
        // DEBUG check to ensure logs are printed only while debugging.
        #if DEBUG
        guard enabled else { return }
        let printMessage = message.isEmpty ? "" : "\n\(message)"
        print(type.title, printMessage)
        #endif
    }
}

// MARK: - Convinience methods.
extension DebugPrint {
    static func log(_ logItem: LogItem) {
        shared.log(logItem)
    }
    
    static func log(_ message: String) {
        shared.log(.none, message)
    }
}

fileprivate enum LogComponent {
    case none
    case url
    case request
    case response
    case headers
    case endline
    case initatedLine
    case finishedLine
    
    var title: String {
        
        switch self {
        case .url: return "• URL:"
        case .request: return "• REQUEST:"
        case .response: return "• RESPONSE:"
        case .headers: return "• HEADERS:"
        case .none: return ""
        case .endline: return "======================================END======================================="
        case .initatedLine: return "=============================REQUEST INITIATED=================================="
        case .finishedLine: return "=============================REQUEST COMPLETED==================================="
        }
    }
}
