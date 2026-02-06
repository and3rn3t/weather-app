//
//  weatherTests.swift
//  weatherTests
//
//  Created by Matt on 2/4/26.
//

import Testing
import Foundation
@testable import weather

// MARK: - Weather Error Tests

struct WeatherErrorTests {
    
    @Test func errorDescriptions() {
        let errors: [WeatherError] = [
            .noInternet,
            .timeout,
            .serverError(statusCode: 500),
            .invalidResponse,
            .invalidURL,
            .decodingError("test"),
            .noData,
            .locationAccessDenied,
            .locationUnavailable,
            .geocodingFailed,
            .rateLimited,
            .apiUnavailable,
            .unknown("test error")
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil, "Error \(error) should have description")
            #expect(error.recoverySuggestion != nil, "Error \(error) should have recovery suggestion")
            #expect(!error.systemImage.isEmpty, "Error \(error) should have system image")
        }
    }
    
    @Test func retryableErrors() {
        // These should be retryable
        #expect(WeatherError.noInternet.isRetryable == true)
        #expect(WeatherError.timeout.isRetryable == true)
        #expect(WeatherError.serverError(statusCode: 500).isRetryable == true)
        #expect(WeatherError.rateLimited.isRetryable == true)
        #expect(WeatherError.apiUnavailable.isRetryable == true)
        
        // These should NOT be retryable
        #expect(WeatherError.invalidURL.isRetryable == false)
        #expect(WeatherError.locationAccessDenied.isRetryable == false)
        #expect(WeatherError.geocodingFailed.isRetryable == false)
    }
    
    @Test func urlErrorConversion() {
        let notConnected = URLError(.notConnectedToInternet)
        #expect(WeatherError.from(notConnected) == .noInternet)
        
        let timedOut = URLError(.timedOut)
        #expect(WeatherError.from(timedOut) == .timeout)
        
        let badURL = URLError(.badURL)
        #expect(WeatherError.from(badURL) == .invalidURL)
    }
    
    @Test func statusCodeConversion() {
        #expect(WeatherError.from(statusCode: 200) == nil) // Success
        #expect(WeatherError.from(statusCode: 400) == .invalidURL)
        #expect(WeatherError.from(statusCode: 429) == .rateLimited)
        #expect(WeatherError.from(statusCode: 500) == .serverError(statusCode: 500))
    }
}

// MARK: - Retry Configuration Tests

struct RetryConfigurationTests {
    
    @Test func defaultConfiguration() {
        let config = RetryConfiguration.default
        #expect(config.maxAttempts == 3)
        #expect(config.initialDelay == 1.0)
    }
    
    @Test func exponentialBackoff() {
        let config = RetryConfiguration(
            maxAttempts: 5,
            initialDelay: 1.0,
            maxDelay: 10.0,
            multiplier: 2.0
        )
        
        #expect(config.delay(for: 1) == 1.0)
        #expect(config.delay(for: 2) == 2.0)
        #expect(config.delay(for: 3) == 4.0)
        #expect(config.delay(for: 4) == 8.0)
        #expect(config.delay(for: 5) == 10.0) // Capped at maxDelay
    }
}

// MARK: - Settings Manager Tests

struct SettingsManagerTests {
    
    @Test func defaultValues() {
        // Clear UserDefaults for test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "temperatureUnit")
        defaults.removeObject(forKey: "windSpeedUnit")
        defaults.removeObject(forKey: "precipitationUnit")
        
        let settings = SettingsManager()
        
        #expect(settings.temperatureUnit == .fahrenheit)
        #expect(settings.windSpeedUnit == .mph)
        #expect(settings.precipitationUnit == .inches)
        #expect(settings.showFeelsLike == true)
        #expect(settings.showAnimatedBackgrounds == true)
        #expect(settings.showWeatherParticles == true)
        #expect(settings.liveActivitiesEnabled == true)
    }
    
    @Test func temperatureFormatting() {
        let settings = SettingsManager()
        
        // Test Fahrenheit (no conversion)
        settings.temperatureUnit = .fahrenheit
        let fahrenheitResult = settings.formatTemperature(72.0)
        #expect(fahrenheitResult == "72°")
        
        // Test Celsius (conversion from Fahrenheit)
        settings.temperatureUnit = .celsius
        let celsiusResult = settings.formatTemperature(72.0)
        #expect(celsiusResult == "22°") // (72-32) * 5/9 ≈ 22
    }
    
    @Test func resetToDefaults() {
        let settings = SettingsManager()
        
        // Change values
        settings.temperatureUnit = .celsius
        settings.showFeelsLike = false
        settings.autoRefreshInterval = 15
        
        // Reset
        settings.resetToDefaults()
        
        #expect(settings.temperatureUnit == .fahrenheit)
        #expect(settings.showFeelsLike == true)
        #expect(settings.autoRefreshInterval == 30)
    }
}

// MARK: - Shared Weather Data Tests

struct SharedWeatherDataTests {
    
    @Test func encodingDecoding() throws {
        let hourlyData = [
            SharedHourlyData(time: "2026-02-05T12:00", temperature: 72.0, weatherCode: 0)
        ]
        
        let originalData = SharedWeatherData(
            temperature: 72.5,
            apparentTemperature: 70.0,
            weatherCode: 1,
            isDay: 1,
            humidity: 65,
            windSpeed: 10.5,
            highTemp: 78.0,
            lowTemp: 55.0,
            precipitationProbability: 20,
            locationName: "Test City",
            lastUpdated: Date(),
            hourlyForecast: hourlyData
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalData)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(SharedWeatherData.self, from: data)
        
        #expect(decodedData.temperature == originalData.temperature)
        #expect(decodedData.weatherCode == originalData.weatherCode)
        #expect(decodedData.locationName == originalData.locationName)
        #expect(decodedData.precipitationProbability == originalData.precipitationProbability)
        #expect(decodedData.hourlyForecast.count == 1)
    }
}

// MARK: - Weather Condition Tests (Snippet View)

struct WeatherConditionSnippetTests {
    
    @Test func clearSkyCode() {
        let condition = WeatherConditionSnippet(code: 0)
        #expect(condition == .clearSky)
        #expect(condition.symbolName == "sun.max.fill")
        #expect(condition.description == "Clear")
    }
    
    @Test func rainCodes() {
        let codes = [61, 63, 65, 80, 81, 82]
        for code in codes {
            let condition = WeatherConditionSnippet(code: code)
            #expect(condition == .rain, "Code \(code) should be rain")
        }
    }
    
    @Test func snowCodes() {
        let codes = [71, 73, 75, 77, 85, 86]
        for code in codes {
            let condition = WeatherConditionSnippet(code: code)
            #expect(condition == .snow, "Code \(code) should be snow")
        }
    }
    
    @Test func thunderstormCodes() {
        let codes = [95, 96, 99]
        for code in codes {
            let condition = WeatherConditionSnippet(code: code)
            #expect(condition == .thunderstorm, "Code \(code) should be thunderstorm")
        }
    }
    
    @Test func unknownCode() {
        let condition = WeatherConditionSnippet(code: 999)
        #expect(condition == .unknown)
    }
}

// MARK: - Temperature Unit Tests

struct TemperatureUnitTests {
    
    @Test func allCasesExist() {
        #expect(TemperatureUnit.allCases.count == 2)
        #expect(TemperatureUnit.allCases.contains(.fahrenheit))
        #expect(TemperatureUnit.allCases.contains(.celsius))
    }
    
    @Test func rawValues() {
        #expect(TemperatureUnit.fahrenheit.rawValue == "°F")
        #expect(TemperatureUnit.celsius.rawValue == "°C")
    }
}

// MARK: - Wind Speed Unit Tests

struct WindSpeedUnitTests {
    
    @Test func allCasesExist() {
        #expect(WindSpeedUnit.allCases.count == 3)
    }
    
    @Test func rawValues() {
        #expect(WindSpeedUnit.mph.rawValue == "mph")
        #expect(WindSpeedUnit.kmh.rawValue == "km/h")
        #expect(WindSpeedUnit.knots.rawValue == "knots")
    }
}
