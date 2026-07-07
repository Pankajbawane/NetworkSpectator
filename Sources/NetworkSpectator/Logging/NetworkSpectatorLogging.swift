//
//  NetworkSpectatorLogging.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 07/07/26.
//

/// Public entry point for non-UI logging integrations.
///
/// Import `NetworkSpectatorLogging` when you need request capture, history, exclusions,
/// or exports without importing the SwiftUI presentation module directly.
public enum NetworkSpectatorLogging {

    /// Starts network logging immediately.
    public static func start() {
        Task {
            await NetworkLogMonitor.shared.enable()
        }
    }

    /// Configures logging for on-demand activation from the UI or stored monitoring preference.
    public static func start(onDemand: Bool) {
        Task {
            if onDemand {
                await NetworkLogMonitor.shared.enableOnDemand()
            } else {
                await NetworkLogMonitor.shared.enable()
            }
        }
    }

    /// Stops network logging.
    public static func stop() {
        Task {
            await NetworkLogMonitor.shared.disable()
        }
    }

    /// Clears the current logging session projection.
    public static func clearLogs() {
        Task {
            await NetworkLogMonitor.shared.clear()
        }
    }

    /// Registers a logging exclusion rule.
    public static func exclude(_ rule: LoggingExclusionRule) {
        LoggingExclusionManager.shared.register(request: rule)
    }

    /// Removes all logging exclusion rules.
    public static func clearExclusions() {
        LoggingExclusionManager.shared.clear()
    }
}
