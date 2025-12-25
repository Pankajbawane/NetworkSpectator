//
//  URLSessionConfiguration+Extension.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 22/06/25.
//

import Foundation

internal extension URLSessionConfiguration {
    
    static func enableNetworkMonitoring() {
        let defaultSelector = #selector(getter: URLSessionConfiguration.default)
        let ephemeralSelector = #selector(getter: URLSessionConfiguration.ephemeral)

        guard let defaultMethod = class_getClassMethod(URLSessionConfiguration.self, defaultSelector),
              let customDefaultMethod = class_getClassMethod(URLSessionConfiguration.self,
                                                               #selector(URLSessionConfiguration.nwDefault)),

              let ephemeralMethod = class_getClassMethod(URLSessionConfiguration.self, ephemeralSelector),
              let customEphemeralMethod = class_getClassMethod(URLSessionConfiguration.self,
                                                                 #selector(URLSessionConfiguration.nwEphemeral)) else {
            return
        }

        method_exchangeImplementations(defaultMethod, customDefaultMethod)
        method_exchangeImplementations(ephemeralMethod, customEphemeralMethod)
    }
    
    static func disableNetworkMonitoring() {
        let defaultSelector = #selector(getter: URLSessionConfiguration.default)
        let ephemeralSelector = #selector(getter: URLSessionConfiguration.ephemeral)

        guard let defaultMethod = class_getClassMethod(URLSessionConfiguration.self, defaultSelector),
              let customDefaultMethod = class_getClassMethod(URLSessionConfiguration.self,
                                                               #selector(URLSessionConfiguration.nwDefault)),

              let ephemeralMethod = class_getClassMethod(URLSessionConfiguration.self, ephemeralSelector),
              let customEphemeralMethod = class_getClassMethod(URLSessionConfiguration.self,
                                                                 #selector(URLSessionConfiguration.nwEphemeral)) else {
            return
        }

        method_exchangeImplementations(customDefaultMethod, defaultMethod)
        method_exchangeImplementations(customEphemeralMethod, ephemeralMethod)
    }

    @objc class func nwDefault() -> URLSessionConfiguration {
        let config = nwDefault()
        injectInterceptor(into: config)
        return config
    }

    @objc class func nwEphemeral() -> URLSessionConfiguration {
        let config = nwEphemeral()
        injectInterceptor(into: config)
        return config
    }

    private static func injectInterceptor(into config: URLSessionConfiguration) {
        var classes = config.protocolClasses ?? []
        if !classes.contains(where: { $0 == NetworkURLProtocol.self }) {
            classes.insert(NetworkURLProtocol.self, at: 0)
            config.protocolClasses = classes
        }
    }
}

internal extension URLSession {
    
    static func enableNetworkMonitoring() {
        
        let originalSelector = #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
        let customSelector = #selector(URLSession.custom_dataTask(with:completionHandler:))
        
        guard let originalMethod = class_getInstanceMethod(URLSession.self, originalSelector),
              let customMethod = class_getInstanceMethod(URLSession.self, customSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, customMethod)
    }
    
    static func disableNetworkMonitoring() {
        let originalSelector = #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
        let customSelector = #selector(URLSession.custom_dataTask(with:completionHandler:))
        
        guard let originalMethod = class_getInstanceMethod(URLSession.self, originalSelector),
              let customMethod = class_getInstanceMethod(URLSession.self, customSelector) else {
            return
        }
        
        // Reset by swapping the implementations back
        method_exchangeImplementations(customMethod, originalMethod)
    }
    
    @objc
    private func custom_dataTask(with request: URLRequest,
                                   completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        // Avoid intercepting requests twice
        if !NetworkURLProtocol.canInit(with: request) {
            return self.custom_dataTask(with: request, completionHandler: completionHandler)
        }
        
        // If the request is ignored for logging using match rules, don't intercept
        if SkipRequestForLoggingHandler.shared.isEnabled,
           let url = request.url,
           SkipRequestForLoggingHandler.shared.shouldSkipLogging(request) {
            return self.custom_dataTask(with: request, completionHandler: completionHandler)
        }
        
        let log = LogItem.fromRequest(request)
        DebugPrint.log(log)
        
        Task {
            await NetworkLogContainer.shared.add(log)
        }
        
        let wrappedHandler: (Data?, URLResponse?, Error?) -> Void = { data, response, error in
            let finalUpdatedLog = log.withResponse(response: response, data: data, error: error)
            DebugPrint.log(finalUpdatedLog)
            
            Task {
                await NetworkLogContainer.shared.add(finalUpdatedLog)
            }
            
            // If the request is mocked using match rules, return mocked response.
            if let mock = MockServer.shared.responseIfMocked(request) {
                completionHandler(mock.response, mock.urlResponse(request), mock.error)
            } else {
                completionHandler(data, response, error)
            }
        }
        
        return self.custom_dataTask(with: request, completionHandler: wrappedHandler)
    }
}
