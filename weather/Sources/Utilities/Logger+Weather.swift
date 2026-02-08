//
//  Logger+Weather.swift
//  weather
//
//  Structured logging to replace print() statements.
//

import OSLog

extension Logger {
    /// Bundle identifier used as the subsystem for all loggers.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "dev.andernet.weather"
    
    // MARK: - Category Loggers
    
    /// Logs related to weather data fetching and API calls.
    static let weatherService = Logger(subsystem: subsystem, category: "WeatherService")
    
    /// Logs related to location services and geocoding.
    static let location = Logger(subsystem: subsystem, category: "Location")
    
    /// Logs related to favorites / saved locations.
    static let favorites = Logger(subsystem: subsystem, category: "Favorites")
    
    /// Logs related to Live Activities.
    static let liveActivity = Logger(subsystem: subsystem, category: "LiveActivity")
    
    /// Logs related to shared data (App Group / widget data).
    static let sharedData = Logger(subsystem: subsystem, category: "SharedData")
    
    /// Logs related to weather maps and radar.
    static let weatherMap = Logger(subsystem: subsystem, category: "WeatherMap")
    
    /// Logs related to location search.
    static let search = Logger(subsystem: subsystem, category: "Search")
    
    /// Logs related to notifications.
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
}
