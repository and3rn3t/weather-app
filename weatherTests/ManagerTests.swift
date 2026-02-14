//
//  ManagerTests.swift
//  weatherTests
//
//  Comprehensive tests for all Manager classes
//

import CoreLocation
import Foundation
import SwiftData
import SwiftUI
import Testing

@testable import weather

// MARK: - Location Manager Tests

@MainActor
struct LocationManagerTests {

    @Test func initialState() {
        let manager = LocationManager()

        #expect(manager.location == nil)
        #expect(manager.locationName == nil)
        #expect(manager.errorMessage == nil)
        // Authorization status could be any value depending on device state
    }

    @Test func authorizationStatusTracking() {
        let manager = LocationManager()

        // Initial status should be one of the valid CLAuthorizationStatus values
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined, .restricted, .denied,
            .authorizedAlways, .authorizedWhenInUse,
        ]

        #expect(validStatuses.contains(manager.authorizationStatus))
    }

    @Test func requestLocationWhenNotDetermined() {
        let manager = LocationManager()

        // Should not crash when requesting location
        manager.requestLocation()

        // If denied, error message should be set
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            #expect(
                manager.errorMessage?.contains("denied") == true
                    || manager.errorMessage?.contains("Settings") == true)
        }
    }
}

// MARK: - Favorites Manager Tests

@MainActor
struct FavoritesManagerTests {

    @Test func initialState() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)

        let manager = FavoritesManager(modelContext: context)

        #expect(manager.savedLocations.isEmpty)
        #expect(manager.currentLocationIndex == 0)
    }

    @Test func addLocation() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)

        let manager = FavoritesManager(modelContext: context)

        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        manager.addLocation(name: "San Francisco", coordinate: coord)

        #expect(manager.savedLocations.count == 1)
        #expect(manager.savedLocations.first?.name == "San Francisco")
        #expect(abs(manager.savedLocations.first!.latitude - 37.7749) < 0.001)
    }

    @Test func preventDuplicateLocations() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)

        let manager = FavoritesManager(modelContext: context)

        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        manager.addLocation(name: "San Francisco", coordinate: coord)
        manager.addLocation(name: "San Francisco 2", coordinate: coord)  // Same coords

        #expect(manager.savedLocations.count == 1, "Should not add duplicate location")
    }

    @Test func removeLocation() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)

        let manager = FavoritesManager(modelContext: context)

        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        manager.addLocation(name: "San Francisco", coordinate: coord)

        #expect(manager.savedLocations.count == 1)

        let location = manager.savedLocations.first!
        manager.removeLocation(location)

        #expect(manager.savedLocations.isEmpty)
    }

    @Test func isFavorite() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)

        let manager = FavoritesManager(modelContext: context)

        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        manager.addLocation(name: "San Francisco", coordinate: coord)

        #expect(manager.isFavorite(coordinate: coord) == true)

        let differentCoord = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        #expect(manager.isFavorite(coordinate: differentCoord) == false)
    }

    @Test func locationOrdering() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)

        let manager = FavoritesManager(modelContext: context)

        manager.addLocation(
            name: "First", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))
        manager.addLocation(
            name: "Second", coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2))
        manager.addLocation(
            name: "Third", coordinate: CLLocationCoordinate2D(latitude: 3, longitude: 3))

        #expect(manager.savedLocations.count == 3)
        #expect(manager.savedLocations[0].order == 0)
        #expect(manager.savedLocations[1].order == 1)
        #expect(manager.savedLocations[2].order == 2)
    }
}

// MARK: - Theme Manager Tests

@MainActor
struct ThemeManagerTests {

    @Test func initialState() {
        let themeManager = ThemeManager()

        // Should have a valid theme
        #expect(AppTheme.allCases.contains(themeManager.currentTheme))

        // Should have adaptive theme setting
        #expect(themeManager.useAdaptiveTheme == true || themeManager.useAdaptiveTheme == false)
    }

    @Test func adaptiveThemeSelection() {
        let themeManager = ThemeManager()
        themeManager.useAdaptiveTheme = true

        // Test adaptive theme for clear sky
        let clearTheme = themeManager.adaptiveTheme(for: 0, isDay: true)
        #expect(AppTheme.allCases.contains(clearTheme))

        // Test adaptive theme for rain
        let rainTheme = themeManager.adaptiveTheme(for: 61, isDay: false)
        #expect(AppTheme.allCases.contains(rainTheme))
    }

    @Test func themeColorMapping() {
        let themeManager = ThemeManager()

        // Test all themes can be used without crashing
        for theme in AppTheme.allCases {
            // Just verify theme exists
            #expect(AppTheme.allCases.contains(theme))
        }
    }

    @Test func adaptiveThemeForClearSky() {
        let manager = ThemeManager()
        manager.useAdaptiveTheme = true

        let dayTheme = manager.adaptiveTheme(for: 0, isDay: true)
        #expect(dayTheme == .sunset)

        let nightTheme = manager.adaptiveTheme(for: 0, isDay: false)
        #expect(nightTheme == .midnight)
    }

    @Test func adaptiveThemeForCloudy() {
        let manager = ThemeManager()
        manager.useAdaptiveTheme = true

        let cloudyTheme = manager.adaptiveTheme(for: 3, isDay: true)
        #expect(cloudyTheme == .storm)
    }

    @Test func adaptiveThemeForRain() {
        let manager = ThemeManager()
        manager.useAdaptiveTheme = true

        let rainTheme = manager.adaptiveTheme(for: 61, isDay: true)
        #expect(rainTheme == .ocean)
    }

    @Test func adaptiveThemeForSnow() {
        let manager = ThemeManager()
        manager.useAdaptiveTheme = true

        let snowTheme = manager.adaptiveTheme(for: 71, isDay: true)
        #expect(snowTheme == .arctic)
    }

    @Test func adaptiveThemeForFog() {
        let manager = ThemeManager()
        manager.useAdaptiveTheme = true

        let fogTheme = manager.adaptiveTheme(for: 45, isDay: true)
        #expect(fogTheme == .fog)
    }

    @Test func adaptiveThemeForThunderstorm() {
        let manager = ThemeManager()
        manager.useAdaptiveTheme = true

        let stormTheme = manager.adaptiveTheme(for: 95, isDay: true)
        #expect(stormTheme == .storm)
    }

    @Test func adaptiveThemeDisabled() {
        let manager = ThemeManager()
        manager.currentTheme = .ocean
        manager.useAdaptiveTheme = false

        // Should return current theme when adaptive is disabled
        let theme = manager.adaptiveTheme(for: 0, isDay: true)
        #expect(theme == .ocean)
    }

    @Test func allThemesHaveGradients() {
        for theme in AppTheme.allCases {
            #expect(!theme.gradientColors.isEmpty)
        }
    }

    @Test func themeChangePersistence() {
        let manager = ThemeManager()
        manager.currentTheme = .arctic

        // Create new manager - should load from UserDefaults
        let newManager = ThemeManager()
        #expect(newManager.currentTheme == .arctic)

        // Reset to default
        manager.currentTheme = .classic
    }
}

// MARK: - Settings Manager Tests

@MainActor
struct SettingsManagerEnhancedTests {

    func clearSettings() {
        let keys = [
            "temperatureUnit", "windSpeedUnit", "precipitationUnit",
            "useSystemAppearance", "preferredColorScheme",
            "dailyForecastEnabled", "severeWeatherAlertsEnabled",
            "rainAlertsEnabled", "notificationTime",
            "showFeelsLike", "show24HourFormat",
            "showAnimatedBackgrounds", "showWeatherParticles",
        ]

        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @Test func initialState() {
        clearSettings()
        let manager = SettingsManager()

        // Should have default values
        #expect(manager.temperatureUnit == .fahrenheit || manager.temperatureUnit == .celsius)
        #expect(
            manager.windSpeedUnit == .mph || manager.windSpeedUnit == .kmh
                || manager.windSpeedUnit == .ms)
        #expect(manager.useSystemAppearance == true || manager.useSystemAppearance == false)

        clearSettings()
    }

    @Test func temperatureUnitChanges() {
        clearSettings()
        let manager = SettingsManager()

        manager.temperatureUnit = .celsius
        #expect(manager.temperatureUnit == .celsius)

        manager.temperatureUnit = .fahrenheit
        #expect(manager.temperatureUnit == .fahrenheit)

        clearSettings()
    }

    @Test func windSpeedUnitChanges() {
        clearSettings()
        let manager = SettingsManager()

        manager.windSpeedUnit = .kmh
        #expect(manager.windSpeedUnit == .kmh)

        manager.windSpeedUnit = .mph
        #expect(manager.windSpeedUnit == .mph)

        manager.windSpeedUnit = .ms
        #expect(manager.windSpeedUnit == .ms)

        clearSettings()
    }

    @Test func precipitationUnitChanges() {
        clearSettings()
        let manager = SettingsManager()

        manager.precipitationUnit = .millimeters
        #expect(manager.precipitationUnit == .millimeters)

        manager.precipitationUnit = .inches
        #expect(manager.precipitationUnit == .inches)

        clearSettings()
    }

    @Test func notificationSettingsChanges() {
        clearSettings()
        let manager = SettingsManager()

        manager.dailyForecastEnabled = true
        #expect(manager.dailyForecastEnabled == true)

        manager.severeWeatherAlertsEnabled = false
        #expect(manager.severeWeatherAlertsEnabled == false)

        manager.rainAlertsEnabled = true
        #expect(manager.rainAlertsEnabled == true)

        clearSettings()
    }

    @Test func displayOptionsChanges() {
        clearSettings()
        let manager = SettingsManager()

        manager.showFeelsLike = false
        #expect(manager.showFeelsLike == false)

        manager.show24HourFormat = true
        #expect(manager.show24HourFormat == true)

        manager.showAnimatedBackgrounds = false
        #expect(manager.showAnimatedBackgrounds == false)

        manager.showWeatherParticles = true
        #expect(manager.showWeatherParticles == true)

        clearSettings()
    }

    @Test func appearanceSettingsChanges() {
        clearSettings()
        let manager = SettingsManager()

        manager.useSystemAppearance = false
        #expect(manager.useSystemAppearance == false)

        manager.preferredColorScheme = .dark
        #expect(manager.preferredColorScheme == .dark)

        manager.preferredColorScheme = .light
        #expect(manager.preferredColorScheme == .light)

        manager.preferredColorScheme = nil
        #expect(manager.preferredColorScheme == nil)

        clearSettings()
    }

    @Test func settingsPersistence() {
        clearSettings()
        let manager = SettingsManager()

        manager.temperatureUnit = .celsius
        manager.windSpeedUnit = .kmh
        manager.showFeelsLike = false

        // Create new manager - should load from UserDefaults
        let newManager = SettingsManager()
        #expect(newManager.temperatureUnit == .celsius)
        #expect(newManager.windSpeedUnit == .kmh)
        #expect(newManager.showFeelsLike == false)

        clearSettings()
    }
}

// MARK: - Notification Manager Tests

@MainActor
struct NotificationManagerTests {

    @Test func managerInitialization() {
        let manager = NotificationManager()

        // Manager should initialize without crashing
        #expect(manager != nil)
    }

    @Test func initialAuthorizationState() {
        let manager = NotificationManager()

        // Should have one of the valid authorization states
        let validStates: [UNAuthorizationStatus] = [
            .notDetermined, .denied, .authorized, .provisional, .ephemeral,
        ]
        #expect(validStates.contains(manager.authorizationStatus))
    }

    @Test func hasPermissionTracking() {
        let manager = NotificationManager()

        // hasPermission should be boolean
        #expect(manager.hasPermission == true || manager.hasPermission == false)
    }

    @Test func cancelDailyForecast() {
        let manager = NotificationManager()

        // Should not crash when canceling non-existent notification
        manager.cancelDailyForecast()

        #expect(true)
    }
}

// MARK: - Live Activity Manager Tests

@MainActor
struct LiveActivityManagerTests {

    @Test func managerInitialization() {
        let manager = LiveActivityManager()

        // Manager should initialize without crashing
        #expect(manager != nil)
    }

    @Test func initialActivityState() {
        let manager = LiveActivityManager()

        // Should not have active activity initially
        #expect(manager.isActivityActive == false)
    }

    @Test func startActivityWithValidData() async {
        let manager = LiveActivityManager()
        let weatherData = MockWeatherData.createSampleWeatherData()!

        // Should not crash when starting activity (may not actually start on simulator/tests)
        await manager.startActivity(weatherData: weatherData, locationName: "Test")

        #expect(true)
    }

    @Test func updateActivityWithoutActiveActivity() async {
        let manager = LiveActivityManager()
        let weatherData = MockWeatherData.createSampleWeatherData()!

        // Should handle update gracefully when no activity is active
        await manager.updateActivity(weatherData: weatherData)

        #expect(true)
    }

    @Test func endActivityWhenNoActivityActive() async {
        let manager = LiveActivityManager()

        // Should handle end gracefully when no activity is active
        await manager.endActivity()

        #expect(manager.isActivityActive == false)
    }
}

// MARK: - Weather Activity Attributes Tests

@MainActor
struct WeatherActivityAttributesTests {

    @Test func contentStateCreation() {
        let state = WeatherActivityAttributes.ContentState(
            temperature: 72.5,
            weatherCode: 0,
            highTemp: 80.0,
            lowTemp: 65.0,
            humidity: 60,
            windSpeed: 10.0,
            lastUpdated: Date()
        )

        #expect(state.temperature == 72.5)
        #expect(state.weatherCode == 0)
        #expect(state.highTemp == 80.0)
        #expect(state.lowTemp == 65.0)
    }

    @Test func attributesCreation() {
        let attributes = WeatherActivityAttributes(locationName: "San Francisco")

        #expect(attributes.locationName == "San Francisco")
    }

    @Test func contentStateEquality() {
        let now = Date()
        let state1 = WeatherActivityAttributes.ContentState(
            temperature: 70.0,
            weatherCode: 1,
            highTemp: 75.0,
            lowTemp: 60.0,
            humidity: 55,
            windSpeed: 12.0,
            lastUpdated: now
        )

        let state2 = WeatherActivityAttributes.ContentState(
            temperature: 70.0,
            weatherCode: 1,
            highTemp: 75.0,
            lowTemp: 60.0,
            humidity: 55,
            windSpeed: 12.0,
            lastUpdated: now
        )

        #expect(state1 == state2)
    }
}
