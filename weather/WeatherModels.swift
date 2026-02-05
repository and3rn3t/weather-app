//
//  WeatherModels.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation

// MARK: - Weather Data Models

struct WeatherData: Codable {
    let latitude: Double
    let longitude: Double
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
    let relativeHumidity2m: Int
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
        case relativeHumidity2m = "relative_humidity_2m"
    }
}

struct HourlyWeather: Codable {
    let time: [String]
    let temperature2m: [Double]
    let weatherCode: [Int]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
    }
}

struct DailyWeather: Codable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationProbabilityMax: [Int]
    
    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
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
}
