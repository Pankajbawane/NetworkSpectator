//
//  NetworkSpectatorManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 20/11/25.
//

import Foundation
import SwiftUI

let logger = NetworkSpectator.consoleLogger

final public class NetworkSpectator: Sendable {
    
    public static var logView: some View {
        ContentView()
    }
    static let consoleLogger: ConsoleLogger = .init(enabled: true)
    
    private init() { }
    
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
