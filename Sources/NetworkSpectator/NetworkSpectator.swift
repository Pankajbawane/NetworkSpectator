//
//  NetworkSpectator.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 20/11/25.
//

#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@_exported import NetworkSpectatorCore
@_exported import NetworkSpectatorMocking
@_exported import NetworkSpectatorLogging
@_exported import NetworkSpectatorUI

/// The entry point for integrating network logging and mocking into your app.
///
/// Use `NetworkSpectator` to start network capture, present the inspection UI, register mock responses,
/// configure logging exclusions, and enable diagnostic console output.
///
/// Call ``start(onDemand:)`` early in the app lifecycle, before the app creates the
/// `URLSession` instances you want to inspect.
///
/// ```swift
/// NetworkSpectator.start()
///
/// // Present the log viewer in SwiftUI.
/// NavigationStack {
///     NetworkSpectator.rootView
/// }
/// ```
public struct NetworkSpectator: Sendable {
    
    /// The SwiftUI inspection interface for captured network activity.
    ///
    /// Present this view from your app to browse requests, responses, mocks, exclusions, history, and insights.
    #if canImport(SwiftUI)
    @MainActor
    public static var rootView: some View {
        RootView()
    }
    #endif
    
    #if canImport(UIKit)
    /// A UIKit host for the NetworkSpectator inspection interface.
    ///
    /// Push or present this view controller from UIKit-based apps.
    @MainActor
    public static var rootViewController: UIViewController {
        UIHostingController(rootView: RootView())
    }
    #elseif canImport(AppKit)
    /// An AppKit host for the NetworkSpectator inspection interface.
    ///
    /// Present this view controller from macOS apps.
    @MainActor
    public static var rootViewController: NSViewController {
        NSHostingController(rootView: RootView())
    }
    #endif
    
    /// Starts network capture for logging, inspection, and mocking.
    ///
    /// Call this method early in the app lifecycle, ideally before creating the `URLSession`
    /// instances you want NetworkSpectator to observe. This method schedules startup work
    /// asynchronously and returns immediately.
    ///
    /// - Parameter onDemand: When `true`, capture is configured but logging remains disabled until
    ///   it is enabled from the UI. When `false`, logging starts immediately.
    public static func start(onDemand: Bool = false) {
        Task {
            if onDemand {
                await NetworkLogMonitor.shared.enableOnDemand()
            } else {
                await NetworkLogMonitor.shared.enable()
            }
        }
    }
    
    /// Stops network capture.
    ///
    /// This method schedules shutdown work asynchronously and returns immediately. Calling it is
    /// not required if ``start(onDemand:)`` was never invoked.
    public static func stop() {
        Task {
            await NetworkLogMonitor.shared.disable()
        }
    }
    
    /// Clears all registered mock responses and logging exclusion rules.
    ///
    /// Use this when you want to keep NetworkSpectator available but discard runtime configuration.
    public static func reset() {
        MockServer.shared.clear()
        LoggingExclusionManager.shared.clear()
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
    /// After calling this method, matching requests are no longer served from NetworkSpectator mocks.
    public static func clearMocks() {
        MockServer.shared.clear()
    }
    
    /// Registers a logging exclusion rule.
    ///
    /// Matching requests continue through the normal network or mock flow, but they are omitted
    /// from the captured request log.
    ///
    /// - Parameter rule: The method and matching rule that identify requests to exclude from logging.
    public static func excludeFromLogging(for rule: LoggingExclusionRule) {
        LoggingExclusionManager.shared.register(request: rule)
    }
    
    /// Removes all logging exclusion rules.
    ///
    /// After calling this method, intercepted requests are eligible to appear in the network log again.
    public static func clearLoggingExclusions() {
        LoggingExclusionManager.shared.clear()
    }
    
    /// Enables or disables NetworkSpectator diagnostic output in the Xcode console.
    ///
    /// Use this while troubleshooting SDK integration or capture behavior.
    ///
    /// - Parameter isEnabled: Pass `true` to enable diagnostic output, or `false` to disable it.
    public static func setDebugConsoleLogging(_ isEnabled: Bool) {
        DebugPrint.shared.update(isEnabled)
    }
    
    /// Instantiation is not intended.
    private init() { }
}
