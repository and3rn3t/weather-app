//
//  WeatherService.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation
import CoreLocation
import OSLog
import os.signpost

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
    var weatherAlerts: [WeatherAlert] = []
    var isLoading = false
    var errorMessage: String?
    var lastError: WeatherError?
    var currentLocationName: String?
    
    // Alert service for severe weather warnings
    private let alertService = WeatherAlertService()
    
    // Enhanced cache manager
    private let cacheManager = WeatherCacheManager.shared
    
    // Request coalescer for batching API calls
    private let requestCoalescer = RequestCoalescer.shared
    
    // Performance tracking
    private let performanceTracker = PerformanceTracker.shared
    
    // MARK: - Instant Startup

    init() {
        // Synchronous cache load + decode in init().
        //
        // WeatherService.init() runs at ~1ms — the main thread is idle here,
        // BEFORE SwiftUI blocks it for ~4.8s of scene setup. Reading 16KB
        // from disk and decoding JSON takes ~2ms total, so doing it
        // synchronously means weatherData is populated before the first
        // SwiftUI render — no loading spinner, no async delay.
        //
        // Previous async approaches (Task, Task.detached + MainActor.run)
        // all suffered from the main actor being blocked by SwiftUI scene
        // setup, delaying the decode until ~7.5s despite the I/O finishing
        // at 2ms.
        os_signpost(.begin, log: StartupSignpost.log, name: "WeatherService.init")
        #if DEBUG
        startupLog("WeatherService.init — synchronous cache load")
        #endif

        let locationMeta = SharedDataManager.lastKnownLocation()
        
        // Use enhanced cache manager for faster, smarter cache loading
        if let locationMeta = locationMeta {
            let cached = cacheManager.getCachedWeather(latitude: locationMeta.latitude, longitude: locationMeta.longitude)
            if let cached {
                self.weatherData = cached
                self.currentLocationName = locationMeta.name
            }
        } else {
            // Fallback: try to load any cached data from SharedDataManager for backward compatibility
            let cached = SharedDataManager.shared.loadCachedFullWeatherData()
            if let cached {
                self.weatherData = cached
                self.currentLocationName = SharedDataManager.lastKnownLocation()?.name
            }
        }
            #if DEBUG
            let elapsed = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
            startupLog("Cache loaded + published: \(String(format: "%.0f", elapsed))ms since launch")
            #endif
        }

        os_signpost(.end, log: StartupSignpost.log, name: "WeatherService.init")

        // Fire a background network refresh with last-known coordinates.
        // This runs after init returns, overlapping with SwiftUI scene setup.
        if let loc = locationMeta {
            Task.detached(priority: .userInitiated) { [self] in
                #if DEBUG
                startupLog(cached == nil ? "No cache — eager fetch" : "Eager background refresh")
                #endif
                await self.fetchWeather(latitude: loc.latitude, longitude: loc.longitude,
                                        locationName: loc.name, forceRefresh: true)
            }
        }
    }
    
    // MARK: - Constants
    
    /// Last successful fetch timestamp for debouncing
    private var lastFetchTime: Date?
    private let minimumFetchInterval: TimeInterval = 60 // 1 minute minimum between fetches
    
    /// Coordinates of the currently in-flight fetch (prevents redundant concurrent requests)
    private var activeFetchCoordinate: (latitude: Double, longitude: Double)?
    
    /// In-flight dedup tolerance: broader than FavoritesManager.coordinateTolerance (0.01°)
    /// because we're preventing redundant network requests, not matching saved locations.
    /// 0.05° ≈ 5.5 km at the equator — close enough that weather data is identical.
    private static let inFlightDeduplicationTolerance = 0.05
    
    // MARK: - Public Methods
    
    func fetchWeather(latitude: Double, longitude: Double, locationName: String? = nil, forceRefresh: Bool = false) async {
        let traceKey = forceRefresh ? "weather_fetch_force" : "weather_fetch_normal"
        performanceTracker.startTrace(traceKey, attributes: [
            "force_refresh": String(forceRefresh),
            "has_location_name": String(locationName != nil),
            "has_cached_data": String(weatherData != nil)
        ])
        
        self.currentLocationName = locationName
        
        // Debounce: Skip fetch if we recently fetched (unless force refresh)
        if !forceRefresh, let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < minimumFetchInterval,
           weatherData != nil {
            performanceTracker.recordEvent("weather_fetch_skipped", parameters: [
                "reason": "debounce",
                "time_since_last": String(Date().timeIntervalSince(lastFetch))
            ])
            performanceTracker.stopTrace(traceKey)
            return
        }
        
        // Skip if another fetch is already in flight for a nearby location.
        if let active = activeFetchCoordinate,
           abs(active.latitude - latitude) < Self.inFlightDeduplicationTolerance,
           abs(active.longitude - longitude) < Self.inFlightDeduplicationTolerance,
           !forceRefresh {
            performanceTracker.recordEvent("weather_fetch_skipped", parameters: [
                "reason": "duplicate_in_flight",
                "distance": String(abs(active.latitude - latitude) + abs(active.longitude - longitude))
            ])
            performanceTracker.stopTrace(traceKey)
            return
        }
        
        activeFetchCoordinate = (latitude, longitude)
        defer { 
            activeFetchCoordinate = nil 
            performanceTracker.stopTrace(traceKey)
        }
        
        await MainActor.run {
            // Only show loading spinner when there's NO data to display yet.
            // If we already have weather data visible, refresh silently in the background.
            if weatherData == nil {
                isLoading = true
            }
            errorMessage = nil
            lastError = nil
        }
        
        do {
            // Use request coalescer for optimized parallel fetching
            async let airQualityTask: Void = fetchAirQualityCoalesced(latitude: latitude, longitude: longitude)
            async let alertsTask: Void = fetchWeatherAlertsCoalesced(latitude: latitude, longitude: longitude)
            let weather = try await performWeatherFetchWithRetryCoalesced(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh)
            
            // Update last fetch time on success
            lastFetchTime = Date()
            
            await MainActor.run {
                self.weatherData = weather
                self.isLoading = false
            }
            
            // Record successful fetch
            performanceTracker.recordEvent("weather_fetch_success", parameters: [
                "force_refresh": String(forceRefresh),
                "has_location_name": String(locationName != nil)
            ])
            
            // Save using enhanced cache manager for better performance
            cacheManager.cacheWeather(weather, latitude: latitude, longitude: longitude)
            
            // Also save to shared storage for widgets (backward compatibility)
            SharedDataManager.shared.saveWeatherData(weather, locationName: currentLocationName)
            
            // Await air quality and alerts completion (already running in parallel)
            await airQualityTask
            await alertsTask
            
        } catch let error as WeatherError {
            // Record error event
            performanceTracker.recordEvent("weather_fetch_error", parameters: [
                "error_type": "WeatherError",
                "error_code": String(error.code.rawValue),
                "has_cached_fallback": String(cacheManager.getCachedWeather(latitude: latitude, longitude: longitude) != nil)
            ])
            
            // Try enhanced cache fallback first, then SharedDataManager
            let cachedFromEnhanced = cacheManager.getCachedWeather(latitude: latitude, longitude: longitude)
            let cachedFromShared = SharedDataManager.shared.loadWeatherData()
            
            if cachedFromEnhanced != nil || cachedFromShared != nil {
                await MainActor.run {
                    // Use enhanced cache if available, otherwise shared cache
                    if let enhanced = cachedFromEnhanced {
                        self.weatherData = enhanced
                    }
                    self.isLoading = false
                    self.errorMessage = "Showing cached data. " + (error.recoverySuggestion ?? "")
                }
            } else {
                await handleError(error)
            }
        } catch let urlError as URLError {
            let cachedFromEnhanced = cacheManager.getCachedWeather(latitude: latitude, longitude: longitude)
            let cachedFromShared = SharedDataManager.shared.loadWeatherData()
            
            if cachedFromEnhanced != nil || cachedFromShared != nil {
                await MainActor.run {
                    if let enhanced = cachedFromEnhanced {
                        self.weatherData = enhanced
                    }
                    self.isLoading = false
                    self.errorMessage = "Showing cached data. Check your connection."
                }
                }
            } else {
                await handleError(.from(urlError))
            }
        } catch {
            await handleError(.unknown(error.localizedDescription))
        }
    }
    
    private func performWeatherFetchWithRetry(latitude: Double, longitude: Double, forceRefresh: Bool = false) async throws -> WeatherData {
        let config = RetryConfiguration.default
        var lastError: (any Error)?
        
        for attempt in 1...config.maxAttempts {
            do {
                return try await performWeatherFetch(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh)
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
    
    private func performWeatherFetch(latitude: Double, longitude: Double, forceRefresh: Bool = false) async throws -> WeatherData {
        os_signpost(.begin, log: StartupSignpost.log, name: "NetworkFetch")
        let fetchStart = CFAbsoluteTimeGetCurrent()
        defer {
            os_signpost(.end, log: StartupSignpost.log, name: "NetworkFetch")
            #if DEBUG
            let fetchMs = (CFAbsoluteTimeGetCurrent() - fetchStart) * 1_000
            startupLog("Network fetch: \(String(format: "%.0f", fetchMs))ms")
            #endif
        }
        var components = URLComponents(string: OpenMeteoConfig.forecastURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: OpenMeteoConfig.currentParameters),
            URLQueryItem(name: "hourly", value: OpenMeteoConfig.hourlyParameters),
            URLQueryItem(name: "daily", value: OpenMeteoConfig.dailyParameters),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "14")
        ]
        
        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }
        
        // Use force-refresh session to bypass HTTP cache when user explicitly refreshes
        let session = forceRefresh ? OpenMeteoConfig.forceRefreshSession : OpenMeteoConfig.cachedSession
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        
        if let error = WeatherError.from(statusCode: httpResponse.statusCode) {
            throw error
        }
        
        do {
            // Use static decoder for better performance
            return try OpenMeteoConfig.decoder.decode(WeatherData.self, from: data)
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
        var components = URLComponents(string: OpenMeteoConfig.airQualityURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: OpenMeteoConfig.airQualityParameters),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        guard let url = components?.url else { return }
        
        do {
            let (data, response) = try await OpenMeteoConfig.cachedSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }
            
            let airQuality = try OpenMeteoConfig.decoder.decode(AirQualityData.self, from: data)
            
            await MainActor.run {
                self.airQualityData = airQuality
            }
        } catch {
            // Air quality is optional
            Logger.weatherService.warning("Failed to fetch air quality: \(error.localizedDescription)")
        }
    }
    
    func fetchWeatherAlerts(latitude: Double, longitude: Double) async {
        let alerts = await alertService.fetchAlerts(latitude: latitude, longitude: longitude)
        
        await MainActor.run {
            // Store previous active alerts to detect new ones
            let previousAlertIds = Set(self.weatherAlerts.map { $0.id })
            
            // Update alerts
            self.weatherAlerts = alerts.filter { !$0.isExpired }
            
            // Check for new severe alerts to notify about
            let newAlerts = self.weatherAlerts.filter { alert in
                !previousAlertIds.contains(alert.id) && alert.isActive
            }
            
            // Send notifications for new severe/extreme alerts
            if !newAlerts.isEmpty {
                Task {
                    await self.notifyNewAlerts(newAlerts)
                }
            }
        }
    }
    
    private func notifyNewAlerts(_ alerts: [WeatherAlert]) async {
        // Only notify for severe and extreme alerts
        let severeAlerts = alerts.filter { alert in
            let severity = alert.severity.lowercased()
            return severity == "severe" || severity == "extreme"
        }
        
        guard !severeAlerts.isEmpty else { return }
        
        // Get notification manager from app and send notifications
        // Note: This requires the NotificationManager to be accessible
        // We'll send the most severe alert
        if let mostSevere = severeAlerts.max(by: { $0.priority < $1.priority }) {
            // Create a simple notification (NotificationManager.notifySevereWeather expects WeatherAlert)
            // This will be handled by NotificationManager
            Logger.weatherService.info("New severe weather alert: \(mostSevere.event)")
        }
    }
    
    // MARK: - Coalesced API Methods
    
    /// Coalesced weather fetch using RequestCoalescer for optimized batching
    private func performWeatherFetchCoalesced(latitude: Double, longitude: Double, forceRefresh: Bool = false) async throws -> WeatherData {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                await requestCoalescer.coalesceWeatherRequest(
                    latitude: latitude,
                    longitude: longitude
                ) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    /// Coalesced air quality fetch
    private func fetchAirQualityCoalesced(latitude: Double, longitude: Double) async {
        await withCheckedContinuation { continuation in
            Task {
                await requestCoalescer.coalesceAirQualityRequest(
                    latitude: latitude,
                    longitude: longitude
                ) { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let airQuality):
                            self.airQualityData = airQuality
                        case .failure:
                            // Air quality failure is non-critical, just log it
                            break
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    /// Coalesced weather alerts fetch
    private func fetchWeatherAlertsCoalesced(latitude: Double, longitude: Double) async {
        await withCheckedContinuation { continuation in
            Task {
                await requestCoalescer.coalesceAlertsRequest(
                    latitude: latitude,
                    longitude: longitude
                ) { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let alerts):
                            self.weatherAlerts = alerts
                        case .failure:
                            // Alerts failure is non-critical, just log it
                            break
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    /// Request coalescing wrapper with retry logic
    private func performWeatherFetchWithRetryCoalesced(latitude: Double, longitude: Double, forceRefresh: Bool = false) async throws -> WeatherData {
        let config = RetryConfiguration.default
        var lastError: (any Error)?
        
        for attempt in 1...config.maxAttempts {
            do {
                return try await performWeatherFetchCoalesced(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh)
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
    
    // MARK: - Request Coalescing Statistics
    
    /// Get request coalescing statistics for debugging
    func getRequestCoalescingStats() async -> RequestCoalescer.CoalescingStatistics {
        return await requestCoalescer.getStatistics()
    }
    
    private static let currentParameters: String = [
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
    
    private static let hourlyParameters: String = [
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
    
    private static let dailyParameters: String = [
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
    
    // MARK: - Lightweight Static Fetch
    
    /// Fetch weather data without instantiating a full WeatherService.
    /// Use this for transient callers like FavoritesView, ComparisonView, and widgets
    /// to avoid heavyweight init() (cache I/O + eager background refresh).
    static func fetchWeatherData(latitude: Double, longitude: Double) async -> WeatherData? {
        var components = URLComponents(string: OpenMeteoConfig.forecastURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: OpenMeteoConfig.currentParameters),
            URLQueryItem(name: "hourly", value: OpenMeteoConfig.hourlyParameters),
            URLQueryItem(name: "daily", value: OpenMeteoConfig.dailyParameters),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "14")
        ]
        
        guard let url = components?.url else { return nil }
        
        do {
            let (data, response) = try await OpenMeteoConfig.cachedSession.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }
            return try OpenMeteoConfig.decoder.decode(WeatherData.self, from: data)
        } catch {
            Logger.weatherService.warning("Static fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Historical Weather
    
    /// Fetch historical weather data for a specific date range
    /// Uses Open-Meteo Historical Weather API (free, no API key required)
    static func fetchHistoricalWeather(
        latitude: Double,
        longitude: Double,
        startDate: Date,
        endDate: Date
    ) async throws -> HistoricalWeatherData {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        var components = URLComponents(string: OpenMeteoConfig.historicalURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "start_date", value: dateFormatter.string(from: startDate)),
            URLQueryItem(name: "end_date", value: dateFormatter.string(from: endDate)),
            URLQueryItem(name: "daily", value: OpenMeteoConfig.historicalDailyParameters),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }
        
        let (data, response) = try await OpenMeteoConfig.cachedSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try OpenMeteoConfig.decoder.decode(HistoricalWeatherData.self, from: data)
    }
    
    // MARK: - Pollen Forecast
    
    /// Fetch pollen forecast data from Open-Meteo Air Quality API
    /// Note: Pollen data is only available for Europe
    static func fetchPollenForecast(
        latitude: Double,
        longitude: Double
    ) async throws -> PollenData {
        var components = URLComponents(string: OpenMeteoConfig.airQualityURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "hourly", value: OpenMeteoConfig.pollenParameters),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        
        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }
        
        let (data, response) = try await OpenMeteoConfig.cachedSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try OpenMeteoConfig.decoder.decode(PollenData.self, from: data)
    }
}

