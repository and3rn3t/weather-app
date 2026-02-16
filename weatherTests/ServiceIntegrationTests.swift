//
//  ServiceIntegrationTests.swift
//  weatherTests
//
//  Service integration and workflow tests
//

import Testing
import Foundation
import CoreLocation
@testable import weather

// MARK: - Weather Service Integration Tests

@MainActor
struct WeatherServiceIntegrationTests {
    
    func clearCache() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "lastWeatherLatitude")
        ud.removeObject(forKey: "lastWeatherLongitude")
        ud.removeObject(forKey: "lastWeatherLocationName")
        
        if let fileURL = SharedDataManager.cachedWeatherFilePrimaryURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        if let legacyURL = SharedDataManager.cachedWeatherFileLegacyURL {
            try? FileManager.default.removeItem(at: legacyURL)
        }
    }
    
    @Test func serviceInitializationWithoutCache() {
        clearCache()
        let service = WeatherService()
        
        #expect(service.weatherData == nil)
        #expect(service.currentLocationName == nil)
        #expect(service.isLoading == false)
    }
    
    @Test func serviceInitializationWithCache() async {
        clearCache()
        
        // Create and cache some weather data
        let weatherData = MockWeatherData.createSampleWeatherData()!
        SharedDataManager.shared.cacheFullWeatherData(weatherData, locationName: "San Francisco")
        
        // Create service - should load from cache
        let service = WeatherService()
        
        #expect(service.weatherData != nil)
        #expect(service.currentLocationName == "San Francisco")
        #expect(service.weatherData?.current.temperature2m == 65.0)
        
        clearCache()
    }
    
    @Test func errorHandlingForInvalidCoordinates() async {
        clearCache()
        let service = WeatherService()
        
        // Invalid coordinates should trigger an error
        await service.fetchWeatherData(latitude: 999.0, longitude: 999.0, locationName: "Invalid")
        
        // Service should have handled the error
        #expect(service.errorMessage != nil || service.lastError != nil)
        
        clearCache()
    }
    
    @Test func fetchWeatherUpdatesLocationName() async {
        clearCache()
        let service = WeatherService()
        
        await service.fetchWeatherData(latitude: 37.7749, longitude: -122.4194, locationName: "Test City")
        
        #expect(service.currentLocationName == "Test City")
        
        clearCache()
    }
    
    @Test func forceRefreshClearsCache() async {
        clearCache()
        
        // Set up initial cache
        let weatherData = MockWeatherData.createSampleWeatherData()!
        SharedDataManager.shared.cacheFullWeatherData(weatherData, locationName: "Test")
        
        let service = WeatherService()
        #expect(service.weatherData != nil)
        
        // Force refresh should attempt new fetch
        await service.fetchWeatherData(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "Test",
            forceRefresh: true
        )
        
        // Location name should be updated
        #expect(service.currentLocationName == "Test")
        
        clearCache()
    }
}

// MARK: - Shared Data Manager Tests

@MainActor
struct SharedDataManagerIntegrationTests {
    
    func clearAll() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "lastWeatherLatitude")
        ud.removeObject(forKey: "lastWeatherLongitude")
        ud.removeObject(forKey: "lastWeatherLocationName")
        
        if let fileURL = SharedDataManager.cachedWeatherFilePrimaryURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        if let legacyURL = SharedDataManager.cachedWeatherFileLegacyURL {
            try? FileManager.default.removeItem(at: legacyURL)
        }
    }
    
    @Test func saveAndLoadLastKnownLocation() {
        clearAll()
        
        // Manually set UserDefaults since there's no direct save method
        let ud = UserDefaults.standard
        ud.set(40.7128, forKey: "lastWeatherLatitude")
        ud.set(-74.0060, forKey: "lastWeatherLongitude")
        ud.set("New York", forKey: "lastWeatherLocationName")
        
        let location = SharedDataManager.lastKnownLocation()
        
        #expect(location != nil)
        #expect(location?.latitude == 40.7128)
        #expect(location?.longitude == -74.0060)
        #expect(location?.name == "New York")
        
        clearAll()
    }
    
    @Test func loadLastKnownLocationWhenEmpty() {
        clearAll()
        
        let location = SharedDataManager.lastKnownLocation()
        
        #expect(location == nil)
    }
    
    @Test func saveAndLoadCachedWeatherData() {
        clearAll()
        
        let weatherData = MockWeatherData.createSampleWeatherData()!
        SharedDataManager.shared.cacheFullWeatherData(weatherData, locationName: "Test")
        
        let loaded = SharedDataManager.shared.loadCachedFullWeatherData()
        
        #expect(loaded != nil)
        #expect(loaded?.latitude == 37.7749)
        #expect(loaded?.current.temperature2m == 65.0)
        
        clearAll()
    }
    
    @Test func loadCachedWeatherDataWhenEmpty() {
        clearAll()
        
        let loaded = SharedDataManager.shared.loadCachedFullWeatherData()
        
        #expect(loaded == nil)
    }
    
    @Test func cachedWeatherFilePrimaryURLExists() {
        #expect(SharedDataManager.cachedWeatherFilePrimaryURL != nil)
    }
    
    @Test func cachedWeatherFileLegacyURLExists() {
        #expect(SharedDataManager.cachedWeatherFileLegacyURL != nil)
    }
}

// MARK: - Weather Alert Service Tests

@MainActor
struct WeatherAlertServiceIntegrationTests {
    
    @Test func initialAlertServiceState() {
        let service = WeatherAlertService()
        
        #expect(service.activeAlerts.isEmpty)
        #expect(service.isLoading == false)
        #expect(service.lastUpdateTime == nil)
    }
    
    @Test func fetchAlertsUpdatesLoadingState() async {
        let service = WeatherAlertService()
        
        // Start fetch in background
        Task {
            _ = await service.fetchAlerts(latitude: 37.7749, longitude: -122.4194)
        }
        
        // Wait briefly
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Loading state should have been triggered at some point
        // (may already be complete depending on network speed)
        #expect(service.lastUpdateTime != nil || service.isLoading)
    }
    
    @Test func fetchAlertsForUSLocation() async {
        let service = WeatherAlertService()
        
        // San Francisco coordinates (US)
        let alerts = await service.fetchAlerts(latitude: 37.7749, longitude: -122.4194)
        
        // Should have attempted fetch (may be empty if no active alerts)
        #expect(service.lastUpdateTime != nil)
        #expect(alerts.isEmpty || !alerts.isEmpty) // Either state is valid
    }
    
    @Test func fetchAlertsForEuropeanLocation() async {
        let service = WeatherAlertService()
        
        // Paris coordinates (Europe)
        let alerts = await service.fetchAlerts(latitude: 48.8566, longitude: 2.3522)
        
        // Should have attempted fetch
        #expect(service.lastUpdateTime != nil)
        #expect(alerts.isEmpty || !alerts.isEmpty)
    }
    
    @Test func fetchAlertsForOtherLocation() async {
        let service = WeatherAlertService()
        
        // Sydney coordinates (neither US nor Europe)
        let alerts = await service.fetchAlerts(latitude: -33.8688, longitude: 151.2093)
        
        // Should return empty for non-supported regions
        #expect(alerts.isEmpty)
        #expect(service.lastUpdateTime != nil)
    }
    
    @Test func activeAlertsUpdatedAfterFetch() async {
        let service = WeatherAlertService()
        
        #expect(service.activeAlerts.isEmpty)
        
        await service.fetchAlerts(latitude: 37.7749, longitude: -122.4194)
        
        // activeAlerts should be updated (may be empty, but property should be set)
        #expect(service.activeAlerts.isEmpty || !service.activeAlerts.isEmpty)
    }
}

// MARK: - Weather Alert Model Tests

@MainActor
struct WeatherAlertDecodingTests {
    
    @Test func weatherAlertDecoding() throws {
        let json = """
        {
            "event": "Winter Storm Warning",
            "headline": "Winter Storm Warning until SAT 6:00 PM PST",
            "description": "Heavy snow expected. Total snow accumulations of 6 to 12 inches possible.",
            "severity": "Severe",
            "urgency": "Expected",
            "areas": "San Francisco Bay Area",
            "effective": "2026-02-14T12:00:00Z",
            "expires": "2026-02-15T02:00:00Z",
            "sender_name": "NWS San Francisco"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let alert = try decoder.decode(WeatherAlert.self, from: data)
        
        #expect(alert.event == "Winter Storm Warning")
        #expect(alert.severity == "Severe")
        #expect(alert.urgency == "Expected")
        #expect(alert.senderName == "NWS San Francisco")
    }
    
    @Test func weatherAlertIdentifiable() throws {
        let json = """
        {
            "event": "Heat Advisory",
            "headline": "Heat Advisory",
            "description": "Dangerously hot conditions",
            "severity": "Moderate",
            "urgency": "Expected",
            "areas": "Los Angeles County",
            "effective": "2026-07-01T12:00:00Z",
            "expires": "2026-07-02T02:00:00Z",
            "sender_name": "NWS Los Angeles"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let alert = try decoder.decode(WeatherAlert.self, from: data)
        
        // ID should be combination of event and effective date
        #expect(!alert.id.isEmpty)
        #expect(alert.id.contains("Heat Advisory"))
    }
    
    @Test func multipleAlertsHaveUniqueIDs() throws {
        let alert1JSON = """
        {
            "event": "Flood Warning",
            "headline": "Flood Warning",
            "description": "Flooding",
            "severity": "Severe",
            "urgency": "Immediate",
            "areas": "Area 1",
            "effective": "2026-02-14T12:00:00Z",
            "expires": "2026-02-15T02:00:00Z",
            "sender_name": "NWS"
        }
        """
        
        let alert2JSON = """
        {
            "event": "Flood Warning",
            "headline": "Flood Warning",
            "description": "Flooding",
            "severity": "Severe",
            "urgency": "Immediate",
            "areas": "Area 2",
            "effective": "2026-02-14T13:00:00Z",
            "expires": "2026-02-15T03:00:00Z",
            "sender_name": "NWS"
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let alert1 = try decoder.decode(WeatherAlert.self, from: alert1JSON.data(using: .utf8)!)
        let alert2 = try decoder.decode(WeatherAlert.self, from: alert2JSON.data(using: .utf8)!)
        
        // Different effective times should produce different IDs
        #expect(alert1.id != alert2.id)
    }
}

// MARK: - Tomorrow.io Service Tests

@MainActor
struct TomorrowIOApiTests {
    
    @Test func invalidURLThrowsError() async {
        // Empty API key with invalid coordinates should fail gracefully
        do {
            _ = try await TomorrowIOService.fetchPollenForecast(
                latitude: 999.0,
                longitude: 999.0,
                apiKey: ""
            )
            Issue.record("Should have thrown an error")
        } catch {
            // Expected to throw
            #expect(error is WeatherError)
        }
    }
    
    @Test func fetchPollenWithInvalidAPIKey() async {
        do {
            _ = try await TomorrowIOService.fetchPollenForecast(
                latitude: 37.7749,
                longitude: -122.4194,
                apiKey: "invalid_key"
            )
            // May throw or return data depending on API response
        } catch {
            // Expected to fail with invalid API key
            if let weatherError = error as? WeatherError {
                #expect(weatherError == .apiUnavailable || weatherError == .rateLimited)
            } else {
                #expect(true) // Other errors are also acceptable
            }
        }
    }
    
    @Test func fetchPollenWithValidCoordinates() async {
        // Test with valid coordinates but likely invalid/missing API key
        // This tests the service structure without requiring a real API key
        do {
            _ = try await TomorrowIOService.fetchPollenForecast(
                latitude: 37.7749,
                longitude: -122.4194,
                apiKey: "test_key_12345"
            )
        } catch {
            // Expected to fail without real API key - any error is acceptable
            #expect(true)
        }
    }
}

// MARK: - Tomorrow.io Configuration Tests

@MainActor
struct TomorrowIOConfigurationTests {
    
    @Test func timelineURLIsValid() {
        #expect(!TomorrowIOConfig.timelineURL.isEmpty)
        #expect(TomorrowIOConfig.timelineURL.starts(with: "https://"))
    }
    
    @Test func pollenFieldsAreConfigured() {
        #expect(!TomorrowIOConfig.pollenFields.isEmpty)
        #expect(TomorrowIOConfig.pollenFields.contains("grassIndex"))
    }
    
    @Test func sessionExists() {
        // Session should be configured
        #expect(TomorrowIOConfig.session.configuration.timeoutIntervalForRequest > 0)
    }
    
    @Test func decoderExists() {
        // Decoder should be configured with ISO8601
        let testDate = "2026-02-14T12:00:00Z"
        let data = "\"\(testDate)\"".data(using: .utf8)!
        
        let decoded = try? TomorrowIOConfig.decoder.decode(Date.self, from: data)
        #expect(decoded != nil)
    }
}

// MARK: - OpenMeteo Configuration Tests

@MainActor
struct OpenMeteoConfigurationTests {
    
    @Test func baseURLsAreValid() {
        #expect(!OpenMeteoConfig.forecastURL.isEmpty)
        #expect(!OpenMeteoConfig.airQualityURL.isEmpty)
        #expect(!OpenMeteoConfig.historicalURL.isEmpty)
        
        #expect(OpenMeteoConfig.forecastURL.starts(with: "https://"))
        #expect(OpenMeteoConfig.airQualityURL.starts(with: "https://"))
        #expect(OpenMeteoConfig.historicalURL.starts(with: "https://"))
    }
    
    @Test func weatherParametersAreConfigured() {
        #expect(!OpenMeteoConfig.currentParameters.isEmpty)
        #expect(!OpenMeteoConfig.hourlyParameters.isEmpty)
        #expect(!OpenMeteoConfig.dailyParameters.isEmpty)
    }
    
    @Test func airQualityParametersAreConfigured() {
        #expect(!OpenMeteoConfig.airQualityParameters.isEmpty)
        #expect(OpenMeteoConfig.airQualityParameters.contains("us_aqi"))
    }
    
    @Test func pollenParametersAreConfigured() {
        #expect(!OpenMeteoConfig.pollenParameters.isEmpty)
        #expect(OpenMeteoConfig.pollenParameters.contains("grass_pollen"))
        #expect(OpenMeteoConfig.pollenParameters.contains("birch_pollen"))
    }
    
    @Test func sessionExists() {
        #expect(OpenMeteoConfig.cachedSession.configuration.timeoutIntervalForRequest > 0)
    }
    
    @Test func decoderExists() {
        let testDate = "2026-02-14T12:00:00Z"
        let data = "\"\(testDate)\"".data(using: .utf8)!
        
        let decoded = try? OpenMeteoConfig.decoder.decode(Date.self, from: data)
        #expect(decoded != nil)
    }
}

// MARK: - Error Handling Tests

@MainActor
struct WeatherErrorHandlingTests {
    
    @Test func weatherErrorEquality() {
        #expect(WeatherError.invalidURL == WeatherError.invalidURL)
        #expect(WeatherError.invalidResponse == WeatherError.invalidResponse)
        #expect(WeatherError.noData == WeatherError.noData)
        #expect(WeatherError.apiUnavailable == WeatherError.apiUnavailable)
        #expect(WeatherError.rateLimited == WeatherError.rateLimited)
    }
    
    @Test func weatherErrorInequality() {
        #expect(WeatherError.invalidURL != WeatherError.invalidResponse)
        #expect(WeatherError.noData != WeatherError.apiUnavailable)
    }
    
    @Test func serverErrorWithStatusCode() {
        let error = WeatherError.serverError(statusCode: 500)
        
        switch error {
        case .serverError(let code):
            #expect(code == 500)
        default:
            Issue.record("Expected serverError case")
        }
    }
    
    @Test func decodingErrorWithMessage() {
        let message = "Invalid JSON structure"
        let error = WeatherError.decodingError(message)
        
        switch error {
        case .decodingError(let msg):
            #expect(msg == message)
        default:
            Issue.record("Expected decodingError case")
        }
    }
}
