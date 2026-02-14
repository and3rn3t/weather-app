//
//  TomorrowIOService.swift
//  weather
//
//  Service for fetching pollen data from Tomorrow.io API
//

import Foundation

// MARK: - Tomorrow.io Service

enum TomorrowIOService {
    
    /// Fetch pollen forecast data from Tomorrow.io API
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    ///   - apiKey: Tomorrow.io API key
    /// - Returns: TomorrowIOPollenData containing forecast
    static func fetchPollenForecast(
        latitude: Double,
        longitude: Double,
        apiKey: String
    ) async throws -> TomorrowIOPollenData {
        // Build request URL
        var components = URLComponents(string: TomorrowIOConfig.timelineURL)
        components?.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "fields", value: TomorrowIOConfig.pollenFields.joined(separator: ",")),
            URLQueryItem(name: "timesteps", value: "1d"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }
        
        #if DEBUG
        print("🌸 Tomorrow.io Pollen Request: \(url.absoluteString)")
        #endif
        
        // Make request
        let (data, response) = try await TomorrowIOConfig.session.data(from: url)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        
        #if DEBUG
        print("🌸 Tomorrow.io Response Status: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("🌸 Error Response: \(errorString)")
            }
        }
        #endif
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw WeatherError.apiUnavailable // Invalid API key
        case 429:
            throw WeatherError.rateLimited
        default:
            // Include error details in the error
            if let errorString = String(data: data, encoding: .utf8) {
                throw WeatherError.decodingError("Tomorrow.io API error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw WeatherError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Decode response
        do {
            return try TomorrowIOConfig.decoder.decode(TomorrowIOPollenData.self, from: data)
        } catch {
            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🌸 Failed to decode JSON: \(jsonString)")
            }
            #endif
            throw WeatherError.decodingError("Failed to decode Tomorrow.io pollen data: \(error.localizedDescription)")
        }
    }
}
