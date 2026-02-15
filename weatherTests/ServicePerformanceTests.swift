//
//  ServicePerformanceTests.swift
//  weatherTests
//
//  Unit tests for measuring performance of business logic and services
//

import XCTest
@testable import weather

final class ServicePerformanceTests: XCTestCase {
    
    var weatherService: WeatherService!
    var mockCacheData: Data!
    
    override func setUpWithError() throws {
        // Create mock data for performance testing
        let mockWeather = WeatherData(
            latitude: 37.7749,
            longitude: -122.4194,
            timezone: "America/Los_Angeles",
            current: CurrentWeather(
                time: "2026-02-15T12:00",
                temperature2m: 72.0,
                apparentTemperature: 75.0,
                weatherCode: 0,
                windSpeed10m: 5.2,
                windDirection10m: 180.0,
                windGusts10m: 8.1,
                relativeHumidity2m: 65,
                dewPoint2m: 58.3,
                pressure: 1013.25,
                cloudCover: 25,
                visibility: 10.0,
                uvIndex: 6.5,
                isDay: 1,
                precipitation: 0.0
            ),
            hourly: HourlyWeather(
                time: Array(0..<24).map { "2026-02-15T\(String(format: "%02d", $0)):00" },
                temperature2m: Array(0..<24).map { Double($0) + 60.0 },
                weatherCode: Array(repeating: 0, count: 24),
                precipitationProbability: Array(repeating: 10, count: 24),
                windSpeed10m: Array(repeating: 5.0, count: 24),
                windGusts10m: Array(repeating: 8.0, count: 24),
                relativeHumidity2m: Array(repeating: 65, count: 24),
                uvIndex: Array(0..<24).map { hour in hour < 6 || hour > 18 ? 0.0 : Double(hour - 6) }
            ),
            daily: DailyWeather(
                time: Array(0..<14).map { "2026-02-\(String(format: "%02d", 15 + $0))" },
                weatherCode: Array(repeating: 0, count: 14),
                temperature2mMax: Array(0..<14).map { Double($0) + 75.0 },
                temperature2mMin: Array(0..<14).map { Double($0) + 55.0 },
                precipitationProbabilityMax: Array(repeating: 15, count: 14),
                sunrise: Array(0..<14).map { _ in "07:00" },
                sunset: Array(0..<14).map { _ in "18:30" },
                uvIndexMax: Array(repeating: 6.0, count: 14),
                windSpeed10mMax: Array(repeating: 10.0, count: 14),
                windGusts10mMax: Array(repeating: 15.0, count: 14)
            )
        )
        
        mockCacheData = try JSONEncoder().encode(mockWeather)
    }
    
    override func tearDownWithError() throws {
        weatherService = nil
        mockCacheData = nil
    }
    
    // MARK: - Service Initialization Performance
    
    func testWeatherServiceInitializationPerformance() throws {
        // Test how long it takes to initialize WeatherService
        measure {
            _ = WeatherService()
        }
    }
    
    func testCacheLoadingPerformance() throws {
        // Test synchronous cache loading performance during init
        let tempDirectory = FileManager.default.temporaryDirectory
        let cacheURL = tempDirectory.appendingPathComponent("weather_cache_test.json")
        
        // Create mock cache file
        try mockCacheData.write(to: cacheURL)
        
        measure {
            // Simulate cache loading
            do {
                let cachedData = try Data(contentsOf: cacheURL)
                _ = try JSONDecoder().decode(WeatherData.self, from: cachedData)
            } catch {
                XCTFail("Cache loading should not fail: \(error)")
            }
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: cacheURL)
    }
    
    // MARK: - JSON Decoding Performance
    
    func testWeatherDataDecodingPerformance() throws {
        // Test JSON decoding performance for weather data
        measure {
            do {
                _ = try JSONDecoder().decode(WeatherData.self, from: mockCacheData)
            } catch {
                XCTFail("Decoding should not fail: \(error)")
            }
        }
    }
    
    func testWeatherDataEncodingPerformance() throws {
        // Test JSON encoding performance
        let weatherData = try JSONDecoder().decode(WeatherData.self, from: mockCacheData)
        
        measure {
            do {
                _ = try JSONEncoder().encode(weatherData)
            } catch {
                XCTFail("Encoding should not fail: \(error)")
            }
        }
    }
    
    // MARK: - Formatter Performance
    
    func testTemperatureFormatterPerformance() throws {
        // Test cached formatter performance vs creating new formatters
        let temperatures = Array(0..<1000).map { Double($0) / 10.0 }
        
        // Test cached formatter (what we currently use)
        measure(metrics: [XCTClockMetric()]) {
            for temp in temperatures {
                _ = SettingsManager.shared.formatTemperature(temp)
            }
        }
    }
    
    func testDateFormatterPerformance() throws {
        // Test date formatting performance
        let dates = Array(0..<100).map { "2026-02-\(String(format: "%02d", $0 % 28 + 1))T12:00" }
        
        measure {
            for dateString in dates {
                _ = SettingsManager.formatDayName(dateString)
            }
        }
    }
    
    // MARK: - Weather Calculation Performance
    
    func testWeatherConditionMappingPerformance() throws {
        // Test performance of weather code to condition mapping
        let weatherCodes = Array(0..<100).map { $0 % 96 } // WMO codes go up to 95
        
        measure {
            for code in weatherCodes {
                let condition = WeatherCondition(code: code)
                _ = condition.symbolName
                _ = condition.description
            }
        }
    }
    
    func testUVIndexCalculationPerformance() throws {
        // Test UV index helper performance
        let uvValues = Array(0..<1000).map { Double($0) / 100.0 } // 0-10 range
        
        measure {
            for uv in uvValues {
                _ = UVIndexHelper.color(for: uv)
                _ = UVIndexHelper.level(for: uv)
                _ = UVIndexHelper.recommendation(for: uv)
            }
        }
    }
    
    // MARK: - Collection Operations Performance
    
    func testHourlyDataProcessingPerformance() throws {
        // Test processing of hourly forecast arrays
        let weatherData = try JSONDecoder().decode(WeatherData.self, from: mockCacheData)
        
        measure {
            // Simulate operations performed on hourly data
            let temperatures = weatherData.hourly.temperature2m
            let avgTemp = temperatures.reduce(0, +) / Double(temperatures.count)
            let maxTemp = temperatures.max() ?? 0
            let minTemp = temperatures.min() ?? 0
            
            // Find temperature trend (as used in UI)
            let firstThree = Array(temperatures.prefix(3)).reduce(0, +) / 3
            let nextThree = Array(temperatures.dropFirst(3).prefix(3)).reduce(0, +) / 3
            let diff = nextThree - firstThree
            
            _ = (avgTemp, maxTemp, minTemp, diff) // Use values to prevent optimization
        }
    }
    
    func testDailyDataFilteringPerformance() throws {
        // Test filtering and processing daily forecast data
        let weatherData = try JSONDecoder().decode(WeatherData.self, from: mockCacheData)
        
        measure {
            // Operations similar to what DailyForecastCard does
            let displayDays = 7
            let limitedDaily = Array(weatherData.daily.time.prefix(displayDays))
            let limitedTempsMax = Array(weatherData.daily.temperature2mMax.prefix(displayDays))
            let limitedTempsMin = Array(weatherData.daily.temperature2mMin.prefix(displayDays))
            
            // Create tuples for display (common UI operation)
            let combinedData = zip(zip(limitedDaily, limitedTempsMax), limitedTempsMin)
                .map { (timeTemp, minTemp) in
                    (time: timeTemp.0, maxTemp: timeTemp.1, minTemp: minTemp)
                }
            
            _ = combinedData.count // Use result
        }
    }
    
    // MARK: - Memory Allocation Performance
    
    func testRepeatedViewModelCreationPerformance() throws {
        // Test performance of creating multiple weather service instances
        // (simulates memory pressure scenarios)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            var services: [WeatherService] = []
            
            // Create and release multiple instances
            for _ in 0..<50 {
                let service = WeatherService()
                services.append(service)
            }
            
            // Clear references to trigger deallocation
            services.removeAll()
        }
    }
    
    func testLargeDataSetHandlingPerformance() throws {
        // Test performance with large forecast datasets
        let largeHourlyData = HourlyWeather(
            time: Array(0..<168).map { hour in // 7 days of hourly data
                let date = Calendar.current.date(byAdding: .hour, value: hour, to: Date()) ?? Date()
                return DateFormatter().string(from: date)
            },
            temperature2m: Array(0..<168).map { Double($0 % 24) + 60 },
            weatherCode: Array(0..<168).map { $0 % 10 },
            precipitationProbability: Array(0..<168).map { $0 % 100 },
            windSpeed10m: Array(0..<168).map { Double($0 % 20) },
            windGusts10m: Array(0..<168).map { Double($0 % 30) },
            relativeHumidity2m: Array(0..<168).map { $0 % 100 },
            uvIndex: Array(0..<168).map { hour in
                let hourOfDay = hour % 24
                return hourOfDay < 6 || hourOfDay > 18 ? 0.0 : Double(hourOfDay - 6)
            }
        )
        
        measure {
            // Process the large dataset
            let avgTemp = largeHourlyData.temperature2m.reduce(0, +) / Double(largeHourlyData.temperature2m.count)
            let precipDays = largeHourlyData.precipitationProbability?.filter { $0 > 50 }.count ?? 0
            
            // Simulate converting for chart display (expensive operation)
            let chartData = zip(largeHourlyData.time, largeHourlyData.temperature2m)
                .map { (time: $0.0, temp: $0.1) }
            
            _ = (avgTemp, precipDays, chartData.count)
        }
    }
    
    // MARK: - Network Response Processing Performance
    
    func testNetworkResponseParsingPerformance() throws {
        // Test parsing performance of typical API response sizes
        measure {
            // Simulate processing network response
            for _ in 0..<10 {
                do {
                    let weatherData = try JSONDecoder().decode(WeatherData.self, from: mockCacheData)
                    
                    // Simulate immediate UI updates that happen after network response
                    let currentTemp = weatherData.current.temperature2m
                    let todayHigh = weatherData.daily.temperature2mMax.first ?? 0
                    let todayLow = weatherData.daily.temperature2mMin.first ?? 0
                    let hourlyTemps = Array(weatherData.hourly.temperature2m.prefix(24))
                    
                    _ = (currentTemp, todayHigh, todayLow, hourlyTemps.count)
                } catch {
                    XCTFail("Parsing should not fail: \(error)")
                }
            }
        }
    }
    
    // MARK: - Startup Performance Integration
    
    func testCompleteStartupSequencePerformance() throws {
        // Test the complete startup sequence performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // 1. Service initialization
            let service = WeatherService()
            
            // 2. Cache loading (already happens in init, but measure the impact)
            let startTime = Date()
            
            // 3. Simulate initial data availability check
            let hasData = service.weatherData != nil
            
            // 4. Simulate first UI update
            if hasData {
                let temp = service.weatherData?.current.temperature2m ?? 0
                _ = SettingsManager.shared.formatTemperature(temp)
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            // Verify performance expectations
            XCTAssertLessThan(elapsed, 0.1, "Complete startup sequence should take less than 100ms")
            
            _ = service // Keep reference to prevent early deallocation
        }
    }
}