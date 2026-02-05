//
//  WeatherService.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation
import CoreLocation

// MARK: - Weather Alert (additional model not in WeatherModels)

struct WeatherAlert: Codable, Sendable, Identifiable {
    var id: String { event + effective.description }
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

