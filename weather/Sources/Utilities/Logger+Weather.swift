//
//  Logger+Weather.swift
//  weather
//
//  Structured logging to replace print() statements.
//

import OSLog
import os.signpost

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

/// Returns a signpost log for the Points of Interest instrument track.
/// Declared as a `nonisolated` function so it is callable from any
/// actor context under SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor.
nonisolated func makeStartupSignpostLog() -> OSLog {
    OSLog(subsystem: "dev.andernet.weather", category: .pointsOfInterest)
}
