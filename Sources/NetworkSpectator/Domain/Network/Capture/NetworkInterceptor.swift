//
//  NetworkInterceptor.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 30/03/26.
//

import Foundation
import os

/// Manages the low-level URLProtocol registration required to intercept network traffic.
///
/// Both the UI layer (`NetworkLogContainer`) and the test layer (`Test`) share
/// this single point of control.
final class NetworkInterceptor: Sendable {
    
    static let shared = NetworkInterceptor()
    
    /// Thread-safe flag to guard against redundant enable/disable calls.
    private let _isEnabled = OSAllocatedUnfairLock(initialState: false)
    
    /// Whether network interception is currently active.
    var isEnabled: Bool { _isEnabled.withLock { $0 } }
    
    private init() { }
    
    /// Registers the URL protocol for intercepting.
    func enable() {
        _ = _isEnabled.withLock { enabled in
            guard !enabled else { return false }
            URLProtocol.registerClass(NetworkURLProtocol.self)
            URLSessionConfiguration.enableNetworkMonitoring()
            enabled = true
            DebugPrint.log("NETWORK SPECTATOR: Interception enabled.")
            return true
        }
    }
    
    /// Unregisters the URL protocol and restores URLSessionConfiguration.
    func disable() {
        _ = _isEnabled.withLock { enabled in
            guard enabled else { return false }
            URLProtocol.unregisterClass(NetworkURLProtocol.self)
            URLSessionConfiguration.disableNetworkMonitoring()
            enabled = false
            DebugPrint.log("NETWORK SPECTATOR: Interception disabled.")
            return true
        }
    }
}
