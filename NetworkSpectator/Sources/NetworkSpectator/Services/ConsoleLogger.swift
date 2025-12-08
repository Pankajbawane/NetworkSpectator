//
//  ConsoleLogger.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 08/12/25.
//

struct ConsoleLogger {
    
    private let enabled: Bool
    
    init(enabled: Bool) {
        self.enabled = enabled
    }
    
    func log(_ level: LogLevel, _ logItem: LogItem) {
        log(level == .initiated ? .initatedLine : .finishedLine)
        log(.url, logItem.method + " " + logItem.url)
        log(.request, logItem.requestBody)
        log(.headers, logItem.headers)
        if level == .finished {
            logger.log(.response, logItem.responseBody)
        }
        log(.line)
    }
    
    func log(_ type: LogType, _ message: String = "") {
        guard enabled else { return }
        let printMessage = message.isEmpty ? "" : "\n\(message)"
        print(type.title, printMessage)
    }
}

enum LogLevel {
    case initiated
    case finished
}

enum LogType {
    case none
    case url
    case request
    case response
    case headers
    case line
    case initatedLine
    case finishedLine
    
    var title: String {
        
        switch self {
        case .url: return "URL:"
        case .request: return "REQUEST:"
        case .response: return "RESPONSE:"
        case .headers: return "HEADERS:"
        case .none: return ""
        case .line: return "================================================================================"
        case .initatedLine: return "=============================REQUEST INITIATED=================================="
        case .finishedLine: return "=============================REQUEST FINISHED==================================="
        }
    }
}
