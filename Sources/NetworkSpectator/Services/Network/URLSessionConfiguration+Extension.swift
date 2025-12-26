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
