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
    
    // Presentable View from SwiftUI.
    public static var rootView: some View {
        RootView()
    }
    
    #if canImport(UIKit)
    // UIViewController to present from UIKit.
    public static var rootViewController: UIViewController {
        UIHostingController(rootView: RootView())
    }
    #elseif canImport(AppKit)
    public static var rootViewController: NSViewController {
        NSHostingController(rootView: RootView())
    }
    #endif
    
    internal nonisolated(unsafe) static let mockServer: MockServer = .init()
    
    internal nonisolated(unsafe) static let ignore: IgnoreRequestManager = .init()
    
    public nonisolated(unsafe) static var configuration: Configuration = .init() {
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
    
    public static func registerMock(for mock: Mock) {
        mockServer.register(mock)
    }
    
    public static func disableMock() {
        mockServer.clear()
    }
    
    public static func ignoreLogging(for rule: MatchRule) {
        ignore.register(rule: rule)
    }
    
    public static func ignoreLogging(for rules: [MatchRule]) {
        ignore.register(rules: rules)
    }
    
    public static func stopIgnoringLogging() {
        ignore.disable()
    }
}
