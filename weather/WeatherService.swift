//
//  WeatherService.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation

@Observable
final class WeatherService {
    var weatherData: WeatherData?
    var isLoading = false
    var errorMessage: String?
    
    func fetchWeather(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Build OpenMeteo API URL
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        
        guard let url = components?.url else {
            errorMessage = "Invalid URL"
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "Server error"
                return
            }
            
            let decoder = JSONDecoder()
            weatherData = try decoder.decode(WeatherData.self, from: data)
        } catch {
            errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
        }
    }
}
