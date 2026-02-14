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

@MainActor
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

@MainActor
struct SettingsManagerTests {
    
    @Test func defaultValues() {
        let settings = SettingsManager()
        
        // Just verify that defaults are one of the valid options
        // (UserDefaults may persist values between tests)
        #expect(TemperatureUnit.allCases.contains(settings.temperatureUnit))
        #expect(WindSpeedUnit.allCases.contains(settings.windSpeedUnit))
        #expect(PrecipitationUnit.allCases.contains(settings.precipitationUnit))
        
        // Booleans should be true by default (if not changed)
        // These are verified after resetToDefaults
    }
    
    @Test func temperatureFormatting() {
        let settings = SettingsManager()
        
        // Test Fahrenheit (no conversion) - includes °F symbol
        settings.temperatureUnit = .fahrenheit
        let fahrenheitResult = settings.formatTemperature(72.0)
        #expect(fahrenheitResult == "72°F")
        
        // Test Celsius (conversion from Fahrenheit) - includes °C symbol
        settings.temperatureUnit = .celsius
        let celsiusResult = settings.formatTemperature(72.0)
        #expect(celsiusResult == "22°C") // (72-32) * 5/9 ≈ 22
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
    
    @Test func windSpeedFormatting() {
        let settings = SettingsManager()
        
        // mph - no conversion (API returns mph)
        settings.windSpeedUnit = .mph
        let mphResult = settings.formatWindSpeed(10.0)
        #expect(mphResult.contains("10") && mphResult.contains("mph"))
        
        // km/h - multiply by 1.60934
        settings.windSpeedUnit = .kmh
        let kmhResult = settings.formatWindSpeed(10.0)
        #expect(kmhResult.contains("16") && kmhResult.contains("km/h")) // 10 * 1.60934 ≈ 16.1
        
        // m/s - multiply by 0.44704
        settings.windSpeedUnit = .ms
        let msResult = settings.formatWindSpeed(10.0)
        #expect(msResult.contains("4") && msResult.contains("m/s")) // 10 * 0.44704 ≈ 4.5
        
        // knots - multiply by 0.868976
        settings.windSpeedUnit = .knots
        let ktsResult = settings.formatWindSpeed(10.0)
        #expect(ktsResult.contains("8") && ktsResult.contains("kts")) // 10 * 0.868976 ≈ 8.7
    }
    
    @Test func convertedWindSpeed() {
        let settings = SettingsManager()
        
        settings.windSpeedUnit = .mph
        #expect(settings.convertedWindSpeed(10.0) == 10.0)
        
        settings.windSpeedUnit = .kmh
        let kmh = settings.convertedWindSpeed(10.0)
        #expect(abs(kmh - 16.0934) < 0.01)
    }
    
    @Test func convertedTemperature() {
        let settings = SettingsManager()
        
        // Fahrenheit — no conversion
        settings.temperatureUnit = .fahrenheit
        #expect(settings.convertedTemperature(72.0) == 72.0)
        
        // Celsius — converts from Fahrenheit
        settings.temperatureUnit = .celsius
        let celsius = settings.convertedTemperature(72.0)
        #expect(abs(celsius - 22.2) < 0.2) // (72-32) * 5/9 ≈ 22.22
    }
    
    @Test func precipitationFormatting() {
        let settings = SettingsManager()
        
        // Inches — no conversion
        settings.precipitationUnit = .inches
        let inchResult = settings.formatPrecipitation(0.5)
        #expect(inchResult == "0.5 in")
        
        // Millimeters — multiply by 25.4
        settings.precipitationUnit = .millimeters
        let mmResult = settings.formatPrecipitation(0.5)
        #expect(mmResult == "12.7 mm") // 0.5 * 25.4 = 12.7
    }
}

// MARK: - Shared Weather Data Tests

@MainActor
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

// MARK: - Weather Condition Tests

@MainActor
struct WeatherConditionTests {
    
    @Test func clearSkyCode() {
        let condition = WeatherCondition(code: 0)
        #expect(condition == .clearSky)
        #expect(condition.symbolName == "sun.max.fill")
        #expect(condition.description == "Clear Sky")
    }
    
    @Test func rainCodes() {
        let codes = [61, 63, 65, 80, 81, 82]
        for code in codes {
            let condition = WeatherCondition(code: code)
            #expect(condition == .rain, "Code \(code) should be rain")
        }
    }
    
    @Test func snowCodes() {
        let codes = [71, 73, 75, 77, 85, 86]
        for code in codes {
            let condition = WeatherCondition(code: code)
            #expect(condition == .snow, "Code \(code) should be snow")
        }
    }
    
    @Test func thunderstormCodes() {
        let codes = [95, 96, 99]
        for code in codes {
            let condition = WeatherCondition(code: code)
            #expect(condition == .thunderstorm, "Code \(code) should be thunderstorm")
        }
    }
    
    @Test func unknownCode() {
        let condition = WeatherCondition(code: 999)
        #expect(condition == .unknown)
    }
    
    @Test func fullDescriptionForAccessibility() {
        #expect(WeatherCondition.clearSky.fullDescription == "clear skies")
        #expect(WeatherCondition.thunderstorm.fullDescription == "thunderstorm")
        #expect(WeatherCondition.foggy.fullDescription == "foggy with reduced visibility")
    }
    
    @Test func allConditionsHaveSymbols() {
        let conditions: [WeatherCondition] = [
            .clearSky, .partlyCloudy, .cloudy, .foggy,
            .drizzle, .rain, .snow, .thunderstorm, .unknown
        ]
        for condition in conditions {
            #expect(!condition.symbolName.isEmpty, "\(condition) should have a symbol name")
            #expect(!condition.description.isEmpty, "\(condition) should have a description")
            #expect(!condition.fullDescription.isEmpty, "\(condition) should have a full description")
        }
    }
}

// MARK: - Temperature Unit Tests

@MainActor
struct TemperatureUnitTests {
    
    @Test func allCasesExist() {
        #expect(TemperatureUnit.allCases.count == 2)
        #expect(TemperatureUnit.allCases.contains(.fahrenheit))
        #expect(TemperatureUnit.allCases.contains(.celsius))
    }
    
    @Test func rawValues() {
        #expect(TemperatureUnit.fahrenheit.rawValue == "Fahrenheit (°F)")
        #expect(TemperatureUnit.celsius.rawValue == "Celsius (°C)")
    }
    
    @Test func symbols() {
        #expect(TemperatureUnit.fahrenheit.symbol == "°F")
        #expect(TemperatureUnit.celsius.symbol == "°C")
    }
}

// MARK: - Wind Speed Unit Tests

@MainActor
struct WindSpeedUnitTests {
    
    @Test func allCasesExist() {
        #expect(WindSpeedUnit.allCases.count == 4) // mph, kmh, ms, knots
    }
    
    @Test func rawValues() {
        #expect(WindSpeedUnit.mph.rawValue == "Miles per hour (mph)")
        #expect(WindSpeedUnit.kmh.rawValue == "Kilometers per hour (km/h)")
        #expect(WindSpeedUnit.ms.rawValue == "Meters per second (m/s)")
        #expect(WindSpeedUnit.knots.rawValue == "Knots")
    }
    
    @Test func symbols() {
        #expect(WindSpeedUnit.mph.symbol == "mph")
        #expect(WindSpeedUnit.kmh.symbol == "km/h")
        #expect(WindSpeedUnit.ms.symbol == "m/s")
        #expect(WindSpeedUnit.knots.symbol == "kts")
    }
}

// MARK: - Accessibility Helper Tests

@MainActor
struct AccessibilityHelperTests {
    
    @Test func windLabel() {
        let label = WeatherAccessibility.windLabel(speed: 15.0, direction: 180)
        #expect(label.contains("15"))
        #expect(label.contains("south") || label.contains("South"))
    }
    
    @Test func humidityLabel() {
        let label = WeatherAccessibility.humidityLabel(75)
        #expect(label.contains("75"))
        #expect(label.contains("humid") || label.contains("Humid"))
    }
    
    @Test func uvIndexLabel() {
        let lowUV = WeatherAccessibility.uvIndexLabel(2.0)
        #expect(lowUV.contains("2"))
        
        let highUV = WeatherAccessibility.uvIndexLabel(9.0)
        #expect(highUV.contains("9"))
    }
    
    @Test func conditionLabel() {
        let label = WeatherAccessibility.conditionLabel(code: 0)
        #expect(label.contains("clear"))
    }
    
    @Test func dailyForecastLabel() {
        let label = WeatherAccessibility.dailyForecastLabel(
            day: "2026-02-05", high: 75.0, low: 55.0, code: 0
        )
        #expect(label.contains("75"))
        #expect(label.contains("55"))
        #expect(label.contains("clear"))
    }
}

// MARK: - Moon Phase Calculation Tests

@MainActor
struct MoonPhaseCalculationTests {
    
    @Test func phaseNames() {
        // All phases should have a name, icon, and illumination
        let date = Date()
        let phase = MoonPhase.calculate(for: date)
        
        #expect(!phase.name.isEmpty)
        #expect(!phase.emoji.isEmpty)
        #expect(phase.illumination >= 0 && phase.illumination <= 1.0)
    }
    
    @Test func phaseCalculationConsistency() {
        // Same date should always produce the same phase
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 15
        let date = Calendar.current.date(from: components)!
        
        let phase1 = MoonPhase.calculate(for: date)
        let phase2 = MoonPhase.calculate(for: date)
        
        #expect(phase1.name == phase2.name)
        #expect(phase1.illumination == phase2.illumination)
        #expect(phase1.emoji == phase2.emoji)
    }
}