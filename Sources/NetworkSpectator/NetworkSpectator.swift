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

/// The main entry point for integrating network logging and mocking into your app.
///
/// Use `NetworkSpectator` to intercept, inspect, and mock HTTP network requests.
/// Call ``start()`` early in your app's lifecycle to begin capturing network traffic,
/// then present ``rootView`` or ``rootViewController`` to display the network log UI.
///
/// ```swift
/// // Start logging on app launch
/// NetworkSpectator.start()
///
/// // Present the log viewer in SwiftUI
/// NavigationStack {
///     NetworkSpectator.rootView
/// }
/// ```
public struct NetworkSpectator: Sendable {
    
    /// A SwiftUI view that displays the network log viewer.
    ///
    /// Present this view in your SwiftUI hierarchy to browse captured network requests and responses.
    @MainActor
    public static var rootView: some View {
        RootView()
    }
    
    #if canImport(UIKit)
    /// A `UIViewController` that hosts the network log viewer for use in UIKit-based apps.
    ///
    /// Push or present this view controller to display the network log UI.
    @MainActor
    public static var rootViewController: UIViewController {
        UIHostingController(rootView: RootView())
    }
    #elseif canImport(AppKit)
    /// An `NSViewController` that hosts the network log viewer for use in AppKit-based apps.
    ///
    /// Present this view controller in a window to display the network log UI.
    @MainActor
    public static var rootViewController: NSViewController {
        NSHostingController(rootView: RootView())
    }
    #endif
    
    /// Starts intercepting network requests for logging and inspection.
    ///
    /// Call this method early in your app's lifecycle (e.g., in `application(_:didFinishLaunchingWithOptions:)` or the `App` initializer)
    /// to begin capturing all HTTP traffic made through `URLSession`.
    ///
    /// - Parameter onDemand: When `true`, logging is deferred until explicitly enabled from the UI.
    ///   When `false` (the default), logging begins immediately.
    public static func start(onDemand: Bool = false) {
        Task {
            if onDemand {
                await NetworkLogContainer.shared.setOnDemand(onDemand)
            } else {
                await NetworkLogContainer.shared.enable()
            }
        }
    }
    
    /// Stops intercepting network requests and clears all registered mocks and skip rules.
    ///
    /// Calling this method is not required if ``start(onDemand:)`` was never invoked.
    public static func stop() {
        Task {
            await NetworkLogContainer.shared.disable()
            MockServer.shared.clear()
            SkipRequestForLoggingHandler.shared.clear()
        }
    }
    
    /// Registers a mock response to be returned for requests matching the mock's rule.
    ///
    /// When a network request matches the ``Mock``'s ``MatchRule``, the mock response is returned
    /// instead of making a real network call.
    ///
    /// - Parameter mock: A ``Mock`` instance that defines the match rule and the response to return.
    public static func registerMock(for mock: Mock) {
        MockServer.shared.register(mock)
    }
    
    /// Removes all registered mock responses.
    ///
    /// After calling this method, all network requests will go through to the actual network.
    public static func stopMocking() {
        MockServer.shared.clear()
    }
    
    /// Excludes network requests matching the given rule from being logged.
    ///
    /// Use this to suppress noisy or irrelevant requests (e.g., analytics pings, health checks)
    /// from appearing in the network log.
    ///
    /// - Parameter rule: A ``MatchRule`` that identifies which requests should be excluded from logging.
    public static func ignoreLogging(for rule: MatchRule) {
        SkipRequestForLoggingHandler.shared.register(rule: rule)
    }
    
    /// Removes all logging exclusion rules.
    ///
    /// After calling this method, all intercepted network requests will be logged again.
    public static func stopIgnoringLog() {
        SkipRequestForLoggingHandler.shared.clear()
    }
    
    /// Enables or disables debug logging to the Xcode console.
    ///
    /// When enabled, NetworkSpectator prints internal diagnostic messages to the console,
    /// which can be helpful for troubleshooting integration issues.
    ///
    /// - Parameter isEnabled: Pass `true` to enable debug logging, or `false` to disable it.
    public static func debugLogsPrint(isEnabled: Bool) {
        DebugPrint.shared.update(isEnabled)
    }
}
