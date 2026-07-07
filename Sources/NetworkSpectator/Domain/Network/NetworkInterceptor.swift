//
//  NetworkInterceptor.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 30/03/26.
//

import Foundation
import os

package enum NetworkInterceptionCapability: Hashable, Sendable {
    case logging
    case mocking
}

/// Manages the low-level URLProtocol registration required to intercept network traffic.
///
/// Both the UI layer (`NetworkLogContainer`) and the test layer (`Test`) share
/// this single point of control.
package final class NetworkInterceptor: Sendable {
    
    package static let shared = NetworkInterceptor()
    
    private let activeCapabilities = OSAllocatedUnfairLock<Set<NetworkInterceptionCapability>>(initialState: [])
    
    /// Whether network interception is currently active.
    package var isEnabled: Bool { activeCapabilities.withLock { !$0.isEmpty } }
    
    private init() { }
    
    /// Registers the URL protocol for intercepting.
    package func enable(for capability: NetworkInterceptionCapability) {
        activeCapabilities.withLock { capabilities in
            let wasInactive = capabilities.isEmpty
            capabilities.insert(capability)
            guard wasInactive else { return }
            URLProtocol.registerClass(NetworkURLProtocol.self)
            URLSessionConfiguration.enableNetworkMonitoring()
            ConsolePrint.log("NETWORK SPECTATOR: Interception enabled.")
        }
    }
    
    /// Unregisters the URL protocol when no interception capability remains active.
    package func disable(for capability: NetworkInterceptionCapability) {
        activeCapabilities.withLock { capabilities in
            guard capabilities.remove(capability) != nil, capabilities.isEmpty else { return }
            URLProtocol.unregisterClass(NetworkURLProtocol.self)
            URLSessionConfiguration.disableNetworkMonitoring()
            ConsolePrint.log("NETWORK SPECTATOR: Interception disabled.")
        }
    }
}
