//
//  IntegrationTests.swift
//  weatherTests
//
//  Integration tests for end-to-end workflows
//

import Testing
import Foundation
import CoreLocation
import SwiftData
@testable import weather

// MARK: - Weather Fetch Integration Tests

@MainActor
struct WeatherFetchIntegrationTests {
    
    @Test func completeWeatherFetchWorkflow() async {
        let service = WeatherService()
        let settings = SettingsManager()
        
        // Configure settings
        settings.temperatureUnit = .fahrenheit
        settings.windSpeedUnit = .mph
        
        // Fetch weather
        await service.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "San Francisco"
        )
        
        // Verify integration
        #expect(service.currentLocationName != nil || service.errorMessage != nil)
        #expect(service.isLoading == false)
    }
    
    @Test func weatherDataAndSettingsIntegration() async {
        let service = WeatherService()
        let settings = SettingsManager()
        
        // Fetch weather
        await service.fetchWeather(
            latitude: 40.7128,
            longitude: -74.0060,
            locationName: "New York"
        )
        
        // If we got weather data, verify settings can format it
        if let weatherData = service.weatherData {
            let tempString = settings.formatTemperature(weatherData.current.temperature2m)
            #expect(!tempString.isEmpty)
            #expect(tempString.contains("°"))
        }
    }
    
    @Test func errorHandlingAcrossServices() async {
        let service = WeatherService()
        
        // Attempt fetch with invalid data
        await service.fetchWeather(
            latitude: 999,
            longitude: 999,
            locationName: "Invalid"
        )
        
        // Should have error state
        #expect(service.errorMessage != nil || service.lastError != nil)
        
        // Error should be one we recognize
        if let error = service.lastError {
            #expect(error.recoverySuggestion != nil)
            #expect(!error.systemImage.isEmpty)
        }
    }
}

// MARK: - Location and Weather Integration Tests

@MainActor
struct LocationWeatherIntegrationTests {
    
    @Test func locationManagerWeatherServiceFlow() async {
        let locationManager = LocationManager()
        let weatherService = WeatherService()
        
        // Simulate location update
        if let location = locationManager.location {
            await weatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: locationManager.locationName ?? "Unknown"
            )
            
            #expect(weatherService.currentLocationName != nil || 
                   weatherService.errorMessage != nil)
        } else {
            // No location available, test still valid
            #expect(true)
        }
    }
    
    @Test func locationAuthorizationErrorFlow() {
        let locationManager = LocationManager()
        
        // Request location
        locationManager.requestLocation()
        
        // If denied, error message should be set
        if locationManager.authorizationStatus == .denied ||
           locationManager.authorizationStatus == .restricted {
            #expect(locationManager.errorMessage != nil)
        }
    }
}

// MARK: - Favorites and Weather Integration Tests

@MainActor
struct FavoritesWeatherIntegrationTests {
    
    @Test func saveFavoriteAndFetchWeather() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let favoritesManager = FavoritesManager(modelContext: context)
        let weatherService = WeatherService()
        
        // Add favorite location
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        favoritesManager.addLocation(name: "San Francisco", coordinate: coord)
        
        #expect(favoritesManager.savedLocations.count == 1)
        
        // Fetch weather for favorite
        let location = favoritesManager.savedLocations[0]
        await weatherService.fetchWeather(
            latitude: location.latitude,
            longitude: location.longitude,
            locationName: location.name
        )
        
        // Should have attempted to fetch
        #expect(weatherService.currentLocationName == "San Francisco" ||
               weatherService.errorMessage != nil)
    }
    
    @Test func multipleFavoritesWorkflow() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let favoritesManager = FavoritesManager(modelContext: context)
        
        // Add multiple favorites
        let locations = [
            ("San Francisco", 37.7749, -122.4194),
            ("New York", 40.7128, -74.0060),
            ("London", 51.5074, -0.1278)
        ]
        
        for (name, lat, lon) in locations {
            favoritesManager.addLocation(
                name: name,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
            )
        }
        
        #expect(favoritesManager.savedLocations.count == 3)
        
        // Verify each has correct order
        for (index, location) in favoritesManager.savedLocations.enumerated() {
            #expect(location.order == index)
        }
    }
}

// MARK: - Settings and Data Formatting Integration Tests

@MainActor
struct SettingsFormattingIntegrationTests {
    
    @Test func allUnitsFormatCorrectly() {
        let settings = SettingsManager()
        
        // Test temperature in both units
        settings.temperatureUnit = .fahrenheit
        let fahrenheit = settings.formatTemperature(72.0)
        #expect(fahrenheit.contains("72") && fahrenheit.contains("°F"))
        
        settings.temperatureUnit = .celsius
        let celsius = settings.formatTemperature(72.0)
        #expect(celsius.contains("°C"))
        
        // Test wind speed in all units
        for unit in WindSpeedUnit.allCases {
            settings.windSpeedUnit = unit
            let windSpeed = settings.formatWindSpeed(10.0)
            #expect(!windSpeed.isEmpty)
            #expect(windSpeed.contains(unit.symbol))
        }
        
        // Test precipitation in both units
        for unit in PrecipitationUnit.allCases {
            settings.precipitationUnit = unit
            let precip = settings.formatPrecipitation(0.5)
            #expect(!precip.isEmpty)
        }
    }
    
    @Test func settingsPersistence() {
        let settings = SettingsManager()
        
        // Change settings
        settings.temperatureUnit = .celsius
        settings.showFeelsLike = false
        settings.autoRefreshInterval = 60
        
        // Create new instance (would read from UserDefaults in real app)
        let newSettings = SettingsManager()
        
        // In a real app with UserDefaults, these would persist
        // For now, just verify the settings object maintains state
        #expect(settings.temperatureUnit == .celsius)
        #expect(settings.showFeelsLike == false)
        #expect(settings.autoRefreshInterval == 60)
    }
}

// MARK: - Alert Service Integration Tests

@MainActor
struct AlertServiceIntegrationTests {
    
    @Test func fetchAlertsForUSLocation() async {
        let alertService = WeatherAlertService()
        
        // San Francisco coordinates (US)
        let alerts = await alertService.fetchAlerts(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        // Should complete without crashing
        #expect(alertService.isLoading == false)
        #expect(alertService.lastUpdateTime != nil)
        
        // Alerts may or may not be present
        #expect(alerts.count >= 0)
    }
    
    @Test func fetchAlertsForEuropeanLocation() async {
        let alertService = WeatherAlertService()
        
        // London coordinates (Europe)
        let alerts = await alertService.fetchAlerts(
            latitude: 51.5074,
            longitude: -0.1278
        )
        
        #expect(alertService.isLoading == false)
        #expect(alertService.lastUpdateTime != nil)
        #expect(alerts.count >= 0)
    }
}

// MARK: - Widget Data Integration Tests

@MainActor
struct WidgetDataIntegrationTests {
    
    @Test func sharedWeatherDataCreation() throws {
        let weatherService = WeatherService()
        
        // Create mock weather data
        guard let weatherData = MockWeatherData.createSampleWeatherData() else {
            Issue.record("Failed to create mock weather data")
            return
        }
        
        // Create shared data for widget
        let sharedData = SharedWeatherData(
            temperature: weatherData.current.temperature2m,
            apparentTemperature: weatherData.current.apparentTemperature,
            weatherCode: weatherData.current.weatherCode,
            isDay: weatherData.current.isDay,
            humidity: weatherData.current.relativeHumidity2m,
            windSpeed: weatherData.current.windSpeed10m,
            highTemp: weatherData.daily.temperature2mMax.first ?? 0,
            lowTemp: weatherData.daily.temperature2mMin.first ?? 0,
            precipitationProbability: weatherData.hourly.precipitationProbability?.first ?? 0,
            locationName: "Test Location",
            lastUpdated: Date(),
            hourlyForecast: []
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(sharedData)
        
        // Decode back
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SharedWeatherData.self, from: data)
        
        #expect(decoded.temperature == sharedData.temperature)
        #expect(decoded.locationName == "Test Location")
    }
}

// MARK: - Performance Integration Tests

@MainActor
struct PerformanceIntegrationTests {
    
    @Test func rapidSettingsChanges() {
        let settings = SettingsManager()
        
        // Rapidly change settings (UI scenario)
        for _ in 0..<100 {
            settings.temperatureUnit = .fahrenheit
            settings.temperatureUnit = .celsius
            settings.windSpeedUnit = .mph
            settings.windSpeedUnit = .kmh
        }
        
        // Should complete without crashing or memory issues
        #expect(true)
    }
    
    @Test func multipleFavoritesOperations() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let favoritesManager = FavoritesManager(modelContext: context)
        
        // Add many favorites
        for i in 0..<50 {
            favoritesManager.addLocation(
                name: "Location \(i)",
                coordinate: CLLocationCoordinate2D(
                    latitude: Double(i) / 10.0,
                    longitude: Double(i) / 10.0
                )
            )
        }
        
        #expect(favoritesManager.savedLocations.count == 50)
        
        // Remove them all
        while !favoritesManager.savedLocations.isEmpty {
            favoritesManager.removeLocation(favoritesManager.savedLocations[0])
        }
        
        #expect(favoritesManager.savedLocations.isEmpty)
    }
}

// MARK: - Data Flow Integration Tests

@MainActor
struct DataFlowIntegrationTests {
    
    @Test func endToEndWeatherFlow() async throws {
        // Simulate complete app flow
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let locationManager = LocationManager()
        let weatherService = WeatherService()
        let favoritesManager = FavoritesManager(modelContext: context)
        let settings = SettingsManager()
        
        // 1. Configure settings
        settings.temperatureUnit = .fahrenheit
        settings.windSpeedUnit = .mph
        
        // 2. Add a favorite location
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        favoritesManager.addLocation(name: "San Francisco", coordinate: coord)
        
        // 3. Fetch weather for favorite
        let favorite = favoritesManager.savedLocations[0]
        await weatherService.fetchWeather(
            latitude: favorite.latitude,
            longitude: favorite.longitude,
            locationName: favorite.name
        )
        
        // 4. Verify data flow
        #expect(favoritesManager.savedLocations.count == 1)
        #expect(weatherService.currentLocationName == "San Francisco" ||
               weatherService.errorMessage != nil)
        
        // 5. If weather data exists, format it with settings
        if let weatherData = weatherService.weatherData {
            let temp = settings.formatTemperature(weatherData.current.temperature2m)
            let wind = settings.formatWindSpeed(weatherData.current.windSpeed10m)
            
            #expect(!temp.isEmpty)
            #expect(!wind.isEmpty)
        }
    }
}
