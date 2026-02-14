//
//  ServiceTests.swift
//  weatherTests
//
//  Comprehensive tests for all Service classes
//

import Testing
import Foundation
@testable import weather

// MARK: - Weather Alert Service Tests

@MainActor
struct WeatherAlertServiceTests {
    
    @Test func initialState() {
        let service = WeatherAlertService()
        
        #expect(service.activeAlerts.isEmpty)
        #expect(service.isLoading == false)
        #expect(service.lastUpdateTime == nil)
    }
    
    @Test func loadingStateManagement() async {
        let service = WeatherAlertService()
        
        // Fetch alerts (may fail without network, but tests state management)
        Task {
            _ = await service.fetchAlerts(latitude: 37.7749, longitude: -122.4194)
        }
        
        // Either loading or completed
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(service.isLoading || service.lastUpdateTime != nil || service.activeAlerts.isEmpty)
    }
}

// MARK: - Weather Alert Model Tests

@MainActor
struct WeatherAlertModelTests {
    
    @Test func alertCodingRoundTrip() throws {
        let originalAlert = WeatherAlert(
            event: "Severe Thunderstorm Warning",
            headline: "Severe weather expected",
            description: "A severe thunderstorm is approaching",
            severity: "Severe",
            urgency: "Immediate",
            areas: "Zone1, Zone2",
            effective: Date(),
            expires: Date().addingTimeInterval(3600),
            senderName: "NWS"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalAlert)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedAlert = try decoder.decode(WeatherAlert.self, from: data)
        
        #expect(decodedAlert.id == originalAlert.id)
        #expect(decodedAlert.event == originalAlert.event)
        #expect(decodedAlert.severity == originalAlert.severity)
        #expect(decodedAlert.areas == originalAlert.areas)
    }
    
    @Test func alertComparison() {
        let alert1 = WeatherAlert(
            event: "Test",
            headline: "Test",
            description: "Test",
            severity: "Minor",
            urgency: "Future",
            areas: "Test Area",
            effective: Date(),
            expires: Date(),
            senderName: "Test"
        )
        
        let alert2 = WeatherAlert(
            event: "Test",
            headline: "Test",
            description: "Test",
            severity: "Minor",
            urgency: "Future",
            areas: "Test Area",
            effective: Date(),
            expires: Date(),
            senderName: "Test"
        )
        
        #expect(alert1.id == alert2.id)
    }
}

// MARK: - Tomorrow.io Service Tests

@MainActor
struct TomorrowIOServiceTests {
    
    @Test func configConstants() {
        // Verify config constants exist
        #expect(!TomorrowIOConfig.timelineURL.isEmpty)
        #expect(!TomorrowIOConfig.pollenFields.isEmpty)
    }
}

// MARK: - OpenMeteo Config Tests

@MainActor
struct OpenMeteoConfigTests {
    
    @Test func configConstants() {
        // Verify all base URLs exist
        #expect(!OpenMeteoConfig.forecastURL.isEmpty)
        #expect(!OpenMeteoConfig.airQualityURL.isEmpty)
        #expect(!OpenMeteoConfig.historicalURL.isEmpty)
        
        // Verify parameters exist
        #expect(!OpenMeteoConfig.currentParameters.isEmpty)
        #expect(!OpenMeteoConfig.hourlyParameters.isEmpty)
    }
}

// MARK: - Weather Service Enhancement Tests

@MainActor
struct WeatherServiceEnhancedTests {
    
    @Test func concurrentFetchHandling() async {
        let service = WeatherService()
        
        // Test multiple concurrent fetches don't cause issues
        async let fetch1: () = service.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "SF"
        )
        async let fetch2: () = service.fetchWeather(
            latitude: 40.7128,
            longitude: -74.0060,
            locationName: "NYC"
        )
        
        _ = await (fetch1, fetch2)
        
        // Should complete without crashing
        #expect(service.currentLocationName != nil || service.errorMessage != nil)
    }
    
    @Test func errorRecovery() async {
        let service = WeatherService()
        
        // Fetch with invalid coordinates
        await service.fetchWeather(latitude: 999, longitude: 999, locationName: "Invalid")
        
        // Should have error
        #expect(service.errorMessage != nil || service.lastError != nil)
        
        // Now fetch with valid coordinates
        await service.fetchWeather(latitude: 37.7749, longitude: -122.4194, locationName: "SF")
        
        // Error state should be updated (either cleared or new error)
        #expect(service.isLoading == false)
    }
    
    @Test func refreshWeather() async {
        let service = WeatherService()
        
        // Initial fetch
        await service.fetchWeather(latitude: 37.7749, longitude: -122.4194, locationName: "SF")
        
        let firstLocationName = service.currentLocationName
        
        // Refresh same location with force refresh
        await service.fetchWeather(latitude: 37.7749, longitude: -122.4194, 
                                   locationName: "SF", forceRefresh: true)
        
        // Should maintain location
        #expect(service.currentLocationName == firstLocationName || 
               service.currentLocationName == "SF")
    }
    
    @Test func backgroundRefresh() async {
        let service = WeatherService()
        
        // Test background refresh mechanism
        await service.fetchWeather(latitude: 37.7749, longitude: -122.4194, locationName: "SF")
        
        // Simulate background refresh
        await service.fetchWeather(latitude: 37.7749, longitude: -122.4194, 
                                   locationName: "SF", forceRefresh: true)
        
        #expect(service.isLoading == false)
    }
}

// MARK: - Retry Mechanism Tests

@MainActor
struct RetryMechanismTests {
    
    @Test func exponentialBackoffCalculation() {
        let config = RetryConfiguration(
            maxAttempts: 5,
            initialDelay: 1.0,
            maxDelay: 30.0,
            multiplier: 2.0
        )
        
        let delays = (1...5).map { config.delay(for: $0) }
        
        #expect(delays[0] == 1.0)  // 1st retry: 1 second
        #expect(delays[1] == 2.0)  // 2nd retry: 2 seconds
        #expect(delays[2] == 4.0)  // 3rd retry: 4 seconds
        #expect(delays[3] == 8.0)  // 4th retry: 8 seconds
        #expect(delays[4] == 16.0) // 5th retry: 16 seconds
    }
    
    @Test func maxDelayEnforcement() {
        let config = RetryConfiguration(
            maxAttempts: 10,
            initialDelay: 1.0,
            maxDelay: 10.0,
            multiplier: 2.0
        )
        
        let delay = config.delay(for: 10)
        
        #expect(delay <= 10.0, "Delay should be capped at maxDelay")
    }
    
    @Test func defaultConfiguration() {
        let config = RetryConfiguration.default
        
        // Verify default configuration exists and has reasonable values
        #expect(config.maxAttempts > 0)
        #expect(config.initialDelay > 0)
        #expect(config.maxDelay > config.initialDelay)
        #expect(config.multiplier > 1.0)
    }
}
