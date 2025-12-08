//
//  LogItem.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import Foundation

struct LogItem: Identifiable {
    let id = UUID()
    let startTime: Date = Date()
    let url: String
    
    var method: String = ""
    var headers: String = ""
    var statusCode: Int = 0
    var requestBody: String = ""
    var responseBody: String = ""
    var responseHeaders: String = ""
    private(set) var responseTime: TimeInterval = 0
    var mimetype: String?
    var textEncodingName: String?
    var error: Error?
    var finishTime: Date? {
        didSet {
            if let finishTime {
                responseTime = finishTime.timeIntervalSince(startTime)
                isLoading = false
            }
        }
    }
    var isLoading: Bool = true
    
    var host: String {
        guard let urlComponents = URLComponents(string: url) else { return url }
        return urlComponents.host ?? url
    }
}

extension LogItem {
    func build(request: URLRequest) -> LogItem {
        var log = self
        log.method = request.httpMethod ?? ""
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            log.headers = headers.prettyPrintedJSON
        }

        if let body = request.httpBody {
            if let json = try? JSONSerialization.jsonObject(with: body, options: []),
               let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
               let pretty = String(data: data, encoding: .utf8) {
                log.requestBody = pretty
            } else if let string = String(data: body, encoding: .utf8) {
                log.requestBody = string
            }
        }
        
        return log
    }
    
    func build(response: URLResponse?, data: Data?, error: Error?) -> LogItem {
        var log = self
        if let httpResponse = response as? HTTPURLResponse {
            log.statusCode = httpResponse.statusCode
            log.responseHeaders = httpResponse.allHeaderFields.prettyPrintedHeaders
            log.mimetype = httpResponse.mimeType
            log.textEncodingName = httpResponse.textEncodingName
        }
        
        if let data = data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
               let pretty = String(data: jsonData, encoding: .utf8) {
                log.responseBody = pretty
            } else if let string = String(data: data, encoding: .utf8) {
                log.responseBody = string
            }
        }
        log.error = error
        log.finishTime = Date()
        
        return log
    }
}
