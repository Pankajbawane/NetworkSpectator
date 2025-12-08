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
        let updatedLog = initialLog.build(request: request)
        logger.log(.initiated, updatedLog)
        Task {
            await NetworkLogManager.shared.add(updatedLog)
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)

        sessionTask = session.dataTask(with: thisRequest as URLRequest) { data, response, error in
            let finalUpdatedLog = updatedLog.build(response: response, data: data, error: error)
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
