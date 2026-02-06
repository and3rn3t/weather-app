//
//  WeatherError.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import Foundation

// MARK: - Weather Error Types

/// Comprehensive error types for weather operations
enum WeatherError: LocalizedError, Equatable {
    // Network Errors
    case noInternet
    case timeout
    case serverError(statusCode: Int)
    case invalidResponse
    
    // Data Errors
    case invalidURL
    case decodingError(String)
    case noData
    
    // Location Errors
    case locationAccessDenied
    case locationUnavailable
    case geocodingFailed
    
    // API Errors
    case rateLimited
    case apiUnavailable
    
    // Generic
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No Internet Connection"
        case .timeout:
            return "Request Timed Out"
        case .serverError(let statusCode):
            return "Server Error (\(statusCode))"
        case .invalidResponse:
            return "Invalid Response"
        case .invalidURL:
            return "Invalid Request"
        case .decodingError:
            return "Data Error"
        case .noData:
            return "No Data Available"
        case .locationAccessDenied:
            return "Location Access Denied"
        case .locationUnavailable:
            return "Location Unavailable"
        case .geocodingFailed:
            return "Location Not Found"
        case .rateLimited:
            return "Too Many Requests"
        case .apiUnavailable:
            return "Service Unavailable"
        case .unknown:
            return "Something Went Wrong"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternet:
            return "Check your internet connection and try again."
        case .timeout:
            return "The server took too long to respond. Please try again."
        case .serverError:
            return "The weather service is experiencing issues. Please try again later."
        case .invalidResponse:
            return "We received unexpected data. Please try again."
        case .invalidURL:
            return "There was a problem with the request. Please try again."
        case .decodingError:
            return "We couldn't read the weather data. Please try again."
        case .noData:
            return "No weather data is available for this location."
        case .locationAccessDenied:
            return "Please enable location access in Settings to get weather for your current location."
        case .locationUnavailable:
            return "We couldn't determine your location. Please try again or search for a city."
        case .geocodingFailed:
            return "We couldn't find that location. Please try a different search."
        case .rateLimited:
            return "Please wait a moment before trying again."
        case .apiUnavailable:
            return "The weather service is temporarily unavailable. Please try again later."
        case .unknown(let message):
            return message.isEmpty ? "Please try again." : message
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .noInternet, .timeout, .serverError, .rateLimited, .apiUnavailable:
            return true
        case .invalidURL, .decodingError, .noData, .invalidResponse,
             .locationAccessDenied, .locationUnavailable, .geocodingFailed, .unknown:
            return false
        }
    }
    
    var systemImage: String {
        switch self {
        case .noInternet:
            return "wifi.slash"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .serverError, .apiUnavailable:
            return "server.rack"
        case .invalidResponse, .decodingError, .noData:
            return "exclamationmark.triangle"
        case .invalidURL:
            return "link.badge.plus"
        case .locationAccessDenied:
            return "location.slash"
        case .locationUnavailable, .geocodingFailed:
            return "location.magnifyingglass"
        case .rateLimited:
            return "hourglass"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    /// Convert from URLError
    static func from(_ urlError: URLError) -> WeatherError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternet
        case .timedOut:
            return .timeout
        case .badURL:
            return .invalidURL
        case .cannotDecodeContentData, .cannotDecodeRawData:
            return .decodingError("Cannot decode data")
        case .badServerResponse:
            return .serverError(statusCode: 0)
        default:
            return .unknown(urlError.localizedDescription)
        }
    }
    
    /// Convert from HTTP status code
    static func from(statusCode: Int) -> WeatherError? {
        switch statusCode {
        case 200...299:
            return nil // Success
        case 400:
            return .invalidURL
        case 429:
            return .rateLimited
        case 500...599:
            return .serverError(statusCode: statusCode)
        case 503:
            return .apiUnavailable
        default:
            return .serverError(statusCode: statusCode)
        }
    }
}

// MARK: - Result Type Alias

typealias WeatherResult<T> = Result<T, WeatherError>

// MARK: - Retry Configuration

struct RetryConfiguration: Sendable {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double
    
    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )
    
    static let aggressive = RetryConfiguration(
        maxAttempts: 5,
        initialDelay: 0.5,
        maxDelay: 15.0,
        multiplier: 1.5
    )
    
    nonisolated func delay(for attempt: Int) -> TimeInterval {
        let delay = initialDelay * pow(multiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

// MARK: - Retry Helper

actor RetryHandler {
    func execute<T>(
        config: RetryConfiguration = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...config.maxAttempts {
            do {
                return try await operation()
            } catch let error as WeatherError {
                lastError = error
                
                guard error.isRetryable && attempt < config.maxAttempts else {
                    throw error
                }
                
                let delay = config.delay(for: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                lastError = error
                
                if attempt >= config.maxAttempts {
                    throw error
                }
                
                let delay = config.delay(for: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? WeatherError.unknown("Maximum retry attempts exceeded")
    }
}
