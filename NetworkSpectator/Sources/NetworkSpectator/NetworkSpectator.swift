//
//  NetworkSpectatorManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 20/11/25.
//

import Foundation
import SwiftUI

final public class NetworkSpectator: Sendable {
    
    public static var view: some View {
        ContentView()
    }
    
    nonisolated(unsafe) public static var configuration: Configuration = .init() {
        didSet {
            DebugPrint.shared = .init(enabled: configuration.debugPrintEnabled)
        }
    }
    
    private init() {
        DebugPrint.shared = .init(enabled: Self.configuration.debugPrintEnabled)
    }
    
    public static func enable() {
        Task {
            await NetworkLogManager.shared.enable()
        }
    }
    
    public static func disable() {
        Task {
            await NetworkLogManager.shared.disable()
        }
    }
}
