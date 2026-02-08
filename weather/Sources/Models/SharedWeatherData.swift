//
//  SharedWeatherData.swift
//  weather
//
//  Created by Matt on 2/5/26.
//
//  Shared data model for passing weather between the main app and widget extension.
//  Both targets should include this file.
//

import Foundation
import OSLog
import os.signpost

// MARK: - App Group Identifier

enum AppGroup {
    static let identifier = "group.dev.andernet.weather"
    
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
    
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

// MARK: - Shared Weather Data

/// Simplified weather data structure for widget display
struct SharedWeatherData: Codable {
    let temperature: Double
    let apparentTemperature: Double
    let weatherCode: Int
    let isDay: Int
    let humidity: Int
    let windSpeed: Double
    let highTemp: Double
    let lowTemp: Double
    let precipitationProbability: Int
    let locationName: String
    let lastUpdated: Date
    let hourlyForecast: [SharedHourlyData]
}

struct SharedHourlyData: Codable {
    let time: String
    let temperature: Double
    let weatherCode: Int
}

// MARK: - Shared Data Manager

class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let weatherDataKey = "sharedWeatherData"
    
    // MARK: - Full WeatherData cache for instant startup
    
    /// Keys for last-known location (persisted in standard UserDefaults for speed)
    private let lastLatitudeKey = "lastWeatherLatitude"
    private let lastLongitudeKey = "lastWeatherLongitude"
    private let lastLocationNameKey = "lastWeatherLocationName"
    
    /// File URL for the cached full WeatherData — computed once and reused.
    /// Uses Application Support (durable) instead of Caches (purge-able by iOS).
    private let cachedWeatherFileURL: URL? = {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        // Ensure directory exists (Application Support isn't auto-created).
        // Done once at init time so repeated URL accesses don't hit the FS.
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("cachedWeatherData.json")
    }()
    
    /// Legacy Caches location — used as fallback for migration
    private let legacyCachedWeatherFileURL: URL? = FileManager.default.urls(
        for: .cachesDirectory, in: .userDomainMask
    ).first?.appendingPathComponent("cachedWeatherData.json")
    
    /// Shared decoder — reused across all cache reads to avoid repeated alloc.
    private static let decoder = JSONDecoder()
    
    /// Shared encoder — reused across all cache writes to avoid repeated alloc.
    private static let encoder = JSONEncoder()
    
    private init() {}
    
    /// Save weather data to the shared container
    func saveWeatherData(_ weatherData: WeatherData, locationName: String?) {
        guard let sharedDefaults = AppGroup.sharedDefaults else {
            Logger.sharedData.error("Failed to access shared UserDefaults")
            return
        }
        
        // Build simplified shared data
        let hourlyData = zip(weatherData.hourly.time.prefix(24), 
                            zip(weatherData.hourly.temperature2m.prefix(24), 
                                weatherData.hourly.weatherCode.prefix(24)))
            .map { time, tempCode in
                SharedHourlyData(time: time, temperature: tempCode.0, weatherCode: tempCode.1)
            }
        
        let highTemp: Double = weatherData.daily.temperature2mMax.first ?? 0.0
        let lowTemp: Double = weatherData.daily.temperature2mMin.first ?? 0.0
        
        let sharedData = SharedWeatherData(
            temperature: weatherData.current.temperature2m,
            apparentTemperature: weatherData.current.apparentTemperature,
            weatherCode: weatherData.current.weatherCode,
            isDay: weatherData.current.isDay,
            humidity: weatherData.current.relativeHumidity2m,
            windSpeed: weatherData.current.windSpeed10m,
            highTemp: highTemp,
            lowTemp: lowTemp,
            precipitationProbability: weatherData.daily.precipitationProbabilityMax.first ?? 0,
            locationName: locationName ?? "Current Location",
            lastUpdated: Date(),
            hourlyForecast: hourlyData
        )
        
        do {
            let data = try Self.encoder.encode(sharedData)
            sharedDefaults.set(data, forKey: weatherDataKey)
            
            // Tell widgets to refresh
            WidgetCenterHelper.reloadAllTimelines()
        } catch {
            Logger.sharedData.error("Failed to encode weather data: \(error.localizedDescription)")
        }
    }
    
    /// Load weather data from the shared container
    func loadWeatherData() -> SharedWeatherData? {
        guard let sharedDefaults = AppGroup.sharedDefaults,
              let data = sharedDefaults.data(forKey: weatherDataKey) else {
            return nil
        }
        
        do {
            return try Self.decoder.decode(SharedWeatherData.self, from: data)
        } catch {
            Logger.sharedData.error("Failed to decode weather data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Full WeatherData Cache (for instant app startup)
    
    /// Cache the full WeatherData to disk + save last coordinates.
    /// Called after every successful API fetch.
    func cacheFullWeatherData(_ weatherData: WeatherData, locationName: String?) {
        // Persist last-known coordinates (UserDefaults is fine for 3 small values)
        let ud = UserDefaults.standard
        ud.set(weatherData.latitude, forKey: lastLatitudeKey)
        ud.set(weatherData.longitude, forKey: lastLongitudeKey)
        ud.set(locationName, forKey: lastLocationNameKey)

        // Write full WeatherData to Application Support (durable, not backed up)
        guard let fileURL = cachedWeatherFileURL else { return }
        do {
            os_signpost(.begin, log: StartupSignpost.log, name: "CacheWrite")
            let data = try Self.encoder.encode(weatherData)
            try data.write(to: fileURL, options: .atomic)
            os_signpost(.end, log: StartupSignpost.log, name: "CacheWrite")
            startupLog("Cache write: \(data.count / 1024)KB")
        } catch {
            Logger.sharedData.error("Failed to cache full weather data: \(error.localizedDescription)")
        }
    }
    
    /// Load the previously cached full WeatherData from disk.
    /// Returns nil on first launch or if cache is corrupt/missing.
    func loadCachedFullWeatherData() -> WeatherData? {
        // Try primary location (Application Support)
        if let data = loadWeatherFile(at: cachedWeatherFileURL) {
            return data
        }
        // Fallback: try legacy Caches location (migration path)
        if let data = loadWeatherFile(at: legacyCachedWeatherFileURL) {
            // Migrate to durable location for next time
            if let fileURL = cachedWeatherFileURL {
                try? Self.encoder.encode(data).write(to: fileURL, options: .atomic)
            }
            return data
        }
        return nil
    }
    
    private func loadWeatherFile(at url: URL?) -> WeatherData? {
        guard let fileURL = url,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            os_signpost(.begin, log: StartupSignpost.log, name: "CacheRead")
            let data = try Data(contentsOf: fileURL)
            let decoded = try Self.decoder.decode(WeatherData.self, from: data)
            os_signpost(.end, log: StartupSignpost.log, name: "CacheRead")
            startupLog("Cache read: \(data.count / 1024)KB")
            return decoded
        } catch {
            Logger.sharedData.error("Failed to load cached weather data: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Returns the last-known location coordinates and name, if available.
    func lastKnownLocation() -> (latitude: Double, longitude: Double, name: String?)? {
        let ud = UserDefaults.standard
        // latitude/longitude default to 0.0 if not set; check both are non-zero
        let lat = ud.double(forKey: lastLatitudeKey)
        let lon = ud.double(forKey: lastLongitudeKey)
        guard lat != 0.0 || lon != 0.0 else { return nil }
        let name = ud.string(forKey: lastLocationNameKey)
        return (lat, lon, name)
    }
}

// MARK: - Widget Center Helper

import WidgetKit

enum WidgetCenterHelper {
    static func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
