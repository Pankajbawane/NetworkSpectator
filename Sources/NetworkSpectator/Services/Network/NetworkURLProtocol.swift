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
           SkipRequestForLoggingHandler.shared.shouldSkipLogging(request) {
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
        guard let thisRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            super.startLoading()
            return
        }
        
        URLProtocol.setProperty(true, forKey: Self.taskCacheKey, in: thisRequest)

        // Capture the HTTP body if it's provided as a stream so our logger can see it
        captureHTTPBodyIfNeeded(on: thisRequest)
        
        // If the request is mocked.
        let mock = MockServer.shared.responseIfMocked(thisRequest as URLRequest)

        // Log the request including headers and body (if any)
        let log = LogItem.fromRequest(thisRequest as URLRequest, mock?.id)
        DebugPrint.log(log)
        Task {
            DebugPrint.log(log)
            await NetworkLogStore.shared.add(log)
        }
        
        let completion: (Data?, URLResponse?, Error?) -> Void = { data, response, error in
            let finalUpdatedLog = log.withResponse(response: response, data: data, error: error)
            Task {
                DebugPrint.log(finalUpdatedLog)
                await NetworkLogStore.shared.add(finalUpdatedLog)
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
        if let mock {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + mock.delay) {
                completion(mock.response, mock.urlResponse(thisRequest as URLRequest), mock.error)
            }
            return
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)

        sessionTask = session.dataTask(with: thisRequest as URLRequest) { data, response, error in
            completion(data, response, error)
        }

        sessionTask?.resume()
    }

    private func captureHTTPBodyIfNeeded(on request: NSMutableURLRequest) {
        if let body = request.httpBody, !body.isEmpty {
            return
        }

        guard let stream = request.httpBodyStream else {
            return
        }

        let data = readData(from: stream)

        // Replace the stream so the forwarded request can still send the body
        request.httpBodyStream = InputStream(data: data)

        // Set httpBody so our logger can read it easily
        request.httpBody = data
    }

    private func readData(from stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }

        let bufferSize = 16 * 1024
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }

        return data
    }

    override func stopLoading() {
        sessionTask?.cancel()
        sessionTask = nil
    }
}
