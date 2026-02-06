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
    
    private init() {}
    
    /// Save weather data to the shared container
    func saveWeatherData(_ weatherData: WeatherData, locationName: String?) {
        guard let sharedDefaults = AppGroup.sharedDefaults else {
            print("Failed to access shared UserDefaults")
            return
        }
        
        // Build simplified shared data
        let hourlyData = zip(weatherData.hourly.time.prefix(24), 
                            zip(weatherData.hourly.temperature2m.prefix(24), 
                                weatherData.hourly.weatherCode.prefix(24)))
            .map { time, tempCode in
                SharedHourlyData(time: time, temperature: tempCode.0, weatherCode: tempCode.1)
            }
        
        let sharedData = SharedWeatherData(
            temperature: weatherData.current.temperature2m,
            apparentTemperature: weatherData.current.apparentTemperature,
            weatherCode: weatherData.current.weatherCode,
            isDay: weatherData.current.isDay,
            humidity: weatherData.current.relativeHumidity2m,
            windSpeed: weatherData.current.windSpeed10m,
            highTemp: weatherData.daily.temperature2mMax.first ?? 0,
            lowTemp: weatherData.daily.temperature2mMin.first ?? 0,
            precipitationProbability: weatherData.daily.precipitationProbabilityMax.first ?? 0,
            locationName: locationName ?? "Current Location",
            lastUpdated: Date(),
            hourlyForecast: hourlyData
        )
        
        do {
            let data = try JSONEncoder().encode(sharedData)
            sharedDefaults.set(data, forKey: weatherDataKey)
            
            // Tell widgets to refresh
            WidgetCenterHelper.reloadAllTimelines()
        } catch {
            print("Failed to encode weather data: \(error)")
        }
    }
    
    /// Load weather data from the shared container
    func loadWeatherData() -> SharedWeatherData? {
        guard let sharedDefaults = AppGroup.sharedDefaults,
              let data = sharedDefaults.data(forKey: weatherDataKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(SharedWeatherData.self, from: data)
        } catch {
            print("Failed to decode weather data: \(error)")
            return nil
        }
    }
}

// MARK: - Widget Center Helper

import WidgetKit

enum WidgetCenterHelper {
    static func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
