//
//  NetworkSpectatorManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 20/11/25.
//

import Foundation

final public class NetworkSpectatorManager: Sendable {
    
    public static let shared: NetworkSpectatorManager = NetworkSpectatorManager()
    
    private init() {
        
    }
    
    public func enable() {
        Task {
            await NetworkLogManager.shared.enable()
        }
    }
    
    public func disable() {
        Task {
            await NetworkLogManager.shared.disable()
        }
    }
}
