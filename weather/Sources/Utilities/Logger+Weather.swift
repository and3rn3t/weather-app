//
//  Logger+Weather.swift
//  weather
//
//  Structured logging to replace print() statements.
//

import OSLog
import os.signpost

nonisolated
extension Logger {
    // MARK: - Category Loggers
    // String literals only — no Bundle.main, no actor dependency.

    static let weatherService = Logger(subsystem: "dev.andernet.weather", category: "WeatherService")
    static let location = Logger(subsystem: "dev.andernet.weather", category: "Location")
    static let favorites = Logger(subsystem: "dev.andernet.weather", category: "Favorites")
    static let liveActivity = Logger(subsystem: "dev.andernet.weather", category: "LiveActivity")
    static let sharedData = Logger(subsystem: "dev.andernet.weather", category: "SharedData")
    static let weatherMap = Logger(subsystem: "dev.andernet.weather", category: "WeatherMap")
    static let search = Logger(subsystem: "dev.andernet.weather", category: "Search")
    static let notifications = Logger(subsystem: "dev.andernet.weather", category: "Notifications")
    static let startup = Logger(subsystem: "dev.andernet.weather", category: "Startup")
}

// MARK: - Startup Signpost Instrumentation
//
// Usage:
//   os_signpost(.begin, log: StartupSignpost.log, name: "PhaseName")
//   os_signpost(.end,   log: StartupSignpost.log, name: "PhaseName")
//
// View in Instruments → os_signpost → Points of Interest track.

/// Centralised signpost log for startup profiling.
/// Explicitly nonisolated so it can be used from any actor context.
nonisolated
enum StartupSignpost: Sendable {
    /// Cached OSLog — created once, reused everywhere.
    static let log = OSLog(
        subsystem: "dev.andernet.weather",
        category: .pointsOfInterest
    )

    /// Wall-clock reference set at static-init time (before main()).
    /// Compare with `CFAbsoluteTimeGetCurrent()` to measure total
    /// pre-main + main startup cost.
    static let processStart = CFAbsoluteTimeGetCurrent()
}

/// Backwards-compatible shim — call sites that haven't been updated yet
/// will still compile. Prefer `StartupSignpost.log` for new code.
@available(*, deprecated, renamed: "StartupSignpost.log")
nonisolated func makeStartupSignpostLog() -> OSLog {
    StartupSignpost.log
}
