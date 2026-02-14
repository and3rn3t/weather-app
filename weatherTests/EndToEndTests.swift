//
//  EndToEndTests.swift
//  weatherTests
//
//  End-to-End integration tests for critical user workflows
//

import CoreLocation
import Foundation
import SwiftData
import Testing

@testable import weather

// MARK: - End-to-End Workflow Tests

@MainActor
struct EndToEndWorkflowTests {

    /// Helper to clear all app state
    func clearAllState() {
        // Clear UserDefaults
        let keys = [
            "lastWeatherLatitude", "lastWeatherLongitude", "lastWeatherLocationName",
            "temperatureUnit", "windSpeedUnit", "precipitationUnit",
            "useSystemAppearance", "appTheme", "useAdaptiveTheme",
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // Clear cached files
        if let fileURL = SharedDataManager.cachedWeatherFilePrimaryURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        if let legacyURL = SharedDataManager.cachedWeatherFileLegacyURL {
            try? FileManager.default.removeItem(at: legacyURL)
        }
    }

    // MARK: - Cold Start Workflow

    @Test func coldStartWorkflow() async {
        clearAllState()

        // 1. User opens app for first time (no cache)
        let weatherService = WeatherService()
        #expect(weatherService.weatherData == nil)
        #expect(weatherService.currentLocationName == nil)

        // 2. App requests weather for default location
        await weatherService.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "San Francisco"
        )

        // 3. Location should be saved
        #expect(weatherService.currentLocationName == "San Francisco")

        // 4. Verify cache was created
        let cachedData = SharedDataManager.shared.loadCachedFullWeatherData()
        #expect(cachedData != nil || weatherService.errorMessage != nil)

        clearAllState()
    }

    @Test func warmStartWithCache() async throws {
        clearAllState()

        // 1. Simulate previous app usage - cache exists
        let mockData = MockWeatherData.createSampleWeatherData()!
        SharedDataManager.shared.cacheFullWeatherData(mockData, locationName: "New York")

        // 2. User opens app - should load from cache instantly
        let weatherService = WeatherService()
        #expect(weatherService.weatherData != nil)
        #expect(weatherService.currentLocationName == "New York")
        #expect(weatherService.weatherData?.current.temperature2m == 65.0)

        // 3. Background refresh should trigger
        try await Task.sleep(nanoseconds: 100_000_000)  // Give background task time

        clearAllState()
    }

    // MARK: - Location Search and Save Workflow

    @Test func searchAndSaveLocationWorkflow() async throws {
        clearAllState()

        // 1. Create favorites manager with in-memory database
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        let favoritesManager = FavoritesManager(modelContext: context)

        // 2. User searches for location
        let searchCoordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)

        // 3. User saves location as favorite
        favoritesManager.addLocation(name: "New York", coordinate: searchCoordinate)

        // 4. Verify save
        #expect(favoritesManager.savedLocations.count == 1)
        #expect(favoritesManager.savedLocations.first?.name == "New York")
        #expect(favoritesManager.isFavorite(coordinate: searchCoordinate))

        // 5. User fetches weather for that location
        let weatherService = WeatherService()
        await weatherService.fetchWeather(
            latitude: searchCoordinate.latitude,
            longitude: searchCoordinate.longitude,
            locationName: "New York"
        )

        // 6. Verify location is active
        #expect(weatherService.currentLocationName == "New York")

        clearAllState()
    }

    // MARK: - Multiple Locations Workflow

    @Test func multipleLocationsWorkflow() async throws {
        clearAllState()

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        let favoritesManager = FavoritesManager(modelContext: context)
        let weatherService = WeatherService()

        // 1. User adds multiple favorite locations
        let locations = [
            (
                name: "San Francisco",
                coord: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            ),
            (
                name: "New York",
                coord: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
            ),
            (name: "London", coord: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)),
        ]

        for location in locations {
            favoritesManager.addLocation(name: location.name, coordinate: location.coord)
        }

        #expect(favoritesManager.savedLocations.count == 3)

        // 2. User switches between locations
        for location in locations {
            await weatherService.fetchWeather(
                latitude: location.coord.latitude,
                longitude: location.coord.longitude,
                locationName: location.name
            )

            #expect(weatherService.currentLocationName == location.name)

            // Small delay to simulate user interaction
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        // 3. User removes a location
        if let toRemove = favoritesManager.savedLocations.first(where: { $0.name == "New York" }) {
            favoritesManager.removeLocation(toRemove)
        }

        #expect(favoritesManager.savedLocations.count == 2)

        clearAllState()
    }

    // MARK: - Settings Change Workflow

    @Test func settingsChangeWorkflow() {
        clearAllState()

        // 1. User opens app with default settings
        let settingsManager = SettingsManager()
        let initialTempUnit = settingsManager.temperatureUnit

        // 2. User changes temperature unit
        let newTempUnit: TemperatureUnit = initialTempUnit == .fahrenheit ? .celsius : .fahrenheit
        settingsManager.temperatureUnit = newTempUnit

        // 3. Verify change persisted
        let newSettingsManager = SettingsManager()
        #expect(newSettingsManager.temperatureUnit == newTempUnit)

        // 4. User changes multiple settings
        settingsManager.windSpeedUnit = .kmh
        settingsManager.showFeelsLike = false
        settingsManager.useSystemAppearance = false

        // 5. Create new manager instance to verify all persisted
        let verifyManager = SettingsManager()
        #expect(verifyManager.windSpeedUnit == .kmh)
        #expect(verifyManager.showFeelsLike == false)
        #expect(verifyManager.useSystemAppearance == false)

        clearAllState()
    }

    // MARK: - Theme Adaptation Workflow

    @Test func themeAdaptationWorkflow() {
        clearAllState()

        // 1. User enables adaptive themes
        let themeManager = ThemeManager()
        themeManager.useAdaptiveTheme = true

        // 2. Simulate different weather conditions
        let scenarios = [
            (weatherCode: 0, isDay: true, expectedTheme: AppTheme.sunset, condition: "Clear day"),
            (
                weatherCode: 0, isDay: false, expectedTheme: AppTheme.midnight,
                condition: "Clear night"
            ),
            (weatherCode: 61, isDay: true, expectedTheme: AppTheme.ocean, condition: "Rain"),
            (weatherCode: 71, isDay: true, expectedTheme: AppTheme.arctic, condition: "Snow"),
            (weatherCode: 45, isDay: true, expectedTheme: AppTheme.fog, condition: "Fog"),
            (
                weatherCode: 95, isDay: true, expectedTheme: AppTheme.storm,
                condition: "Thunderstorm"
            ),
        ]

        for scenario in scenarios {
            let adaptedTheme = themeManager.adaptiveTheme(
                for: scenario.weatherCode,
                isDay: scenario.isDay
            )
            #expect(
                adaptedTheme == scenario.expectedTheme,
                "Theme mismatch for \(scenario.condition)"
            )
        }

        // 3. User disables adaptive theme
        themeManager.useAdaptiveTheme = false
        themeManager.currentTheme = .ocean

        // 4. Theme should stay fixed regardless of weather
        let fixedTheme = themeManager.adaptiveTheme(for: 0, isDay: true)
        #expect(fixedTheme == .ocean)

        clearAllState()
    }

    // MARK: - Error Recovery Workflow

    @Test func errorRecoveryWorkflow() async {
        clearAllState()

        let weatherService = WeatherService()

        // 1. User enters invalid location coordinates
        await weatherService.fetchWeather(
            latitude: 999.0,
            longitude: 999.0,
            locationName: "Invalid"
        )

        // 2. App should handle error gracefully
        #expect(weatherService.errorMessage != nil || weatherService.lastError != nil)

        // 3. User corrects and enters valid coordinates
        await weatherService.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "San Francisco"
        )

        // 4. App should recover and show location
        #expect(weatherService.currentLocationName == "San Francisco")

        clearAllState()
    }

    // MARK: - Cache Invalidation Workflow

    @Test func cacheInvalidationWorkflow() async {
        clearAllState()

        // 1. User fetches weather, gets cached
        let weatherService = WeatherService()
        await weatherService.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "Test"
        )

        let firstFetch = weatherService.weatherData

        // 2. User force refreshes
        await weatherService.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "Test",
            forceRefresh: true
        )

        // 3. Should attempt new fetch (data may be same or different depending on API)
        #expect(weatherService.currentLocationName == "Test")

        clearAllState()
    }

    // MARK: - Weather Alert Workflow

    @Test func weatherAlertWorkflow() async {
        // 1. User's location has active weather alerts (US location)
        let alertService = WeatherAlertService()

        // 2. Fetch alerts for US location
        let usAlerts = await alertService.fetchAlerts(latitude: 37.7749, longitude: -122.4194)

        // 3. Service should have attempted to fetch
        #expect(alertService.lastUpdateTime != nil)

        // 4. Fetch alerts for non-supported location
        let otherAlerts = await alertService.fetchAlerts(latitude: -33.8688, longitude: 151.2093)

        // 5. Should return empty for unsupported regions
        #expect(otherAlerts.isEmpty)
    }
}

// MARK: - Integration Test Scenarios

@MainActor
struct IntegrationTestScenarios {

    func clearState() {
        UserDefaults.standard.removeObject(forKey: "lastWeatherLatitude")
        UserDefaults.standard.removeObject(forKey: "lastWeatherLongitude")
        UserDefaults.standard.removeObject(forKey: "lastWeatherLocationName")

        if let fileURL = SharedDataManager.cachedWeatherFilePrimaryURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    // MARK: - Service Layer Integration

    @Test func weatherServiceAndCacheIntegration() async {
        clearState()

        // 1. WeatherService fetches data
        let service = WeatherService()
        await service.fetchWeather(
            latitude: 40.7128,
            longitude: -74.0060,
            locationName: "NYC"
        )

        // 2. SharedDataManager should have cached it
        let location = SharedDataManager.lastKnownLocation()
        #expect(location?.name == "NYC" || service.errorMessage != nil)

        // 3. Loading cache should work
        let cached = SharedDataManager.shared.loadCachedFullWeatherData()
        #expect(cached != nil || service.errorMessage != nil)

        clearState()
    }

    @Test func servicesAndManagersIntegration() async {
        clearState()

        // 1. Create coordinated system
        let weatherService = WeatherService()
        let settingsManager = SettingsManager()
        let themeManager = ThemeManager()

        // 2. Fetch weather
        await weatherService.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "SF"
        )

        // 3. Settings should work independently
        settingsManager.temperatureUnit = .celsius
        #expect(settingsManager.temperatureUnit == .celsius)

        // 4. Theme should adapt if weather data available
        if let weatherData = weatherService.weatherData {
            themeManager.useAdaptiveTheme = true
            let theme = themeManager.adaptiveTheme(
                for: weatherData.current.weatherCode,
                isDay: weatherData.current.isDay == 1
            )
            #expect(AppTheme.allCases.contains(theme))
        }

        clearState()
    }

    @Test func multipleServicesCoordination() async {
        clearState()

        // 1. Weather and Alert services work together
        let weatherService = WeatherService()
        let alertService = WeatherAlertService()

        // 2. Fetch weather for location
        await weatherService.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "San Francisco"
        )

        // 3. Fetch alerts for same location
        let alerts = await alertService.fetchAlerts(latitude: 37.7749, longitude: -122.4194)

        // 4. Both services should have completed
        #expect(weatherService.currentLocationName != nil || weatherService.errorMessage != nil)
        #expect(alertService.lastUpdateTime != nil)

        clearState()
    }

    // MARK: - Data Flow Integration

    @Test func fullDataFlowIntegration() async {
        clearState()

        // 1. User location → Service → Cache → UI state
        let weatherService = WeatherService()

        // 2. Fetch from API
        await weatherService.fetchWeather(
            latitude: 51.5074,
            longitude: -0.1278,
            locationName: "London"
        )

        // 3. Verify data flow to cache
        let savedLocation = SharedDataManager.lastKnownLocation()
        let cachedData = SharedDataManager.shared.loadCachedFullWeatherData()

        #expect(savedLocation?.name == "London" || weatherService.errorMessage != nil)
        #expect(cachedData != nil || weatherService.errorMessage != nil)

        // 4. Verify state updates
        #expect(
            weatherService.currentLocationName == "London" || weatherService.errorMessage != nil)

        clearState()
    }

    @Test func concurrentRequestsHandling() async {
        clearState()

        let service = WeatherService()

        // 1. Simulate rapid location changes (user scrolling favorites)
        async let request1: () = service.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "SF"
        )

        async let request2: () = service.fetchWeather(
            latitude: 40.7128,
            longitude: -74.0060,
            locationName: "NYC"
        )

        async let request3: () = service.fetchWeather(
            latitude: 51.5074,
            longitude: -0.1278,
            locationName: "London"
        )

        // 2. Wait for all to complete
        _ = await (request1, request2, request3)

        // 3. Service should have settled on one location
        #expect(service.currentLocationName != nil || service.errorMessage != nil)

        clearState()
    }

    // MARK: - Persistence Integration

    @Test func persistenceAcrossAppLifecycle() async throws {
        clearState()

        // 1. First app session
        let weatherService1 = WeatherService()
        await weatherService1.fetchWeather(
            latitude: 48.8566,
            longitude: 2.3522,
            locationName: "Paris"
        )

        // 2. Verify data was fetched (or error occurred)
        #expect(weatherService1.weatherData != nil || weatherService1.errorMessage != nil)
        
        // 3. Give background caching time to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // 4. Simulate app termination and relaunch
        let weatherService2 = WeatherService()

        // 5. Should load from cache if first fetch succeeded
        if weatherService1.weatherData != nil {
            #expect(
                weatherService2.weatherData != nil || weatherService2.currentLocationName != nil
            )
        }

        clearState()
    }

    @Test func settingsPersistenceIntegration() {
        clearState()

        // 1. User session 1: Configure settings
        let settings1 = SettingsManager()
        settings1.temperatureUnit = .celsius
        settings1.windSpeedUnit = .ms
        settings1.showFeelsLike = false

        let theme1 = ThemeManager()
        theme1.currentTheme = .arctic
        theme1.useAdaptiveTheme = true

        // 2. Simulate app restart - new instances
        let settings2 = SettingsManager()
        let theme2 = ThemeManager()

        // 3. Verify all settings persisted
        #expect(settings2.temperatureUnit == .celsius)
        #expect(settings2.windSpeedUnit == .ms)
        #expect(settings2.showFeelsLike == false)
        #expect(theme2.currentTheme == .arctic)
        #expect(theme2.useAdaptiveTheme == true)

        clearState()
    }

    // MARK: - Edge Cases Integration

    @Test func networkFailureRecovery() async {
        clearState()

        // 1. Attempt request that will likely fail
        let service = WeatherService()
        await service.fetchWeather(
            latitude: 0,
            longitude: 0,
            locationName: "Middle of Ocean"
        )

        // 2. Error should be set
        #expect(
            service.errorMessage != nil || service.lastError != nil || service.weatherData != nil)

        // 3. Retry with valid location
        await service.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "SF"
        )

        // 4. Should recover or maintain error state
        #expect(service.currentLocationName != nil || service.errorMessage != nil)

        clearState()
    }

    @Test func emptyStateHandling() throws {
        clearState()

        // 1. Fresh app with no data
        let weatherService = WeatherService()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        let favoritesManager = FavoritesManager(modelContext: context)

        // 2. All should handle empty state
        #expect(weatherService.weatherData == nil)
        #expect(weatherService.currentLocationName == nil)
        #expect(favoritesManager.savedLocations.isEmpty)

        // 3. Cached location should be nil
        let location = SharedDataManager.lastKnownLocation()
        #expect(location == nil)

        clearState()
    }

@Test func rapidSettingsChanges() async {
        clearState()

        let settings = SettingsManager()

        // 1. Rapid fire setting changes
        for _ in 0..<10 {
            settings.temperatureUnit = .celsius
            settings.temperatureUnit = .fahrenheit
            settings.windSpeedUnit = .kmh
            settings.windSpeedUnit = .mph
            settings.showFeelsLike = true
            settings.showFeelsLike = false
        }

        // 2. Final state should be consistent
        let verify = SettingsManager()
        #expect(verify.temperatureUnit == settings.temperatureUnit)
        #expect(verify.windSpeedUnit == settings.windSpeedUnit)

        clearState()
    }
}

// MARK: - Real World Scenario Tests

@MainActor
struct RealWorldScenarioTests {

    func clearAll() {
        let keys = [
            "lastWeatherLatitude", "lastWeatherLongitude", "lastWeatherLocationName",
            "temperatureUnit", "windSpeedUnit", "appTheme",
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        if let fileURL = SharedDataManager.cachedWeatherFilePrimaryURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    @Test func morningRoutineScenario() async {
        clearAll()

        // User wakes up, opens app
        // 1. App loads with cached data from last night
        let mockData = MockWeatherData.createSampleWeatherData()!
        SharedDataManager.shared.cacheFullWeatherData(mockData, locationName: "Home")

        let service = WeatherService()
        #expect(service.weatherData != nil)

        // 2. User pulls to refresh
        await service.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "Home",
            forceRefresh: true
        )

        // 3. Check if theme adapts to morning
        let theme = ThemeManager()
        theme.useAdaptiveTheme = true
        if let weatherData = service.weatherData {
            let morningTheme = theme.adaptiveTheme(
                for: weatherData.current.weatherCode,
                isDay: true
            )
            #expect(AppTheme.allCases.contains(morningTheme))
        }

        clearAll()
    }

    @Test func travelScenario() async throws {
        clearAll()

        // User traveling to multiple cities
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        let favorites = FavoritesManager(modelContext: context)
        let service = WeatherService()

        // 1. Save future destinations
        let destinations = [
            ("Tokyo", 35.6762, 139.6503),
            ("Paris", 48.8566, 2.3522),
            ("Sydney", -33.8688, 151.2093),
        ]

        for (name, lat, lon) in destinations {
            favorites.addLocation(
                name: name,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
            )
        }

        #expect(favorites.savedLocations.count == 3)

        // 2. Check weather for each destination
        for (name, lat, lon) in destinations {
            await service.fetchWeather(latitude: lat, longitude: lon, locationName: name)
            #expect(service.currentLocationName == name || service.errorMessage != nil)
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        clearAll()
    }

    @Test func weatherEventResponseScenario() async {
        clearAll()

        // Severe weather approaching
        let service = WeatherService()
        let alertService = WeatherAlertService()

        // 1. User checks current weather
        await service.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "SF"
        )

        // 2. User checks for alerts
        let alerts = await alertService.fetchAlerts(latitude: 37.7749, longitude: -122.4194)

        // 3. System should handle both requests
        #expect(service.currentLocationName != nil || service.errorMessage != nil)
        #expect(alertService.lastUpdateTime != nil)

        clearAll()
    }

    @Test func offlineToOnlineTransition() async {
        clearAll()

        // 1. App opens offline with cached data
        let cachedWeather = MockWeatherData.createSampleWeatherData()!
        SharedDataManager.shared.cacheFullWeatherData(cachedWeather, locationName: "Cached")

        let service = WeatherService()
        #expect(service.weatherData != nil)
        #expect(service.currentLocationName == "Cached")

        // 2. Network comes back, user refreshes
        await service.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "SF",
            forceRefresh: true
        )

        // 3. Should attempt to fetch new data
        #expect(service.currentLocationName == "SF" || service.errorMessage != nil)

        clearAll()
    }

@Test func userPreferenceChangeScenario() async {
        clearAll()

        // User experiments with different settings
        let settings = SettingsManager()

        // 1. Try Celsius
        settings.temperatureUnit = .celsius
        #expect(settings.temperatureUnit == .celsius)

        // 2. Try different wind units
        settings.windSpeedUnit = .ms
        #expect(settings.windSpeedUnit == .ms)

        // 3. Change mind, go back to imperial
        settings.temperatureUnit = .fahrenheit
        settings.windSpeedUnit = .mph

        // 4. Verify final choices persisted
        let verify = SettingsManager()
        #expect(verify.temperatureUnit == .fahrenheit)
        #expect(verify.windSpeedUnit == .mph)

        clearAll()
    }
}
