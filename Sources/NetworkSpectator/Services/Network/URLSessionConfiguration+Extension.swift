//
//  URLSessionConfiguration+Extension.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 22/06/25.
//

import Foundation

internal extension URLSessionConfiguration {
    
    static func enableNetworkSwizzling() {
        let defaultSelector = #selector(getter: URLSessionConfiguration.default)
        let ephemeralSelector = #selector(getter: URLSessionConfiguration.ephemeral)

        guard let defaultMethod = class_getClassMethod(URLSessionConfiguration.self, defaultSelector),
              let swizzledDefaultMethod = class_getClassMethod(URLSessionConfiguration.self,
                                                               #selector(URLSessionConfiguration.nwDefault)),

              let ephemeralMethod = class_getClassMethod(URLSessionConfiguration.self, ephemeralSelector),
              let swizzledEphemeralMethod = class_getClassMethod(URLSessionConfiguration.self,
                                                                 #selector(URLSessionConfiguration.nwEphemeral)) else {
            return
        }

        method_exchangeImplementations(defaultMethod, swizzledDefaultMethod)
        method_exchangeImplementations(ephemeralMethod, swizzledEphemeralMethod)
    }
    
    static func disableNetworkSwizzling() {
        let defaultSelector = #selector(getter: URLSessionConfiguration.default)
        let ephemeralSelector = #selector(getter: URLSessionConfiguration.ephemeral)

        guard let defaultMethod = class_getClassMethod(URLSessionConfiguration.self, defaultSelector),
              let swizzledDefaultMethod = class_getClassMethod(URLSessionConfiguration.self,
                                                               #selector(URLSessionConfiguration.nwDefault)),

              let ephemeralMethod = class_getClassMethod(URLSessionConfiguration.self, ephemeralSelector),
              let swizzledEphemeralMethod = class_getClassMethod(URLSessionConfiguration.self,
                                                                 #selector(URLSessionConfiguration.nwEphemeral)) else {
            return
        }

        method_exchangeImplementations(swizzledDefaultMethod, defaultMethod)
        method_exchangeImplementations(swizzledEphemeralMethod, ephemeralMethod)
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
    
    static func enableNetworkSwizzling() {
        
        let originalSelector = #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
        let swizzledSelector = #selector(URLSession.swizzled_dataTask(with:completionHandler:))
        
        guard let originalMethod = class_getInstanceMethod(URLSession.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(URLSession.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    static func disableNetworkSwizzling() {
        let originalSelector = #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
        let swizzledSelector = #selector(URLSession.swizzled_dataTask(with:completionHandler:))
        
        guard let originalMethod = class_getInstanceMethod(URLSession.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(URLSession.self, swizzledSelector) else {
            return
        }
        
        // Reverse the swizzle by swapping the implementations back
        method_exchangeImplementations(swizzledMethod, originalMethod)
    }
    
    @objc
    private func swizzled_dataTask(with request: URLRequest,
                                   completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        if SkipRequestForLoggingHandler.shared.isEnabled,
           let url = request.url,
           SkipRequestForLoggingHandler.shared.shouldSkipLogging(url) {
                return self.swizzled_dataTask(with: request, completionHandler: completionHandler)
        }
        let log = LogItem.fromRequest(request)
        DebugPrint.log(log)
        
        Task {
            await NetworkLogManager.shared.add(log)
        }
        
        let wrappedHandler: (Data?, URLResponse?, Error?) -> Void = { data, response, error in
            let finalUpdatedLog = log.withResponse(response: response, data: data, error: error)
            DebugPrint.log(finalUpdatedLog)
            
            Task {
                await NetworkLogManager.shared.add(finalUpdatedLog)
            }
            
            completionHandler(data, response, error)
        }
        
        return self.swizzled_dataTask(with: request, completionHandler: wrappedHandler)
    }
}
