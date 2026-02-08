//
//  WeatherService.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation
import CoreLocation
import OSLog

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
    var airQualityData: AirQualityData?
    var isLoading = false
    var errorMessage: String?
    var lastError: WeatherError?
    var currentLocationName: String?
    
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private let airQualityURL = "https://air-quality-api.open-meteo.com/v1/air-quality"
    
    // MARK: - Constants
    
    /// Cache capacity: 10 MB in memory
    private static let memoryCacheCapacity = 10_000_000
    /// Cache capacity: 50 MB on disk
    private static let diskCacheCapacity = 50_000_000
    /// Timeout for individual requests (seconds)
    private static let requestTimeout: TimeInterval = 15
    /// Timeout for overall resource loading (seconds)
    private static let resourceTimeout: TimeInterval = 30
    
    // MARK: - Performance Optimizations
    
    /// Shared URL session with caching enabled for faster repeated requests
    private static let cachedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: memoryCacheCapacity, diskCapacity: diskCacheCapacity)
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = resourceTimeout
        return URLSession(configuration: config)
    }()
    
    /// Shared decoder - creating decoders is expensive
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    /// Last successful fetch timestamp for debouncing
    private var lastFetchTime: Date?
    private let minimumFetchInterval: TimeInterval = 60 // 1 minute minimum between fetches
    
    // MARK: - Public Methods
    
    func fetchWeather(latitude: Double, longitude: Double, locationName: String? = nil, forceRefresh: Bool = false) async {
        self.currentLocationName = locationName
        
        // Debounce: Skip fetch if we recently fetched (unless force refresh)
        if !forceRefresh, let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < minimumFetchInterval,
           weatherData != nil {
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            lastError = nil
        }
        
        do {
            // Perform weather fetch; kick off air quality in parallel (fire-and-forget)
            async let airQualityTask: Void = fetchAirQuality(latitude: latitude, longitude: longitude)
            let weather = try await performWeatherFetchWithRetry(latitude: latitude, longitude: longitude)
            
            // Update last fetch time on success
            lastFetchTime = Date()
            
            await MainActor.run {
                self.weatherData = weather
                self.isLoading = false
            }
            
            // Save to shared storage for widgets + cache full data for instant startup
            SharedDataManager.shared.saveWeatherData(weather, locationName: currentLocationName)
            SharedDataManager.shared.cacheFullWeatherData(weather, locationName: currentLocationName)
            
            // Await air quality completion (already running in parallel)
            await airQualityTask
            
        } catch let error as WeatherError {
            // Try offline fallback before showing error
            if SharedDataManager.shared.loadWeatherData() != nil {
                await MainActor.run {
                    // Show cached data with error message as warning
                    self.isLoading = false
                    self.errorMessage = "Showing cached data. " + (error.recoverySuggestion ?? "")
                }
            } else {
                await handleError(error)
            }
        } catch let urlError as URLError {
            if SharedDataManager.shared.loadWeatherData() != nil {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Showing cached data. Check your connection."
                }
            } else {
                await handleError(.from(urlError))
            }
        } catch {
            await handleError(.unknown(error.localizedDescription))
        }
    }
    
    private func performWeatherFetchWithRetry(latitude: Double, longitude: Double) async throws -> WeatherData {
        let config = RetryConfiguration.default
        var lastError: Error?
        
        for attempt in 1...config.maxAttempts {
            do {
                return try await performWeatherFetch(latitude: latitude, longitude: longitude)
            } catch let error as WeatherError where error.isRetryable && attempt < config.maxAttempts {
                lastError = error
                let delay = config.delay(for: attempt)
                try await Task.sleep(for: .seconds(delay))
            } catch {
                throw error
            }
        }
        
        throw lastError ?? WeatherError.unknown("Request failed after retries")
    }
    
    func retry() async {
        // Use the stored location from weatherData if available
        if let weather = weatherData {
            await fetchWeather(latitude: weather.latitude, longitude: weather.longitude, locationName: currentLocationName)
        } else {
            await handleError(.locationUnavailable)
        }
    }
    
    // MARK: - Private Methods
    
    private func performWeatherFetch(latitude: Double, longitude: Double) async throws -> WeatherData {
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
            throw WeatherError.invalidURL
        }
        
        // Use cached session for better performance
        let (data, response) = try await Self.cachedSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        
        if let error = WeatherError.from(statusCode: httpResponse.statusCode) {
            throw error
        }
        
        do {
            // Use static decoder for better performance
            return try Self.decoder.decode(WeatherData.self, from: data)
        } catch let decodingError as DecodingError {
            throw WeatherError.decodingError(decodingError.localizedDescription)
        }
    }
    
    private func handleError(_ error: WeatherError) async {
        await MainActor.run {
            self.lastError = error
            self.errorMessage = error.errorDescription
            self.isLoading = false
        }
    }
    
    func fetchAirQuality(latitude: Double, longitude: Double) async {
        var components = URLComponents(string: airQualityURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "us_aqi,pm10,pm2_5,ozone,nitrogen_dioxide,sulphur_dioxide,carbon_monoxide"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        guard let url = components?.url else { return }
        
        do {
            let (data, response) = try await Self.cachedSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }
            
            let airQuality = try Self.decoder.decode(AirQualityData.self, from: data)
            
            await MainActor.run {
                self.airQualityData = airQuality
            }
        } catch {
            // Air quality is optional
            Logger.weatherService.warning("Failed to fetch air quality: \(error.localizedDescription)")
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
            "wind_gusts_10m",
            "relative_humidity_2m",
            "dew_point_2m",
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
            "wind_gusts_10m",
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
            "wind_gusts_10m_max",
            "uv_index_max"
        ].joined(separator: ",")
    }
}

