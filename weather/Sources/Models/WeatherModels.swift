//
//  WeatherModels.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation
import SwiftUI

// MARK: - Weather Data Models

struct WeatherData: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentWeather
    let hourly: HourlyWeather
    let daily: DailyWeather
}

struct CurrentWeather: Codable {
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
        case pressure = "surface_pressure"
        case cloudCover = "cloud_cover"
        case visibility
        case uvIndex = "uv_index"
        case isDay = "is_day"
        case precipitation
    }
}

struct HourlyWeather: Codable {
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

struct DailyWeather: Codable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationProbabilityMax: [Int]
    let sunrise: [String]
    let sunset: [String]
    let uvIndexMax: [Double?]
    let windSpeed10mMax: [Double?]
    let windGusts10mMax: [Double?]
    
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
}

// MARK: - Weather Condition Helpers

enum WeatherCondition {
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
    
    // Alias for consistency
    var sfSymbol: String { symbolName }
    
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

struct AirQualityData: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentAirQuality
}

struct CurrentAirQuality: Codable {
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
