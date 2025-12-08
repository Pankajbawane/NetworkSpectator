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
        URLProtocol.property(forKey: taskCacheKey, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let thisRequest = request as? NSMutableURLRequest {
            URLProtocol.setProperty(true, forKey: Self.taskCacheKey, in: thisRequest)
        }
        
        let log = LogItem.fromRequest(request)
        logger.log(.initiated, log)
        Task {
            await NetworkLogManager.shared.add(log)
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)

        sessionTask = session.dataTask(with: request) { data, response, error in
            let finalUpdatedLog = log.withResponse(response: response, data: data, error: error)
            logger.log(.finished, finalUpdatedLog)
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

        sessionTask?.resume()
    }

    override func stopLoading() {
        sessionTask?.cancel()
    }
}
