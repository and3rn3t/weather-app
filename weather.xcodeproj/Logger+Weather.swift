//
//  Logger+Weather.swift
//  weather
//
//  Structured logging to replace print() statements.
//

import OSLog
import os.signpost

// Evaluated once at module load time, outside any actor context.
// Bundle.main is safe to read here because it never changes after launch.
private let _subsystem: String = {
    guard let id = Bundle.main.bundleIdentifier else {
        return "dev.andernet.weather"
    }
    return id
}()

extension Logger {
    // MARK: - Category Loggers

    /// Logs related to weather data fetching and API calls.
    static let weatherService = Logger(subsystem: _subsystem, category: "WeatherService")

    /// Logs related to location services and geocoding.
    static let location = Logger(subsystem: _subsystem, category: "Location")

    /// Logs related to favorites / saved locations.
    static let favorites = Logger(subsystem: _subsystem, category: "Favorites")

    /// Logs related to Live Activities.
    static let liveActivity = Logger(subsystem: _subsystem, category: "LiveActivity")

    /// Logs related to shared data (App Group / widget data).
    static let sharedData = Logger(subsystem: _subsystem, category: "SharedData")

    /// Logs related to weather maps and radar.
    static let weatherMap = Logger(subsystem: _subsystem, category: "WeatherMap")

    /// Logs related to location search.
    static let search = Logger(subsystem: _subsystem, category: "Search")

    /// Logs related to notifications.
    static let notifications = Logger(subsystem: _subsystem, category: "Notifications")

    /// Logs related to app startup performance.
    static let startup = Logger(subsystem: _subsystem, category: "Startup")
}

/// Signpost log for profiling startup phases in Instruments.
/// Stored as a plain global so it is accessible from any concurrency context.
let StartupSignpostLog = OSLog(subsystem: _subsystem, category: .pointsOfInterest)
