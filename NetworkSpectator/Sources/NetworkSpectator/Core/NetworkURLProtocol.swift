//
//  NetworkURLProtocol.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 22/06/25.
//

import Foundation

final internal class NetworkURLProtocol: URLProtocol {
    private var sessionTask: URLSessionDataTask?
    private static let taskCacheKey = "TRACKED_TASK"

    override class func canInit(with request: URLRequest) -> Bool {
        // Avoid intercepting requests twice
        URLProtocol.property(forKey: taskCacheKey, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let thisRequest = request as? NSMutableURLRequest else {
            super.startLoading()
            return
        }
        URLProtocol.setProperty(true, forKey: Self.taskCacheKey, in: thisRequest)
        
        let initialLog = LogItem(url: request.url?.absoluteString ?? "")
        let updatedLog = initialLog.build(request: thisRequest)
        Task {
            await NetworkLogManager.shared.add(updatedLog)
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)

        sessionTask = session.dataTask(with: thisRequest as URLRequest) { data, response, error in
            let random = Int.random(in: 0..<5)
            let finalUpdatedLog = updatedLog.build(response: response, data: data, error: error)
            Task {
                await NetworkLogManager.shared.add(finalUpdatedLog)
            }

            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response = response {
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data = data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }

        sessionTask?.resume()
    }

    override func stopLoading() {
        sessionTask?.cancel()
    }
    
    private func logger(log: inout LogItem, request: NSMutableURLRequest) {
        print("Logging Request: \(request.httpMethod) \(request.url?.absoluteString ?? "")")
        log.method = request.httpMethod
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("Logging Request Headers:\n\(headers.prettyPrintedJSON)")
            log.headers = headers.prettyPrintedJSON
        }

        if let body = request.httpBody {
            if let json = try? JSONSerialization.jsonObject(with: body, options: []),
               let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
               let pretty = String(data: data, encoding: .utf8) {
                print("Logging Request Body:\n\(pretty)")
                log.requestBody = pretty
            } else if let string = String(data: body, encoding: .utf8) {
                print("Logging Request Body (raw):\n\(string)")
                log.requestBody = string
            }
        }
    }
    
    private func logger(log: LogItem, response: URLResponse?, data: Data?, error: Error?) -> LogItem {
        var log = log
        if let httpResponse = response as? HTTPURLResponse {
            print("Logging Response Headers:\n\(httpResponse.allHeaderFields.prettyPrintedHeaders)" as Any)
            log.statusCode = httpResponse.statusCode
            log.responseHeaders = httpResponse.allHeaderFields.prettyPrintedHeaders
            log.mimetype = httpResponse.mimeType
            log.textEncodingName = httpResponse.textEncodingName
        }
        
        if let data = data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
               let pretty = String(data: jsonData, encoding: .utf8) {
                print("Logging Response Body:\n\(pretty)")
                log.responseBody = pretty
            } else if let string = String(data: data, encoding: .utf8) {
                print("Logging Response Body (raw):\n\(string)")
                log.responseBody = string
            }
        }
        log.error = error
        log.finishTime = Date()
        
        return log
    }
}
