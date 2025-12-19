//
//  NetworkSpectatorManager.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 20/11/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct NetworkSpectator: Sendable {
    
    @MainActor
    // Presentable View from SwiftUI.
    public static var rootView: some View {
        RootView()
    }
    
    #if canImport(UIKit)
    @MainActor
    // UIViewController to present from UIKit.
    public static var rootViewController: UIViewController {
        UIHostingController(rootView: RootView())
    }
    #elseif canImport(AppKit)
    @MainActor
    public static var rootViewController: NSViewController {
        NSHostingController(rootView: RootView())
    }
    #endif
    
    internal nonisolated(unsafe) static let skipRequestLogging: SkipRequestForLoggingHandler = .init()
    
    public static func start() {
        Task {
            await NetworkLogManager.shared.enable()
        }
    }
    
    public static func stop() {
        Task {
            await NetworkLogManager.shared.disable()
            MockServer.shared.clear()
            skipRequestLogging.clear()
        }
    }
    
    public static func registerMock(for mock: Mock) {
        MockServer.shared.register(mock)
    }
    
    public static func stopMocking() {
        MockServer.shared.clear()
    }
    
    public static func ignoreLogging(for rule: MatchRule) {
        SkipRequestForLoggingHandler.shared.register(rule: rule)
    }
    
    public static func ignoreLogging(for rules: [MatchRule]) {
        SkipRequestForLoggingHandler.shared.register(rules: rules)
    }
    
    public static func stopIgnoringLog() {
        SkipRequestForLoggingHandler.shared.clear()
    }
    
    public  static func debugLogsPrint(isEnabled: Bool) {
        DebugPrint.shared = .init(enabled: isEnabled)
    }
}
