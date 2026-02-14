//
//  ModelTests.swift
//  weatherTests
//
//  Comprehensive tests for data models
//

import Foundation
import SwiftUI
import Testing

@testable import weather

// MARK: - Pollen Model Tests

@MainActor
struct PollenDataTests {

    @Test func pollenDataDecoding() throws {
        let json = """
            {
                "latitude": 40.7128,
                "longitude": -74.0060,
                "timezone": "America/New_York",
                "hourly": {
                    "time": ["2026-02-14T00:00", "2026-02-14T01:00"],
                    "grass_pollen": [15.5, 20.2],
                    "birch_pollen": [10.0, 12.5],
                    "olive_pollen": [5.0, 8.0],
                    "ragweed_pollen": [25.0, 30.0]
                }
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let pollenData = try decoder.decode(PollenData.self, from: data)

        #expect(pollenData.latitude == 40.7128)
        #expect(pollenData.longitude == -74.0060)
        #expect(pollenData.timezone == "America/New_York")
        #expect(pollenData.hourly != nil)
        #expect(pollenData.hourly?.time.count == 2)
        if let grassPollen = pollenData.hourly?.grassPollen {
            #expect(grassPollen[0] == 15.5)
        }
        if let birchPollen = pollenData.hourly?.birchPollen {
            #expect(birchPollen[1] == 12.5)
        }
    }

    @Test func pollenDataEquality() {
        let hourly1 = HourlyPollen(
            time: ["2026-02-14T00:00"],
            grassPollen: [10.0],
            birchPollen: [5.0],
            olivePollen: [3.0],
            ragweedPollen: [15.0]
        )

        let hourly2 = HourlyPollen(
            time: ["2026-02-14T00:00"],
            grassPollen: [10.0],
            birchPollen: [5.0],
            olivePollen: [3.0],
            ragweedPollen: [15.0]
        )

        let data1 = PollenData(
            latitude: 40.0, longitude: -74.0, timezone: "America/New_York", hourly: hourly1)
        let data2 = PollenData(
            latitude: 40.0, longitude: -74.0, timezone: "America/New_York", hourly: hourly2)

        #expect(data1 == data2)
    }

    @Test func hourlyPollenMaxInRange() {
        let hourly = HourlyPollen(
            time: ["2026-02-14T00:00", "2026-02-14T01:00", "2026-02-14T02:00"],
            grassPollen: [10.0, 25.0, 15.0],
            birchPollen: [5.0, 8.0, 12.0],
            olivePollen: [3.0, 7.0, 20.0],
            ragweedPollen: [15.0, 30.0, 18.0]
        )

        let result = hourly.maxPollenInRange(start: 0, count: 3)
        #expect(result != nil)
        #expect(result?.type == .ragweed)
        #expect(result?.value == 30.0)
    }

    @Test func hourlyPollenMaxInPartialRange() {
        let hourly = HourlyPollen(
            time: ["2026-02-14T00:00", "2026-02-14T01:00", "2026-02-14T02:00"],
            grassPollen: [50.0, 25.0, 15.0],
            birchPollen: [5.0, 8.0, 12.0],
            olivePollen: nil,
            ragweedPollen: [15.0, 10.0, 8.0]
        )

        let result = hourly.maxPollenInRange(start: 0, count: 1)
        #expect(result != nil)
        #expect(result?.type == .grass)
        #expect(result?.value == 50.0)
    }

    @Test func hourlyPollenNoData() {
        let hourly = HourlyPollen(
            time: ["2026-02-14T00:00"],
            grassPollen: nil,
            birchPollen: nil,
            olivePollen: nil,
            ragweedPollen: nil
        )

        let result = hourly.maxPollenInRange(start: 0, count: 1)
        #expect(result == nil)
    }
}

@MainActor
struct PollenTypeTests {

    @Test func allCasesExist() {
        let types = PollenType.allCases
        #expect(types.count == 4)
        #expect(types.contains(.grass))
        #expect(types.contains(.birch))
        #expect(types.contains(.olive))
        #expect(types.contains(.ragweed))
    }

    @Test func rawValues() {
        #expect(PollenType.grass.rawValue == "Grass")
        #expect(PollenType.birch.rawValue == "Birch")
        #expect(PollenType.olive.rawValue == "Olive")
        #expect(PollenType.ragweed.rawValue == "Ragweed")
    }

    @Test func icons() {
        #expect(PollenType.grass.icon == "leaf.fill")
        #expect(PollenType.birch.icon == "tree.fill")
        #expect(PollenType.olive.icon == "tree")
        #expect(PollenType.ragweed.icon == "allergens")
    }

    @Test func colorsAreAssigned() {
        // Just verify they return Color instances
        _ = PollenType.grass.color
        _ = PollenType.birch.color
        _ = PollenType.olive.color
        _ = PollenType.ragweed.color
        // Test passes if no crash
    }
}

@MainActor
struct PollenLevelTests {

    @Test func levelInitialization() {
        #expect(PollenLevel(concentration: 0) == .none)
        #expect(PollenLevel(concentration: 5) == .low)
        #expect(PollenLevel(concentration: 25) == .moderate)
        #expect(PollenLevel(concentration: 75) == .high)
        #expect(PollenLevel(concentration: 150) == .veryHigh)
    }

    @Test func boundaryValues() {
        #expect(PollenLevel(concentration: 9.9) == .low)
        #expect(PollenLevel(concentration: 10.0) == .moderate)
        #expect(PollenLevel(concentration: 49.9) == .moderate)
        #expect(PollenLevel(concentration: 50.0) == .high)
        #expect(PollenLevel(concentration: 99.9) == .high)
        #expect(PollenLevel(concentration: 100.0) == .veryHigh)
    }

    @Test func levelNames() {
        #expect(PollenLevel.none.name == "None")
        #expect(PollenLevel.low.name == "Low")
        #expect(PollenLevel.moderate.name == "Moderate")
        #expect(PollenLevel.high.name == "High")
        #expect(PollenLevel.veryHigh.name == "Very High")
    }

    @Test func levelColors() {
        // Verify colors are assigned
        _ = PollenLevel.none.color
        _ = PollenLevel.low.color
        _ = PollenLevel.moderate.color
        _ = PollenLevel.high.color
        _ = PollenLevel.veryHigh.color
    }

    @Test func levelAdvice() {
        #expect(PollenLevel.none.advice.contains("No pollen"))
        #expect(PollenLevel.low.advice.contains("Low pollen"))
        #expect(PollenLevel.moderate.advice.contains("Moderate pollen"))
        #expect(PollenLevel.high.advice.contains("High pollen"))
        #expect(PollenLevel.veryHigh.advice.contains("Very high"))
    }
}

@MainActor
struct TomorrowIOPollenTests {

    @Test func tomorrowIODecoding() throws {
        let json = """
            {
                "data": {
                    "timelines": [{
                        "timestep": "1h",
                        "intervals": [
                            {
                                "startTime": "2026-02-14T00:00:00Z",
                                "values": {
                                    "treeIndex": 2.5,
                                    "grassIndex": 3.0,
                                    "weedIndex": 1.5
                                }
                            }
                        ]
                    }]
                }
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let pollenData = try decoder.decode(TomorrowIOPollenData.self, from: data)

        #expect(pollenData.data.timelines.count == 1)
        #expect(pollenData.data.timelines[0].intervals.count == 1)
        #expect(pollenData.data.timelines[0].intervals[0].values.treeIndex == 2.5)
        #expect(pollenData.data.timelines[0].intervals[0].values.grassIndex == 3.0)
        #expect(pollenData.data.timelines[0].intervals[0].values.weedIndex == 1.5)
    }
}

@MainActor
struct UnifiedPollenDataTests {

    @Test func fromOpenMeteoConversion() {
        let hourly = HourlyPollen(
            time: ["2026-02-14T00:00", "2026-02-14T01:00"],
            grassPollen: [10.0, 20.0],
            birchPollen: [5.0, 8.0],
            olivePollen: [3.0, 7.0],
            ragweedPollen: [15.0, 25.0]
        )

        let pollenData = PollenData(
            latitude: 40.0,
            longitude: -74.0,
            timezone: "America/New_York",
            hourly: hourly
        )

        let unified = UnifiedPollenData.from(openMeteo: pollenData)

        #expect(unified != nil)
        #expect(unified?.dates.count == 2)
        #expect(unified?.grassLevels == [10.0, 20.0])
        #expect(unified?.treeLevels == [5.0, 8.0])
        #expect(unified?.weedLevels == [15.0, 25.0])
    }

    @Test func fromOpenMeteoNoHourlyData() {
        let pollenData = PollenData(
            latitude: 40.0,
            longitude: -74.0,
            timezone: "America/New_York",
            hourly: nil
        )

        let unified = UnifiedPollenData.from(openMeteo: pollenData)
        #expect(unified == nil)
    }

    @Test func fromTomorrowIOConversion() {
        let interval1 = TomorrowIOPollenData.TomorrowIOInterval(
            startTime: "2026-02-14T00:00:00Z",
            values: TomorrowIOPollenData.TomorrowIOValues(
                treeIndex: 2.0,
                grassIndex: 3.0,
                weedIndex: 1.0
            )
        )

        let interval2 = TomorrowIOPollenData.TomorrowIOInterval(
            startTime: "2026-02-14T01:00:00Z",
            values: TomorrowIOPollenData.TomorrowIOValues(
                treeIndex: 4.0,
                grassIndex: 2.0,
                weedIndex: 3.0
            )
        )

        let timeline = TomorrowIOPollenData.TomorrowIOTimeline(
            timestep: "1h",
            intervals: [interval1, interval2]
        )

        let data = TomorrowIOPollenData(
            data: TomorrowIOPollenData.TomorrowIOTimelineData(timelines: [timeline])
        )

        let unified = UnifiedPollenData.from(tomorrowIO: data)

        #expect(unified != nil)
        #expect(unified?.dates.count == 2)
        #expect(unified?.grassLevels == [75.0, 50.0])  // 3.0 * 25, 2.0 * 25
        #expect(unified?.treeLevels == [50.0, 100.0])  // 2.0 * 25, 4.0 * 25
        #expect(unified?.weedLevels == [25.0, 75.0])  // 1.0 * 25, 3.0 * 25
    }

    @Test func fromTomorrowIONoTimelines() {
        let data = TomorrowIOPollenData(
            data: TomorrowIOPollenData.TomorrowIOTimelineData(timelines: [])
        )

        let unified = UnifiedPollenData.from(tomorrowIO: data)
        #expect(unified == nil)
    }

    @Test func unifiedPollenMaxInRange() {
        let unified = UnifiedPollenData(
            dates: ["2026-02-14T00:00", "2026-02-14T01:00", "2026-02-14T02:00"],
            grassLevels: [10.0, 20.0, 15.0],
            treeLevels: [5.0, 8.0, 12.0],
            weedLevels: [15.0, 30.0, 18.0]
        )

        let result = unified.maxPollenInRange(start: 0, count: 3)
        #expect(result != nil)
        #expect(result?.type == .ragweed)
        #expect(result?.value == 30.0)
    }

    @Test func unifiedPollenMaxInRangeGrass() {
        let unified = UnifiedPollenData(
            dates: ["2026-02-14T00:00"],
            grassLevels: [50.0],
            treeLevels: [20.0],
            weedLevels: [15.0]
        )

        let result = unified.maxPollenInRange(start: 0, count: 1)
        #expect(result != nil)
        #expect(result?.type == .grass)
        #expect(result?.value == 50.0)
    }

    @Test func unifiedPollenMaxInRangeTree() {
        let unified = UnifiedPollenData(
            dates: ["2026-02-14T00:00"],
            grassLevels: [10.0],
            treeLevels: [60.0],
            weedLevels: [15.0]
        )

        let result = unified.maxPollenInRange(start: 0, count: 1)
        #expect(result != nil)
        #expect(result?.type == .birch)
        #expect(result?.value == 60.0)
    }

    @Test func unifiedPollenNoData() {
        let unified = UnifiedPollenData(
            dates: ["2026-02-14T00:00"],
            grassLevels: [],
            treeLevels: [],
            weedLevels: []
        )

        let result = unified.maxPollenInRange(start: 0, count: 1)
        #expect(result == nil)
    }
}

// MARK: - Weather Model Tests

@MainActor
struct WeatherModelStructTests {

    @Test func weatherDataEquality() {
        let current1 = CurrentWeather(
            time: "2026-02-14T12:00",
            temperature2m: 72.5,
            apparentTemperature: 70.0,
            weatherCode: 0,
            windSpeed10m: 10.0,
            windDirection10m: 180.0,
            windGusts10m: 15.0,
            relativeHumidity2m: 65,
            dewPoint2m: 55.0,
            pressure: 1013.25,
            cloudCover: 25,
            visibility: 10000.0,
            uvIndex: 5.0,
            isDay: 1,
            precipitation: 0.0
        )

        let current2 = CurrentWeather(
            time: "2026-02-14T12:00",
            temperature2m: 72.5,
            apparentTemperature: 70.0,
            weatherCode: 0,
            windSpeed10m: 10.0,
            windDirection10m: 180.0,
            windGusts10m: 15.0,
            relativeHumidity2m: 65,
            dewPoint2m: 55.0,
            pressure: 1013.25,
            cloudCover: 25,
            visibility: 10000.0,
            uvIndex: 5.0,
            isDay: 1,
            precipitation: 0.0
        )

        #expect(current1 == current2)
    }

    @Test func hourlyWeatherArrayHandling() {
        let hourly = HourlyWeather(
            time: ["2026-02-14T00:00", "2026-02-14T01:00"],
            temperature2m: [65.0, 64.0],
            weatherCode: [0, 1],
            precipitationProbability: [10, 20],
            windSpeed10m: [5.0, 6.0],
            windGusts10m: [8.0, 9.0],
            relativeHumidity2m: [70, 72],
            uvIndex: [0.0, 0.0]
        )

        #expect(hourly.time.count == 2)
        #expect(hourly.temperature2m.count == 2)
        #expect(hourly.precipitationProbability?.count == 2)
    }

    @Test func dailyWeatherOptionalArrays() {
        let daily = DailyWeather(
            time: ["2026-02-14"],
            weatherCode: [0],
            temperature2mMax: [75.0],
            temperature2mMin: [60.0],
            precipitationProbabilityMax: [15],
            sunrise: ["07:00"],
            sunset: ["18:00"],
            uvIndexMax: [6.0],
            windSpeed10mMax: [12.0],
            windGusts10mMax: [18.0]
        )

        #expect(daily.time.count == 1)
        #expect(daily.temperature2mMax.count == 1)
        #expect(daily.uvIndexMax.count == 1)
    }
}

@MainActor
struct AirQualityModelTests {

    @Test func airQualityDecoding() throws {
        let json = """
            {
                "latitude": 40.7128,
                "longitude": -74.0060,
                "timezone": "America/New_York",
                "current": {
                    "time": "2026-02-14T12:00",
                    "us_aqi": 45,
                    "pm10": 15.5,
                    "pm2_5": 8.2,
                    "carbon_monoxide": 250.0,
                    "nitrogen_dioxide": 12.5,
                    "sulphur_dioxide": 5.0,
                    "ozone": 35.0
                }
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let airQuality = try decoder.decode(AirQualityData.self, from: data)

        #expect(airQuality.latitude == 40.7128)
        #expect(airQuality.current.usAqi == 45)
        #expect(airQuality.current.pm10 == 15.5)
        #expect(airQuality.current.pm25 == 8.2)
    }

    @Test func currentAirQualityEquality() {
        let current1 = CurrentAirQuality(
            time: "2026-02-14T12:00",
            usAqi: 50,
            pm10: 20.0,
            pm25: 10.0,
            ozone: 40.0,
            nitrogenDioxide: 15.0,
            sulphurDioxide: 8.0,
            carbonMonoxide: 300.0
        )

        let current2 = CurrentAirQuality(
            time: "2026-02-14T12:00",
            usAqi: 50,
            pm10: 20.0,
            pm25: 10.0,
            ozone: 40.0,
            nitrogenDioxide: 15.0,
            sulphurDioxide: 8.0,
            carbonMonoxide: 300.0
        )

        #expect(current1 == current2)
    }
}

// MARK: - Shared Weather Data Tests

@MainActor
struct SharedDataModelTests {

    @Test func sharedWeatherDataCodingRoundTrip() throws {
        let hourly = SharedHourlyData(
            time: "12:00 PM",
            temperature: 72.0,
            weatherCode: 0
        )

        let shared = SharedWeatherData(
            temperature: 70.0,
            apparentTemperature: 68.0,
            weatherCode: 1,
            isDay: 1,
            humidity: 65,
            windSpeed: 10.0,
            highTemp: 75.0,
            lowTemp: 60.0,
            precipitationProbability: 20,
            locationName: "San Francisco",
            lastUpdated: Date(),
            hourlyForecast: [hourly]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(shared)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SharedWeatherData.self, from: data)

        #expect(decoded.locationName == "San Francisco")
        #expect(decoded.temperature == 70.0)
        #expect(decoded.weatherCode == 1)
        #expect(decoded.hourlyForecast.count == 1)
    }
}
