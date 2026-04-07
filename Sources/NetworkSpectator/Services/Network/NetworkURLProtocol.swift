//
//  NetworkURLProtocol.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 22/06/25.
//

import Foundation
import os

final class NetworkURLProtocol: URLProtocol, @unchecked Sendable {
    
    private var sessionTask: URLSessionDataTask?
    private var mockTask: Task<Void, Never>?
    private let protectedLog: OSAllocatedUnfairLock<LogItem>
    private static let taskCacheKey = "NETWORKSPECTATOR_TRACK_CACHED_TASK_KEY"
    
    private static let _logger = OSAllocatedUnfairLock<any NetworkItemLogger>(
        initialState: UIItemLogger()
    )
    static var logger: any NetworkItemLogger {
        get { _logger.withLock { $0 } }
        set { _logger.withLock { $0 = newValue } }
    }
    
    private static let _mockServer = OSAllocatedUnfairLock<MockServer>(
        initialState: .shared
    )
    static var mockServer: MockServer {
        get { _mockServer.withLock { $0 } }
        set { _mockServer.withLock { $0 = newValue } }
    }
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: (any URLProtocolClient)?) {
        // Capture the HTTP body if it's provided
        let urlRequest = Self.captureHTTPBodyIfNeeded(request)
        protectedLog = OSAllocatedUnfairLock(initialState: LogItem.fromRequest(urlRequest))
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        
    }

    override class func canInit(with request: URLRequest) -> Bool {
        // Avoid intercepting requests twice
        if URLProtocol.property(forKey: taskCacheKey, in: request) != nil {
            return false
        }

        // If the request is ignored for logging using match rules, don't intercept
        if LogSkipManager.shared.isEnabled,
           LogSkipManager.shared.shouldSkipLogging(request) {
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
        
        // If the request is mocked.
        let mock = Self.mockServer.responseIfMocked(request)

        // Log the request including headers and body (if any)
        let requestLog = protectedLog.withLock { log in
            log = log.withMockID(mock?.id)
            return log
        }
        logging(requestLog)
        
        let completion: @Sendable (Data?, URLResponse?, Error?) -> Void = { [weak self] data, response, error in
            guard let self else { return }
            let responseLog = self.protectedLog.withLock { log in
                log = log.withResponse(response: response, data: data, error: error)
                return log
            }
            self.logging(responseLog)

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
            let urlRequest = thisRequest as URLRequest
            mockTask = Task {
                do {
                    try await Task.sleep(for: .seconds(mock.response.responseTime))
                    completion(mock.response.responseData,
                               mock.urlResponse(urlRequest),
                               mock.response.error)
                } catch {
                    // Handle in stopLoading()
                }
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
    
    override func stopLoading() {
        let cancelledLog: LogItem? = protectedLog.withLock { log in
            guard log.finishTime == nil else { return nil }
            return log.withResponse(response: nil, data: nil, error: URLError(.cancelled))
        }
        if let cancelledLog {
            logging(cancelledLog)
        }
        sessionTask?.cancel()
        sessionTask = nil
        mockTask?.cancel()
        mockTask = nil
    }
    
    nonisolated private static func captureHTTPBodyIfNeeded(_ urlRequest: URLRequest) -> URLRequest {
        var request = urlRequest
        if let body = request.httpBody, !body.isEmpty {
            return urlRequest
        }

        guard let stream = request.httpBodyStream else {
            return urlRequest
        }

        let data = readData(from: stream)

        // Replace the stream so the forwarded request can still send the body
        request.httpBodyStream = InputStream(data: data)

        // Set httpBody so our logger can read it easily
        request.httpBody = data
        return request
    }

    nonisolated private static func readData(from stream: InputStream) -> Data {
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
    
    func logging(_ item: LogItem) {
        Self.logger.logging(item)
    }
}
