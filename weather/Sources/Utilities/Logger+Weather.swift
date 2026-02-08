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

// MARK: - Startup Timing Log Helper

/// Logs a startup timing message via `Logger.startup` (for Xcode console)
/// and appends to a file readable via `simctl get_app_container`.
nonisolated func startupLog(_ message: String) {
    let elapsed = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
    let line = "⏱ [+\(String(format: "%.0f", elapsed))ms] \(message)"
    Logger.startup.notice("\(line)")
    #if DEBUG
    StartupTimingDisk.append(line + "\n")
    #endif
}

/// Call once at app launch to clear the previous run's timing entries.
nonisolated func resetStartupLog() {
    #if DEBUG
    StartupTimingDisk.reset()
    #endif
}

/// Uses POSIX file I/O (fully nonisolated, no Foundation isolation issues)
/// to write timing data to Documents/startup_timing.log.
nonisolated enum StartupTimingDisk: Sendable {
    // Use C-level file I/O to avoid any Swift concurrency / MainActor issues.

    private static var filePath: String {
        // NSHomeDirectory() is a C-bridged function, always safe to call.
        let home = NSHomeDirectory()
        return home + "/Documents/startup_timing.log"
    }

    static func reset() {
        let path = filePath
        path.withCString { cPath in
            // Truncate / create the file
            let fd = open(cPath, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
            if fd >= 0 { close(fd) }
        }
    }

    static func append(_ text: String) {
        let path = filePath
        path.withCString { cPath in
            let fd = open(cPath, O_WRONLY | O_CREAT | O_APPEND, 0o644)
            guard fd >= 0 else { return }
            text.withCString { cText in
                _ = write(fd, cText, strlen(cText))
            }
            close(fd)
        }
    }
}
