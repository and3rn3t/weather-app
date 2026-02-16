//
//  RequestCoalescer.swift
//  weather
//
//  Request coalescing manager to batch API calls and reduce server load
//

import Foundation
import OSLog

/**
 * Request coalescer that batches multiple API requests within a time window
 * Reduces server load and improves performance by combining similar requests
 */
actor RequestCoalescer {
    static let shared = RequestCoalescer()
    
    // MARK: - Configuration
    
    private struct Config {
        static let coalescingWindow: TimeInterval = 2.0 // 2 second window
        static let maxBatchSize = 5 // Maximum requests per batch
        static let locationTolerance = 0.05 // ~5.5km tolerance for location grouping
    }
    
    // MARK: - Types
    
    typealias WeatherRequest = (latitude: Double, longitude: Double, completion: @Sendable (Result<WeatherData, Error>) -> Void)
    typealias AirQualityRequest = (latitude: Double, longitude: Double, completion: @Sendable (Result<AirQualityData, Error>) -> Void)
    typealias AlertsRequest = (latitude: Double, longitude: Double, completion: @Sendable (Result<[WeatherAlert], Error>) -> Void)
    
    // MARK: - Pending Requests
    
    private var pendingWeatherRequests: [WeatherRequest] = []
    private var pendingAirQualityRequests: [AirQualityRequest] = []
    private var pendingAlertsRequests: [AlertsRequest] = []
    
    // MARK: - Batch Tasks
    
    private var weatherBatchTask: Task<Void, Never>?
    private var airQualityBatchTask: Task<Void, Never>?
    private var alertsBatchTask: Task<Void, Never>?
    
    // MARK: - Logger
    
    private let logger = Logger(subsystem: "WeatherApp.Networking", category: "RequestCoalescer")
    
    private init() {}
    
    // MARK: - Weather Request Coalescing
    
    func coalesceWeatherRequest(
        latitude: Double,
        longitude: Double,
        completion: @escaping @Sendable (Result<WeatherData, Error>) -> Void
    ) {
        // Check if we have a very similar pending request (within tolerance)
        if let existingIndex = pendingWeatherRequests.firstIndex(where: { request in
            abs(request.latitude - latitude) < Config.locationTolerance &&
            abs(request.longitude - longitude) < Config.locationTolerance
        }) {
            // Combine with existing request
            let existingRequest = pendingWeatherRequests[existingIndex]
            let existingCompletion = existingRequest.completion
            let newCompletion = completion
            let combinedCompletion: @Sendable (Result<WeatherData, Error>) -> Void = { result in
                existingCompletion(result)
                newCompletion(result)
            }
            pendingWeatherRequests[existingIndex] = (
                latitude: (existingRequest.latitude + latitude) / 2, // Average location
                longitude: (existingRequest.longitude + longitude) / 2,
                completion: combinedCompletion
            )
            logger.debug("Coalesced weather request for nearby location")
            return
        }
        
        // Add new request to batch
        pendingWeatherRequests.append((latitude, longitude, completion))
        logger.debug("Added weather request to batch (\\(pendingWeatherRequests.count)/\\(Config.maxBatchSize))")
        
        // Process batch if we hit the limit or start timer for time-based processing
        if pendingWeatherRequests.count >= Config.maxBatchSize {
            Task { await processWeatherBatch() }
        } else if weatherBatchTask == nil {
            startWeatherBatchTimer()
        }
    }
    
    private func startWeatherBatchTimer() {
        weatherBatchTask = Task {
            try? await Task.sleep(for: .seconds(Config.coalescingWindow))
            await processWeatherBatch()
        }
    }
    
    private func processWeatherBatch() {
        guard !pendingWeatherRequests.isEmpty else { return }
        
        let requests = pendingWeatherRequests
        pendingWeatherRequests.removeAll()
        weatherBatchTask?.cancel()
        weatherBatchTask = nil
        
        logger.info("Processing weather batch with \\(requests.count) requests")
        
        // Group requests by location clusters
        let clusters = clusterWeatherRequests(requests)
        
        // Process each cluster
        for cluster in clusters {
            Task {
                await self.executeWeatherCluster(cluster)
            }
        }
    }
    
    private func clusterWeatherRequests(_ requests: [WeatherRequest]) -> [[WeatherRequest]] {
        var clusters: [[WeatherRequest]] = []
        var remaining = requests
        
        while !remaining.isEmpty {
            let seed = remaining.removeFirst()
            var cluster = [seed]
            
            // Find requests within tolerance of seed
            remaining.removeAll { request in
                if abs(request.latitude - seed.latitude) < Config.locationTolerance &&
                   abs(request.longitude - seed.longitude) < Config.locationTolerance {
                    cluster.append(request)
                    return true
                }
                return false
            }
            
            clusters.append(cluster)
        }
        
        return clusters
    }
    
    private func executeWeatherCluster(_ cluster: [WeatherRequest]) async {
        // Use the centroid of the cluster for the API call
        let avgLatitude = cluster.map(\.latitude).reduce(0, +) / Double(cluster.count)
        let avgLongitude = cluster.map(\.longitude).reduce(0, +) / Double(cluster.count)
        
        logger.debug("Executing clustered weather request at (\\(avgLatitude), \\(avgLongitude)) for \\(cluster.count) requests")
        
        do {
            // Make the actual API call (using existing weather service logic)
            let weather = try await performWeatherAPICall(latitude: avgLatitude, longitude: avgLongitude)
            
            // Notify all requests in cluster
            for request in cluster {
                request.completion(.success(weather))
            }
        } catch {
            // Notify all requests of failure
            for request in cluster {
                request.completion(.failure(error))
            }
        }
    }
    
    // MARK: - Air Quality Request Coalescing
    
    func coalesceAirQualityRequest(
        latitude: Double,
        longitude: Double,
        completion: @escaping @Sendable (Result<AirQualityData, Error>) -> Void
    ) {
        // Similar implementation to weather coalescing
        if let existingIndex = pendingAirQualityRequests.firstIndex(where: { request in
            abs(request.latitude - latitude) < Config.locationTolerance &&
            abs(request.longitude - longitude) < Config.locationTolerance
        }) {
            let existingRequest = pendingAirQualityRequests[existingIndex]
            let existingCompletion = existingRequest.completion
            let newCompletion = completion
            let combinedCompletion: @Sendable (Result<AirQualityData, Error>) -> Void = { result in
                existingCompletion(result)
                newCompletion(result)
            }
            pendingAirQualityRequests[existingIndex] = (
                latitude: (existingRequest.latitude + latitude) / 2,
                longitude: (existingRequest.longitude + longitude) / 2,
                completion: combinedCompletion
            )
            return
        }
        
        pendingAirQualityRequests.append((latitude, longitude, completion))
        
        if pendingAirQualityRequests.count >= Config.maxBatchSize {
            Task { await processAirQualityBatch() }
        } else if airQualityBatchTask == nil {
            startAirQualityBatchTimer()
        }
    }
    
    private func startAirQualityBatchTimer() {
        airQualityBatchTask = Task {
            try? await Task.sleep(for: .seconds(Config.coalescingWindow))
            await processAirQualityBatch()
        }
    }
    
    private func processAirQualityBatch() {
        guard !pendingAirQualityRequests.isEmpty else { return }
        
        let requests = pendingAirQualityRequests
        pendingAirQualityRequests.removeAll()
        airQualityBatchTask?.cancel()
        airQualityBatchTask = nil
        
        logger.info("Processing air quality batch with \\(requests.count) requests")
        
        // Process each request (air quality API doesn't support bulk requests)
        for request in requests {
            Task {
                await self.executeAirQualityRequest(request)
            }
        }
    }
    
    private func executeAirQualityRequest(_ request: AirQualityRequest) async {
        do {
            let airQuality = try await performAirQualityAPICall(latitude: request.latitude, longitude: request.longitude)
            request.completion(.success(airQuality))
        } catch {
            request.completion(.failure(error))
        }
    }
    
    // MARK: - Weather Alerts Request Coalescing
    
    func coalesceAlertsRequest(
        latitude: Double,
        longitude: Double,
        completion: @escaping @Sendable (Result<[WeatherAlert], Error>) -> Void
    ) {
        // Weather alerts are regional, so we can be more aggressive with coalescing
        let regionTolerance = 0.1 // ~11km tolerance for alerts
        
        if let existingIndex = pendingAlertsRequests.firstIndex(where: { request in
            abs(request.latitude - latitude) < regionTolerance &&
            abs(request.longitude - longitude) < regionTolerance
        }) {
            let existingRequest = pendingAlertsRequests[existingIndex]
            let existingCompletion = existingRequest.completion
            let newCompletion = completion
            let combinedCompletion: @Sendable (Result<[WeatherAlert], Error>) -> Void = { result in
                existingCompletion(result)
                newCompletion(result)
            }
            pendingAlertsRequests[existingIndex] = (
                latitude: (existingRequest.latitude + latitude) / 2,
                longitude: (existingRequest.longitude + longitude) / 2,
                completion: combinedCompletion
            )
            logger.debug("Coalesced weather alerts request for nearby region")
            return
        }
        
        pendingAlertsRequests.append((latitude, longitude, completion))
        
        if pendingAlertsRequests.count >= Config.maxBatchSize {
            Task { await processAlertsBatch() }
        } else if alertsBatchTask == nil {
            startAlertsBatchTimer()
        }
    }
    
    private func startAlertsBatchTimer() {
        alertsBatchTask = Task {
            try? await Task.sleep(for: .seconds(Config.coalescingWindow))
            await processAlertsBatch()
        }
    }
    
    private func processAlertsBatch() {
        guard !pendingAlertsRequests.isEmpty else { return }
        
        let requests = pendingAlertsRequests
        pendingAlertsRequests.removeAll()
        alertsBatchTask?.cancel()
        alertsBatchTask = nil
        
        logger.info("Processing weather alerts batch with \\(requests.count) requests")
        
        for request in requests {
            Task {
                await self.executeAlertsRequest(request)
            }
        }
    }
    
    private func executeAlertsRequest(_ request: AlertsRequest) async {
        do {
            let alerts = try await performAlertsAPICall(latitude: request.latitude, longitude: request.longitude)
            request.completion(.success(alerts))
        } catch {
            request.completion(.failure(error))
        }
    }
    
    // MARK: - API Call Methods (to be implemented by WeatherService)
    
    private nonisolated func performWeatherAPICall(latitude: Double, longitude: Double) async throws -> WeatherData {
        // This would use the existing weather service logic
        // For now, we'll call the existing method
        
        let forecastURL = await MainActor.run { OpenMeteoConfig.forecastURL }
        let currentParams = await MainActor.run { OpenMeteoConfig.currentParameters }
        let hourlyParams = await MainActor.run { OpenMeteoConfig.hourlyParameters }
        let dailyParams = await MainActor.run { OpenMeteoConfig.dailyParameters }
        
        var components = URLComponents(string: forecastURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: currentParams),
            URLQueryItem(name: "hourly", value: hourlyParams),
            URLQueryItem(name: "daily", value: dailyParams),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "14")
        ]
        
        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }
        
        let cachedSession = await MainActor.run { OpenMeteoConfig.cachedSession }
        let (data, response) = try await cachedSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        
        if let error = WeatherError.from(statusCode: httpResponse.statusCode) {
            throw error
        }
        
        let decoder = await MainActor.run { OpenMeteoConfig.decoder }
        return try await MainActor.run {
            try decoder.decode(WeatherData.self, from: data)
        }
    }
    
    private func performAirQualityAPICall(latitude: Double, longitude: Double) async throws -> AirQualityData {
        // Implementation would be similar to existing air quality fetching logic
        // Placeholder for now
        throw WeatherError.unknown("Air quality coalescing not yet implemented")
    }
    
    private func performAlertsAPICall(latitude: Double, longitude: Double) async throws -> [WeatherAlert] {
        // Implementation would be similar to existing alerts fetching logic
        // Placeholder for now
        throw WeatherError.unknown("Weather alerts coalescing not yet implemented")
    }
    
    // MARK: - Statistics and Debugging
    
    func getStatistics() -> CoalescingStatistics {
        return CoalescingStatistics(
            pendingWeatherRequests: pendingWeatherRequests.count,
            pendingAirQualityRequests: pendingAirQualityRequests.count,
            pendingAlertsRequests: pendingAlertsRequests.count,
            hasActiveWeatherTimer: weatherBatchTask != nil,
            hasActiveAirQualityTimer: airQualityBatchTask != nil,
            hasActiveAlertsTimer: alertsBatchTask != nil
        )
    }
    
    struct CoalescingStatistics {
        let pendingWeatherRequests: Int
        let pendingAirQualityRequests: Int
        let pendingAlertsRequests: Int
        let hasActiveWeatherTimer: Bool
        let hasActiveAirQualityTimer: Bool
        let hasActiveAlertsTimer: Bool
    }
}