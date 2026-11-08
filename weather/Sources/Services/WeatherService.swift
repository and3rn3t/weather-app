//
//  WeatherService.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import CoreLocation
import Foundation
import os.signpost
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

@MainActor
@Observable
class WeatherService {
    static let shared = WeatherService()
    
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

    /// Sessions used for the forecast request. Injectable so tests can stub the network.
    private let session: URLSession
    private let forceRefreshSession: URLSession
    /// When false, air quality and alerts are not fetched alongside the forecast (tests).
    private let fetchesSecondaryData: Bool

    init(
        session: URLSession = OpenMeteoConfig.cachedSession,
        forceRefreshSession: URLSession = OpenMeteoConfig.forceRefreshSession,
        fetchesSecondaryData: Bool = true
    ) {
        self.session = session
        self.forceRefreshSession = forceRefreshSession
        self.fetchesSecondaryData = fetchesSecondaryData

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
        
        os_signpost(.end, log: StartupSignpost.log, name: "WeatherService.init")
    }

        // Fire a background network refresh with last-known coordinates.
        // This runs after init returns, overlapping with SwiftUI scene setup.
        /*
        if let loc = locationMeta {
            Task.detached(priority: .userInitiated) { [self] in
                #if DEBUG
                startupLog(cached == nil ? "No cache — eager fetch" : "Eager background refresh")
                #endif
                await self.fetchWeatherData(latitude: loc.latitude, longitude: loc.longitude,
                                        locationName: loc.name, forceRefresh: true)
            }
        }
        */
    // MARK: - Constants
    
    /// Last successful fetch timestamp for debouncing
    private var lastFetchTime: Date?
    /// Coordinates of the last successful fetch; the debounce only applies to the same place.
    private var lastFetchCoordinate: (latitude: Double, longitude: Double)?
    private let minimumFetchInterval: TimeInterval = 60 // 1 minute minimum between fetches
    /// Even an explicit refresh (pull-to-refresh) is ignored this soon after a successful fetch.
    private let minimumForceRefreshInterval: TimeInterval = 10

    /// Incremented by every fetch that starts. A fetch publishes its results only while it is
    /// still the latest, so a slow response for an earlier location can't overwrite a newer one.
    private var fetchGeneration: UInt = 0
    
    /// Coordinates of the currently in-flight fetch (prevents redundant concurrent requests)
    private var activeFetchCoordinate: (latitude: Double, longitude: Double)?
    
    /// In-flight dedup tolerance: broader than FavoritesManager.coordinateTolerance (0.01°)
    /// because we're preventing redundant network requests, not matching saved locations.
    /// 0.05° ≈ 5.5 km at the equator — close enough that weather data is identical.
    static let inFlightDeduplicationTolerance = 0.05
    
    // MARK: - Public Methods
    
    func fetchWeatherData(latitude: Double, longitude: Double, locationName: String? = nil, forceRefresh: Bool = false) async {
        let traceKey = forceRefresh ? "weather_fetch_force" : "weather_fetch_normal"
        performanceTracker.startTrace(traceKey, attributes: [
            "force_refresh": String(forceRefresh),
            "has_location_name": String(locationName != nil),
            "has_cached_data": String(weatherData != nil)
        ])
        
        if let reason = skipReason(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh) {
            performanceTracker.recordEvent("weather_fetch_skipped", parameters: ["reason": reason])
            performanceTracker.stopTrace(traceKey)
            return
        }
        
        fetchGeneration &+= 1
        let generation = fetchGeneration
        activeFetchCoordinate = (latitude, longitude)
        defer {
            // A newer fetch owns the in-flight marker now; only clear our own.
            if generation == fetchGeneration {
                activeFetchCoordinate = nil
            }
            performanceTracker.stopTrace(traceKey)
        }
        
        // Only show loading spinner when there's NO data to display yet.
        // If we already have weather data visible, refresh silently in the background.
        if weatherData == nil {
            isLoading = true
        }
        errorMessage = nil
        lastError = nil
        
        do {
            // Air quality and alerts run in parallel with the forecast.
            async let airQualityTask: Void = fetchAirQualityCoalesced(latitude: latitude, longitude: longitude, generation: generation)
            async let alertsTask: Void = fetchWeatherAlertsCoalesced(latitude: latitude, longitude: longitude, generation: generation)
            let weather = try await performWeatherFetchWithRetry(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh)
            
            // A newer fetch started while we waited: this response is for a place the user left.
            guard generation == fetchGeneration else {
                await airQualityTask
                await alertsTask
                return
            }
            
            lastFetchTime = Date()
            lastFetchCoordinate = (latitude, longitude)
            
            // Name and data are published together so they always describe the same place.
            currentLocationName = locationName
            weatherData = weather
            isLoading = false
            
            performanceTracker.recordEvent("weather_fetch_success", parameters: [
                "force_refresh": String(forceRefresh),
                "has_location_name": String(locationName != nil)
            ])
            
            // Save using enhanced cache manager for better performance
            cacheManager.cacheWeather(weather, latitude: latitude, longitude: longitude)
            
            // Also save to shared storage for widgets (backward compatibility)
            SharedDataManager.shared.saveWeatherData(weather, locationName: locationName)
            
            await airQualityTask
            await alertsTask
        } catch is CancellationError {
            finishCancelledFetch(generation: generation)
        } catch let urlError as URLError where urlError.code == .cancelled {
            finishCancelledFetch(generation: generation)
        } catch let error as WeatherError {
            guard generation == fetchGeneration else { return }
            performanceTracker.recordEvent("weather_fetch_error", parameters: [
                "error_type": "WeatherError",
                "error_code": String(describing: error),
                "has_cached_fallback": String(cacheManager.getCachedWeather(latitude: latitude, longitude: longitude) != nil)
            ])
            
            // Fall back only to the cache for THIS location. Anything else would show another
            // place's forecast under this place's name.
            if let cached = cacheManager.getCachedWeather(latitude: latitude, longitude: longitude) {
                showCachedFallback(cached, locationName: locationName, message: "Showing cached data. " + (error.recoverySuggestion ?? ""))
            } else {
                await handleError(error)
            }
        } catch let urlError as URLError {
            guard generation == fetchGeneration else { return }
            if let cached = cacheManager.getCachedWeather(latitude: latitude, longitude: longitude) {
                showCachedFallback(cached, locationName: locationName, message: "Showing cached data. Check your connection.")
            } else {
                await handleError(.from(urlError))
            }
        } catch {
            guard generation == fetchGeneration else { return }
            await handleError(.unknown(error.localizedDescription))
        }
    }
    
    /// Why a fetch for this place should be skipped, or nil if it should go ahead.
    /// A different place is never skipped by the debounce.
    private func skipReason(latitude: Double, longitude: Double, forceRefresh: Bool) -> String? {
        if let lastFetch = lastFetchTime,
           let lastCoordinate = lastFetchCoordinate,
           weatherData != nil,
           Self.isNearby(lastCoordinate, latitude: latitude, longitude: longitude) {
            let interval = forceRefresh ? minimumForceRefreshInterval : minimumFetchInterval
            if Date().timeIntervalSince(lastFetch) < interval {
                return "debounce"
            }
        }
        if !forceRefresh,
           let active = activeFetchCoordinate,
           Self.isNearby(active, latitude: latitude, longitude: longitude) {
            return "duplicate_in_flight"
        }
        return nil
    }
    
    /// Whether two coordinates are close enough to share the same weather.
    private static func isNearby(_ coordinate: (latitude: Double, longitude: Double), latitude: Double, longitude: Double) -> Bool {
        abs(coordinate.latitude - latitude) < inFlightDeduplicationTolerance
            && abs(coordinate.longitude - longitude) < inFlightDeduplicationTolerance
    }
    
    private func showCachedFallback(_ cached: WeatherData, locationName: String?, message: String) {
        currentLocationName = locationName
        weatherData = cached
        isLoading = false
        errorMessage = message
    }
    
    /// A cancelled request (the user moved on, or the task was cancelled) is not an error.
    private func finishCancelledFetch(generation: UInt) {
        if generation == fetchGeneration {
            isLoading = false
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
            await fetchWeatherData(latitude: weather.latitude, longitude: weather.longitude, locationName: currentLocationName)
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
        let session = forceRefresh ? forceRefreshSession : session
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
        let message: String
        switch error {
        case .decodingError(let details):
            message = details
        default:
            message = error.recoverySuggestion ?? error.errorDescription ?? "Unknown error"
        }
        await MainActor.run {
            self.lastError = error
            self.errorMessage = message
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
    private func fetchAirQualityCoalesced(latitude: Double, longitude: Double, generation: UInt) async {
        guard fetchesSecondaryData else { return }
        await withCheckedContinuation { continuation in
            Task {
                await requestCoalescer.coalesceAirQualityRequest(
                    latitude: latitude,
                    longitude: longitude
                ) { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let airQuality):
                            guard generation == self.fetchGeneration else { break }
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
    private func fetchWeatherAlertsCoalesced(latitude: Double, longitude: Double, generation: UInt) async {
        guard fetchesSecondaryData else { return }
        await withCheckedContinuation { continuation in
            Task {
                await requestCoalescer.coalesceAlertsRequest(
                    latitude: latitude,
                    longitude: longitude
                ) { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let alerts):
                            guard generation == self.fetchGeneration else { break }
                            self.weatherAlerts = alerts.filter { !$0.isExpired }
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
}
