//
//  OpenMeteoConfig.swift
//  weather
//
//  Shared configuration for Open-Meteo API calls
//

import Foundation

// MARK: - Open-Meteo API Configuration

enum OpenMeteoConfig {
    // MARK: - Base URLs
    
    static let forecastURL = "https://api.open-meteo.com/v1/forecast"
    static let airQualityURL = "https://api.open-meteo.com/v1/air-quality"
    static let historicalURL = "https://archive-api.open-meteo.com/v1/archive"
    
    // MARK: - API Parameters
    
    /// Current weather parameters for all endpoints
    static let currentParameters = "temperature_2m,apparent_temperature,weather_code," +
        "wind_speed_10m,wind_direction_10m,wind_gusts_10m," +
        "relative_humidity_2m,dew_point_2m,pressure_msl," +
        "cloud_cover,visibility,uv_index,precipitation,is_day"
    
    /// Hourly forecast parameters
    static let hourlyParameters = "temperature_2m,weather_code," +
        "precipitation_probability,wind_speed_10m,wind_gusts_10m," +
        "relative_humidity_2m,uv_index"
    
    /// Daily forecast parameters
    static let dailyParameters = "weather_code,temperature_2m_max,temperature_2m_min," +
        "precipitation_probability_max,sunrise,sunset," +
        "uv_index_max,wind_speed_10m_max"
    
    /// Air quality parameters
    static let airQualityParameters = "us_aqi,pm10,pm2_5,ozone,nitrogen_dioxide,sulphur_dioxide,carbon_monoxide"
    
    /// Pollen parameters (European Air Quality Index)
    static let pollenParameters = "alder_pollen,birch_pollen,grass_pollen,ragweed_pollen"
    
    /// Historical weather parameters
    static let historicalDailyParameters = "weather_code,temperature_2m_max,temperature_2m_min," +
        "precipitation_sum,wind_speed_10m_max"
    
    // MARK: - Shared JSON Decoder
    
    /// Shared decoder instance - creating decoders is expensive
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Network Configuration
    
    /// Cache capacity: 10 MB in memory
    static let memoryCacheCapacity = 10_000_000
    /// Cache capacity: 50 MB on disk
    static let diskCacheCapacity = 50_000_000
    /// Timeout for individual requests (seconds)
    static let requestTimeout: TimeInterval = 15
    /// Timeout for overall resource loading (seconds)
    static let resourceTimeout: TimeInterval = 30
    
    // MARK: - Shared URL Sessions
    
    /// Shared URL session with caching enabled for faster repeated requests
    static let cachedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: memoryCacheCapacity, diskCapacity: diskCacheCapacity)
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = resourceTimeout
        return URLSession(configuration: config)
    }()
    
    /// Separate session that bypasses HTTP cache for force-refresh requests
    static let forceRefreshSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = resourceTimeout
        return URLSession(configuration: config)
    }()
}
