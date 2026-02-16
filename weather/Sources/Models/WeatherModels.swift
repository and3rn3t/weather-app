//
//  WeatherModels.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation

// MARK: - Weather Data Models

struct WeatherData: Codable, Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentWeather
    let hourly: HourlyWeather
    let daily: DailyWeather
}

struct CurrentWeather: Codable, Sendable, Equatable {
    let time: String
    let temperature2m: Double
    let apparentTemperature: Double
    let weatherCode: Int
    let windSpeed10m: Double
    let windDirection10m: Double
    let windGusts10m: Double
    let relativeHumidity2m: Int
    let dewPoint2m: Double
    let pressure: Double
    let cloudCover: Int
    let visibility: Double
    let uvIndex: Double
    let isDay: Int
    let precipitation: Double
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
        case windDirection10m = "wind_direction_10m"
        case windGusts10m = "wind_gusts_10m"
        case relativeHumidity2m = "relative_humidity_2m"
        case dewPoint2m = "dew_point_2m"
        case pressureMSL = "pressure_msl"
        case cloudCover = "cloud_cover"
        case visibility
        case uvIndex = "uv_index"
        case isDay = "is_day"
        case precipitation
    }

    private enum LegacyKeys: String, CodingKey {
        case surfacePressure = "surface_pressure"
    }

    init(
        time: String,
        temperature2m: Double,
        apparentTemperature: Double,
        weatherCode: Int,
        windSpeed10m: Double,
        windDirection10m: Double,
        windGusts10m: Double,
        relativeHumidity2m: Int,
        dewPoint2m: Double,
        pressure: Double,
        cloudCover: Int,
        visibility: Double,
        uvIndex: Double,
        isDay: Int,
        precipitation: Double
    ) {
        self.time = time
        self.temperature2m = temperature2m
        self.apparentTemperature = apparentTemperature
        self.weatherCode = weatherCode
        self.windSpeed10m = windSpeed10m
        self.windDirection10m = windDirection10m
        self.windGusts10m = windGusts10m
        self.relativeHumidity2m = relativeHumidity2m
        self.dewPoint2m = dewPoint2m
        self.pressure = pressure
        self.cloudCover = cloudCover
        self.visibility = visibility
        self.uvIndex = uvIndex
        self.isDay = isDay
        self.precipitation = precipitation
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(String.self, forKey: .time)
        temperature2m = try container.decode(Double.self, forKey: .temperature2m)
        apparentTemperature = try container.decode(Double.self, forKey: .apparentTemperature)
        weatherCode = try container.decode(Int.self, forKey: .weatherCode)
        windSpeed10m = try container.decode(Double.self, forKey: .windSpeed10m)
        windDirection10m = try container.decodeIfPresent(Double.self, forKey: .windDirection10m) ?? 0
        windGusts10m = try container.decodeIfPresent(Double.self, forKey: .windGusts10m) ?? 0
        relativeHumidity2m = try container.decodeIfPresent(Int.self, forKey: .relativeHumidity2m) ?? 0
        dewPoint2m = try container.decodeIfPresent(Double.self, forKey: .dewPoint2m) ?? 0
        let legacy = try decoder.container(keyedBy: LegacyKeys.self)
        pressure = try container.decodeIfPresent(Double.self, forKey: .pressureMSL)
            ?? legacy.decodeIfPresent(Double.self, forKey: .surfacePressure)
            ?? 0
        cloudCover = try container.decodeIfPresent(Int.self, forKey: .cloudCover) ?? 0
        visibility = try container.decodeIfPresent(Double.self, forKey: .visibility) ?? 0
        uvIndex = try container.decodeIfPresent(Double.self, forKey: .uvIndex) ?? 0
        isDay = try container.decode(Int.self, forKey: .isDay)
        precipitation = try container.decodeIfPresent(Double.self, forKey: .precipitation) ?? 0
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)
        try container.encode(temperature2m, forKey: .temperature2m)
        try container.encode(apparentTemperature, forKey: .apparentTemperature)
        try container.encode(weatherCode, forKey: .weatherCode)
        try container.encode(windSpeed10m, forKey: .windSpeed10m)
        try container.encode(windDirection10m, forKey: .windDirection10m)
        try container.encode(windGusts10m, forKey: .windGusts10m)
        try container.encode(relativeHumidity2m, forKey: .relativeHumidity2m)
        try container.encode(dewPoint2m, forKey: .dewPoint2m)
        try container.encode(pressure, forKey: .pressureMSL)
        try container.encode(cloudCover, forKey: .cloudCover)
        try container.encode(visibility, forKey: .visibility)
        try container.encode(uvIndex, forKey: .uvIndex)
        try container.encode(isDay, forKey: .isDay)
        try container.encode(precipitation, forKey: .precipitation)
    }
}

struct HourlyWeather: Codable, Sendable, Equatable {
    let time: [String]
    let temperature2m: [Double]
    let weatherCode: [Int]
    let precipitationProbability: [Int]?
    let windSpeed10m: [Double]?
    let windGusts10m: [Double]?
    let relativeHumidity2m: [Int]?
    let uvIndex: [Double?]?
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case precipitationProbability = "precipitation_probability"
        case windSpeed10m = "wind_speed_10m"
        case windGusts10m = "wind_gusts_10m"
        case relativeHumidity2m = "relative_humidity_2m"
        case uvIndex = "uv_index"
    }
}

struct DailyWeather: Codable, Sendable, Equatable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationProbabilityMax: [Int]
    let sunrise: [String]
    let sunset: [String]
    let uvIndexMax: [Double?]
    let windSpeed10mMax: [Double?]
    let windGusts10mMax: [Double?]?
    
    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case sunrise
        case sunset
        case uvIndexMax = "uv_index_max"
        case windSpeed10mMax = "wind_speed_10m_max"
        case windGusts10mMax = "wind_gusts_10m_max"
    }

    init(
        time: [String],
        weatherCode: [Int],
        temperature2mMax: [Double],
        temperature2mMin: [Double],
        precipitationProbabilityMax: [Int],
        sunrise: [String],
        sunset: [String],
        uvIndexMax: [Double?],
        windSpeed10mMax: [Double?],
        windGusts10mMax: [Double?]?
    ) {
        self.time = time
        self.weatherCode = weatherCode
        self.temperature2mMax = temperature2mMax
        self.temperature2mMin = temperature2mMin
        self.precipitationProbabilityMax = precipitationProbabilityMax
        self.sunrise = sunrise
        self.sunset = sunset
        self.uvIndexMax = uvIndexMax
        self.windSpeed10mMax = windSpeed10mMax
        self.windGusts10mMax = windGusts10mMax
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode([String].self, forKey: .time)
        weatherCode = try container.decode([Int].self, forKey: .weatherCode)
        temperature2mMax = try container.decode([Double].self, forKey: .temperature2mMax)
        temperature2mMin = try container.decode([Double].self, forKey: .temperature2mMin)
        if let ints = try? container.decode([Int].self, forKey: .precipitationProbabilityMax) {
            precipitationProbabilityMax = ints
        } else if let doubles = try? container.decode([Double].self, forKey: .precipitationProbabilityMax) {
            precipitationProbabilityMax = doubles.map { Int($0.rounded()) }
        } else {
            precipitationProbabilityMax = []
        }
        sunrise = try container.decode([String].self, forKey: .sunrise)
        sunset = try container.decode([String].self, forKey: .sunset)
        uvIndexMax = try container.decodeIfPresent([Double?].self, forKey: .uvIndexMax) ?? []
        windSpeed10mMax = try container.decodeIfPresent([Double?].self, forKey: .windSpeed10mMax) ?? []
        windGusts10mMax = try container.decodeIfPresent([Double?].self, forKey: .windGusts10mMax)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)
        try container.encode(weatherCode, forKey: .weatherCode)
        try container.encode(temperature2mMax, forKey: .temperature2mMax)
        try container.encode(temperature2mMin, forKey: .temperature2mMin)
        try container.encode(precipitationProbabilityMax, forKey: .precipitationProbabilityMax)
        try container.encode(sunrise, forKey: .sunrise)
        try container.encode(sunset, forKey: .sunset)
        try container.encode(uvIndexMax, forKey: .uvIndexMax)
        try container.encode(windSpeed10mMax, forKey: .windSpeed10mMax)
        try container.encodeIfPresent(windGusts10mMax, forKey: .windGusts10mMax)
    }
}

// MARK: - Weather Condition Helpers

import SwiftUI

enum WeatherCondition: Equatable, Hashable {
    case clearSky
    case partlyCloudy
    case cloudy
    case foggy
    case drizzle
    case rain
    case snow
    case thunderstorm
    case unknown
    
    init(code: Int) {
        switch code {
        case 0:
            self = .clearSky
        case 1, 2:
            self = .partlyCloudy
        case 3:
            self = .cloudy
        case 45, 48:
            self = .foggy
        case 51, 53, 55:
            self = .drizzle
        case 61, 63, 65, 80, 81, 82:
            self = .rain
        case 71, 73, 75, 77, 85, 86:
            self = .snow
        case 95, 96, 99:
            self = .thunderstorm
        default:
            self = .unknown
        }
    }
    
    var description: String {
        switch self {
        case .clearSky: return "Clear Sky"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .foggy: return "Foggy"
        case .drizzle: return "Drizzle"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .thunderstorm: return "Thunderstorm"
        case .unknown: return "Unknown"
        }
    }
    
    var symbolName: String {
        switch self {
        case .clearSky: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .clearSky: return .orange
        case .partlyCloudy: return .yellow
        case .cloudy: return .gray
        case .foggy: return .gray.opacity(0.7)
        case .drizzle: return .blue.opacity(0.7)
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .unknown: return .gray
        }
    }
}

// MARK: - Air Quality Models

struct AirQualityData: Codable, Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentAirQuality
}

struct CurrentAirQuality: Codable, Sendable, Equatable {
    let time: String
    let usAqi: Int
    let pm10: Double
    let pm25: Double
    let ozone: Double?
    let nitrogenDioxide: Double?
    let sulphurDioxide: Double?
    let carbonMonoxide: Double?
    
    enum CodingKeys: String, CodingKey {
        case time
        case usAqi = "us_aqi"
        case pm10
        case pm25 = "pm2_5"
        case ozone
        case nitrogenDioxide = "nitrogen_dioxide"
        case sulphurDioxide = "sulphur_dioxide"
        case carbonMonoxide = "carbon_monoxide"
    }
}
