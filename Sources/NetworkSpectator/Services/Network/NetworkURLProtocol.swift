//
//  NetworkURLProtocol.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 22/06/25.
//

import Foundation

final internal class NetworkURLProtocol: URLProtocol {
    
    private var sessionTask: URLSessionDataTask?
    private static let taskCacheKey = "TRACK_CACHED_TASK_KEY"

    override class func canInit(with request: URLRequest) -> Bool {
        // Avoid intercepting requests twice
        if URLProtocol.property(forKey: taskCacheKey, in: request) != nil {
            return false
        }

        // If the request is ignored for logging using match rules, don't intercept
        if SkipRequestForLoggingHandler.shared.isEnabled,
           let url = request.url,
           SkipRequestForLoggingHandler.shared.shouldSkipLogging(url) {
            return false
        }

        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return canInit(with: request)
    }
    
    override func startLoading() {
        guard let thisRequest = request as? NSMutableURLRequest else {
            super.startLoading()
            return
        }
        
        URLProtocol.setProperty(true, forKey: Self.taskCacheKey, in: thisRequest)
        let log = LogItem.fromRequest(request)
        DebugPrint.log(log)
        Task {
            await NetworkLogManager.shared.add(log)
        }
        
        let completion: (Data?, URLResponse?, Error?) -> Void = { data, response, error in
            let finalUpdatedLog = log.withResponse(response: response, data: data, error: error)
            DebugPrint.log(finalUpdatedLog)
            Task {
                await NetworkLogManager.shared.add(finalUpdatedLog)
            }

            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response {
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
        
        // If the request is mocked using match rules, return mocked response.
        if let mock = MockServer.shared.responseIfMocked(request) {
            completion(mock.response, mock.urlResponse(request), mock.error)
            return
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)

        sessionTask = session.dataTask(with: thisRequest as URLRequest) { data, response, error in
            completion(data, response, error)
        }

        sessionTask?.resume()
    }

    override func stopLoading() {
        sessionTask?.cancel()
        sessionTask = nil
    }
}
