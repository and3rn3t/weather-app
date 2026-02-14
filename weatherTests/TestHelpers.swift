//
//  TestHelpers.swift
//  weatherTests
//
//  Shared test utilities and mock data factories
//

import Foundation
import CoreLocation
import SwiftData
@testable import weather

// MARK: - Mock Data Factory

enum MockDataFactory {
    /// Creates a complete weather data object for testing
    static func createWeatherData(
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        temperature: Double = 72.0,
        weatherCode: Int = 0
    ) -> WeatherData? {
        return MockWeatherData.createSampleWeatherData()
    }
    
    /// Creates a minimal weather data object
    static func createMinimalWeatherData() -> WeatherData? {
        let json = """
        {
            "latitude": 0.0,
            "longitude": 0.0,
            "timezone": "UTC",
            "current": {
                "time": "2026-02-14T12:00",
                "temperature_2m": 0.0,
                "apparent_temperature": 0.0,
                "weather_code": 0,
                "is_day": 1,
                "precipitation": 0.0,
                "wind_speed_10m": 0.0,
                "wind_direction_10m": 0,
                "wind_gusts_10m": 0.0,
                "relative_humidity_2m": 0,
                "dew_point_2m": 0.0,
                "surface_pressure": 1000.0,
                "visibility": 10000,
                "uv_index": 0.0,
                "cloud_cover": 0
            },
            "hourly": {
                "time": ["2026-02-14T12:00"],
                "temperature_2m": [0.0],
                "weather_code": [0],
                "precipitation_probability": [0]
            },
            "daily": {
                "time": ["2026-02-14"],
                "weather_code": [0],
                "temperature_2m_max": [0.0],
                "temperature_2m_min": [0.0],
                "sunrise": ["2026-02-14T07:00"],
                "sunset": ["2026-02-14T17:00"],
                "precipitation_probability_max": [0],
                "uv_index_max": [0.0],
                "wind_speed_10m_max": [0.0],
                "wind_gusts_10m_max": [0.0]
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try? decoder.decode(WeatherData.self, from: data)
    }
    
    /// Creates a saved location for testing
    static func createSavedLocation(
        name: String = "Test Location",
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        order: Int = 0
    ) -> SavedLocation {
        return SavedLocation(
            name: name,
            latitude: latitude,
            longitude: longitude,
            order: order
        )
    }
    
    /// Creates multiple test locations
    static func createMultipleLocations(count: Int) -> [SavedLocation] {
        return (0..<count).map { index in
            createSavedLocation(
                name: "Location \(index)",
                latitude: Double(index),
                longitude: Double(index),
                order: index
            )
        }
    }
}

// MARK: - Test Assertions

enum TestAssertions {
    /// Verifies that a coordinate is valid
    static func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
               coordinate.longitude >= -180 && coordinate.longitude <= 180
    }
    
    /// Verifies that a temperature is in a reasonable range
    static func isReasonableTemperature(_ temp: Double, unit: TemperatureUnit) -> Bool {
        switch unit {
        case .fahrenheit:
            return temp >= -100 && temp <= 150
        case .celsius:
            return temp >= -75 && temp <= 65
        }
    }
    
    /// Verifies that wind speed is reasonable
    static func isReasonableWindSpeed(_ speed: Double) -> Bool {
        return speed >= 0 && speed <= 200 // mph
    }
    
    /// Verifies that humidity is valid
    static func isValidHumidity(_ humidity: Int) -> Bool {
        return humidity >= 0 && humidity <= 100
    }
    
    /// Verifies that UV index is valid
    static func isValidUVIndex(_ uvIndex: Double) -> Bool {
        return uvIndex >= 0 && uvIndex <= 15
    }
}

// MARK: - Async Test Helpers

@MainActor
class AsyncTestHelper {
    /// Waits for a condition to be true with timeout
    static func waitFor(
        timeout: TimeInterval = 5.0,
        condition: @escaping () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return false
    }
    
    /// Waits for an async operation to complete
    static func waitForAsync<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async -> T?
    ) async -> T? {
        return await operation()
    }
}

// MARK: - SwiftData Test Container

@MainActor
class TestModelContainer {
    /// Creates an in-memory model container for testing
    static func create() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: SavedLocation.self, configurations: config)
    }
    
    /// Creates a model context for testing
    static func createContext() throws -> ModelContext {
        let container = try create()
        return ModelContext(container)
    }
}

// MARK: - Network Mock Helpers

enum NetworkMockHelper {
    /// Simulates a network delay
    static func simulateNetworkDelay(seconds: Double = 0.5) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
    
    /// Creates a mock URL response
    static func createMockResponse(statusCode: Int) -> HTTPURLResponse? {
        return HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
    }
}

// MARK: - Date Test Helpers

enum DateTestHelper {
    /// Creates a date from components for consistent testing
    static func createDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// Creates a date in the past
    static func pastDate(daysAgo: Int) -> Date {
        return Calendar.current.date(
            byAdding: .day,
            value: -daysAgo,
            to: Date()
        ) ?? Date()
    }
    
    /// Creates a date in the future
    static func futureDate(daysAhead: Int) -> Date {
        return Calendar.current.date(
            byAdding: .day,
            value: daysAhead,
            to: Date()
        ) ?? Date()
    }
}
