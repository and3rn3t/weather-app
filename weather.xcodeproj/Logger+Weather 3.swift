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

    /// Logs related to weather data fetching and API calls.
    static let weatherService = Logger(subsystem: "dev.andernet.weather", category: "WeatherService")

    /// Logs related to location services and geocoding.
    static let location = Logger(subsystem: "dev.andernet.weather", category: "Location")

    /// Logs related to favorites / saved locations.
    static let favorites = Logger(subsystem: "dev.andernet.weather", category: "Favorites")

    /// Logs related to Live Activities.
    static let liveActivity = Logger(subsystem: "dev.andernet.weather", category: "LiveActivity")

    /// Logs related to shared data (App Group / widget data).
    static let sharedData = Logger(subsystem: "dev.andernet.weather", category: "SharedData")

    /// Logs related to weather maps and radar.
    static let weatherMap = Logger(subsystem: "dev.andernet.weather", category: "WeatherMap")

    /// Logs related to location search.
    static let search = Logger(subsystem: "dev.andernet.weather", category: "Search")

    /// Logs related to notifications.
    static let notifications = Logger(subsystem: "dev.andernet.weather", category: "Notifications")

    /// Logs related to app startup performance.
    static let startup = Logger(subsystem: "dev.andernet.weather", category: "Startup")
}

// MARK: - Startup Signpost

/// Returns a fresh OSLog handle for the Points of Interest instrument track.
/// Called as a function rather than a stored property so that
/// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor does not isolate the value.
nonisolated func makeStartupSignpostLog() -> OSLog {
    OSLog(subsystem: "dev.andernet.weather", category: .pointsOfInterest)
}
