//
//  WeatherService.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation
import CoreLocation

// MARK: - Weather Data Models

struct WeatherData: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentWeather
    let hourly: HourlyWeather
    let daily: DailyWeather
    let alerts: [WeatherAlert]?
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude, timezone, current, hourly, daily, alerts
    }
}

struct CurrentWeather: Codable, Sendable {
    let time: String
    let temperature: Double
    let apparentTemperature: Double
    let weatherCode: Int
    let isDay: Int
    let precipitation: Double
    let windSpeed: Double
    let windDirection: Int
    let humidity: Int
    let pressure: Double
    let visibility: Double
    let uvIndex: Double
    let cloudCover: Int
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case weatherCode = "weather_code"
        case isDay = "is_day"
        case precipitation
        case windSpeed = "wind_speed_10m"
        case windDirection = "wind_direction_10m"
        case humidity = "relative_humidity_2m"
        case pressure = "surface_pressure"
        case visibility
        case uvIndex = "uv_index"
        case cloudCover = "cloud_cover"
    }
}

struct HourlyWeather: Codable, Sendable {
    let time: [String]
    let temperature: [Double]
    let apparentTemperature: [Double]
    let weatherCode: [Int]
    let precipitation: [Double]
    let precipitationProbability: [Int]
    let windSpeed: [Double]
    let windDirection: [Int]
    let humidity: [Int]
    let uvIndex: [Double]
    let visibility: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case weatherCode = "weather_code"
        case precipitation
        case precipitationProbability = "precipitation_probability"
        case windSpeed = "wind_speed_10m"
        case windDirection = "wind_direction_10m"
        case humidity = "relative_humidity_2m"
        case uvIndex = "uv_index"
        case visibility
    }
}

struct DailyWeather: Codable, Sendable {
    let time: [String]
    let weatherCode: [Int]
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    let sunrise: [String]
    let sunset: [String]
    let precipitationSum: [Double]
    let precipitationProbability: [Int]
    let windSpeedMax: [Double]
    let uvIndexMax: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case sunrise
        case sunset
        case precipitationSum = "precipitation_sum"
        case precipitationProbability = "precipitation_probability_max"
        case windSpeedMax = "wind_speed_10m_max"
        case uvIndexMax = "uv_index_max"
    }
}

struct WeatherAlert: Codable, Sendable, Identifiable {
    let id: String
    let event: String
    let headline: String
    let description: String
    let severity: String
    let urgency: String
    let areas: String
    let effective: Date
    let expires: Date
    let senderName: String
    
    enum CodingKeys: String, CodingKey {
        case id = "event"
        case event
        case headline
        case description
        case severity
        case urgency
        case areas
        case effective
        case expires
        case senderName = "sender_name"
    }
}

// MARK: - Weather Service

@Observable
class WeatherService {
    var weatherData: WeatherData?
    var isLoading = false
    var errorMessage: String?
    
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    
    func fetchWeather(latitude: Double, longitude: Double) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Build URL components
            var components = URLComponents(string: baseURL)
            components?.queryItems = [
                URLQueryItem(name: "latitude", value: String(latitude)),
                URLQueryItem(name: "longitude", value: String(longitude)),
                URLQueryItem(name: "current", value: currentParameters),
                URLQueryItem(name: "hourly", value: hourlyParameters),
                URLQueryItem(name: "daily", value: dailyParameters),
                URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
                URLQueryItem(name: "wind_speed_unit", value: "mph"),
                URLQueryItem(name: "precipitation_unit", value: "inch"),
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "forecast_days", value: "14")
            ]
            
            guard let url = components?.url else {
                await MainActor.run {
                    self.errorMessage = "Invalid URL"
                    self.isLoading = false
                }
                return
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.errorMessage = "Server error"
                    self.isLoading = false
                }
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let weather = try decoder.decode(WeatherData.self, from: data)
            
            await MainActor.run {
                self.weatherData = weather
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private var currentParameters: String {
        [
            "temperature_2m",
            "apparent_temperature",
            "weather_code",
            "is_day",
            "precipitation",
            "wind_speed_10m",
            "wind_direction_10m",
            "relative_humidity_2m",
            "surface_pressure",
            "visibility",
            "uv_index",
            "cloud_cover"
        ].joined(separator: ",")
    }
    
    private var hourlyParameters: String {
        [
            "temperature_2m",
            "apparent_temperature",
            "weather_code",
            "precipitation",
            "precipitation_probability",
            "wind_speed_10m",
            "wind_direction_10m",
            "relative_humidity_2m",
            "uv_index",
            "visibility"
        ].joined(separator: ",")
    }
    
    private var dailyParameters: String {
        [
            "weather_code",
            "temperature_2m_max",
            "temperature_2m_min",
            "sunrise",
            "sunset",
            "precipitation_sum",
            "precipitation_probability_max",
            "wind_speed_10m_max",
            "uv_index_max"
        ].joined(separator: ",")
    }
}

// MARK: - Weather Condition Mapping

enum WeatherCondition: Sendable {
    case clearSky
    case partlyCloudy
    case cloudy
    case fog
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
            self = .fog
        case 51, 53, 55, 56, 57:
            self = .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82:
            self = .rain
        case 71, 73, 75, 77, 85, 86:
            self = .snow
        case 95, 96, 99:
            self = .thunderstorm
        default:
            self = .unknown
        }
    }
    
    var icon: String {
        switch self {
        case .clearSky:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .cloudy:
            return "cloud.fill"
        case .fog:
            return "cloud.fog.fill"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .rain:
            return "cloud.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorm:
            return "cloud.bolt.rain.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .clearSky:
            return "Clear Sky"
        case .partlyCloudy:
            return "Partly Cloudy"
        case .cloudy:
            return "Cloudy"
        case .fog:
            return "Foggy"
        case .drizzle:
            return "Drizzle"
        case .rain:
            return "Rain"
        case .snow:
            return "Snow"
        case .thunderstorm:
            return "Thunderstorm"
        case .unknown:
            return "Unknown"
        }
    }
}
