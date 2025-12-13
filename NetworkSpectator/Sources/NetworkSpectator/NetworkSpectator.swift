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

final public class NetworkSpectator: Sendable {
    
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
