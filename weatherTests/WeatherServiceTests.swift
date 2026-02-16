//
//  WeatherServiceTests.swift
//  weatherTests
//
//  Created by Matt on 2/5/26.
//

import Testing
import Foundation
@testable import weather

// MARK: - Weather Service Tests

@MainActor
struct WeatherServiceTests {
    
    /// Clear cached weather data and UserDefaults before each test
    func clearCache() {
        // Clear UserDefaults keys
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "lastWeatherLatitude")
        ud.removeObject(forKey: "lastWeatherLongitude")
        ud.removeObject(forKey: "lastWeatherLocationName")
        
        // Clear cached file
        if let fileURL = SharedDataManager.cachedWeatherFilePrimaryURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    @Test func initialState() {
        clearCache()
        let service = WeatherService()
        
        #expect(service.weatherData == nil)
        #expect(service.airQualityData == nil)
        #expect(service.isLoading == false)
        #expect(service.errorMessage == nil)
        #expect(service.lastError == nil)
        #expect(service.currentLocationName == nil)
    }
    
    @Test func fetchWeatherUpdatesLoadingState() async {
        clearCache()
        let service = WeatherService()
        
        // Start a fetch (will fail without network, but tests loading state)
        Task {
            await service.fetchWeatherData(latitude: 37.7749, longitude: -122.4194, locationName: "San Francisco")
        }
        
        // Give time for loading to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Either loading or completed/errored
        #expect(service.isLoading || service.errorMessage != nil || service.weatherData != nil)
    }
    
    @Test func locationNameIsSaved() async {
        clearCache()
        let service = WeatherService()
        let testName = "Test Location"
        
        // This will likely fail but should save the location name
        await service.fetchWeatherData(latitude: 0, longitude: 0, locationName: testName)
        
        #expect(service.currentLocationName == testName)
    }
}

// MARK: - Mock Weather Data for Testing

struct MockWeatherData {
    static func createSampleWeatherData() -> WeatherData? {
        let json = """
        {
            "latitude": 37.7749,
            "longitude": -122.4194,
            "timezone": "America/Los_Angeles",
            "current": {
                "time": "2026-02-05T12:00",
                "temperature_2m": 65.0,
                "apparent_temperature": 63.0,
                "weather_code": 1,
                "is_day": 1,
                "precipitation": 0.0,
                "wind_speed_10m": 10.0,
                "wind_direction_10m": 180,
                "wind_gusts_10m": 15.0,
                "relative_humidity_2m": 55,
                "dew_point_2m": 45.0,
                "surface_pressure": 1015.0,
                "visibility": 10000,
                "uv_index": 5.0,
                "cloud_cover": 25
            },
            "hourly": {
                "time": ["2026-02-05T12:00", "2026-02-05T13:00"],
                "temperature_2m": [65.0, 67.0],
                "apparent_temperature": [63.0, 65.0],
                "weather_code": [1, 0],
                "precipitation": [0.0, 0.0],
                "precipitation_probability": [10, 5],
                "wind_speed_10m": [10.0, 12.0],
                "wind_direction_10m": [180, 185],
                "relative_humidity_2m": [55, 50],
                "uv_index": [5.0, 6.0],
                "visibility": [10000, 10000]
            },
            "daily": {
                "time": ["2026-02-05", "2026-02-06"],
                "weather_code": [1, 0],
                "temperature_2m_max": [70.0, 72.0],
                "temperature_2m_min": [55.0, 56.0],
                "sunrise": ["2026-02-05T07:00", "2026-02-06T07:00"],
                "sunset": ["2026-02-05T17:30", "2026-02-06T17:31"],
                "precipitation_sum": [0.0, 0.0],
                "precipitation_probability_max": [10, 5],
                "wind_speed_10m_max": [15.0, 18.0],
                "wind_gusts_10m_max": [20.0, 25.0],
                "uv_index_max": [6.0, 7.0]
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode(WeatherData.self, from: data)
    }
}

// MARK: - Weather Data Model Tests

@MainActor
struct WeatherDataModelTests {
    
    @Test func decodesSampleData() {
        let weatherData = MockWeatherData.createSampleWeatherData()
        #expect(weatherData != nil)
    }
    
    @Test func currentWeatherValues() {
        guard let weatherData = MockWeatherData.createSampleWeatherData() else {
            Issue.record("Failed to create sample weather data")
            return
        }
        
        #expect(weatherData.current.temperature2m == 65.0)
        #expect(weatherData.current.apparentTemperature == 63.0)
        #expect(weatherData.current.weatherCode == 1)
        #expect(weatherData.current.isDay == 1)
        #expect(weatherData.current.relativeHumidity2m == 55)
    }
    
    @Test func dailyForecastValues() {
        guard let weatherData = MockWeatherData.createSampleWeatherData() else {
            Issue.record("Failed to create sample weather data")
            return
        }
        
        #expect(weatherData.daily.temperature2mMax.count == 2)
        #expect(weatherData.daily.temperature2mMin.count == 2)
        #expect(weatherData.daily.temperature2mMax[0] == 70.0)
        #expect(weatherData.daily.temperature2mMin[0] == 55.0)
    }
    
    @Test func hourlyForecastValues() {
        guard let weatherData = MockWeatherData.createSampleWeatherData() else {
            Issue.record("Failed to create sample weather data")
            return
        }
        
        #expect(weatherData.hourly.temperature2m.count == 2)
        #expect(weatherData.hourly.time.count == 2)
        #expect(weatherData.hourly.weatherCode.count == 2)
    }
}

// MARK: - Air Quality Data Tests

@MainActor
struct AirQualityDataTests {
    
    @Test func decodesAirQualityData() throws {
        let json = """
        {
            "latitude": 37.7749,
            "longitude": -122.4194,
            "timezone": "America/Los_Angeles",
            "current": {
                "time": "2026-02-05T12:00",
                "us_aqi": 45,
                "pm10": 15.0,
                "pm2_5": 8.0,
                "ozone": 30.0,
                "nitrogen_dioxide": 10.0,
                "sulphur_dioxide": 2.0,
                "carbon_monoxide": 200.0
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let airQuality = try decoder.decode(AirQualityData.self, from: data)
        
        #expect(airQuality.current.usAqi == 45)
        #expect(airQuality.current.pm25 == 8.0)
        #expect(airQuality.current.ozone == 30.0)
        #expect(airQuality.latitude == 37.7749)
        #expect(airQuality.timezone == "America/Los_Angeles")
    }
}
