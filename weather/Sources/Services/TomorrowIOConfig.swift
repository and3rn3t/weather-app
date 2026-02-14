//
//  TomorrowIOConfig.swift
//  weather
//
//  Tomorrow.io API configuration for US pollen data
//

import Foundation

// MARK: - Tomorrow.io API Configuration

enum TomorrowIOConfig {
    // MARK: - Base URLs
    
    static let baseURL = "https://api.tomorrow.io/v4"
    
    // MARK: - API Endpoints
    
    static let timelineURL = "\(baseURL)/timelines"
    
    // MARK: - Available Fields
    
    /// Pollen fields available in Tomorrow.io API
    static let pollenFields = [
        "treeIndex",      // Tree pollen index (0-5)
        "grassIndex",     // Grass pollen index (0-5)
        "weedIndex"       // Weed pollen index (0-5)
    ]
    
    // MARK: - Shared JSON Decoder
    
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Network Configuration
    
    /// Timeout for individual requests (seconds)
    static let requestTimeout: TimeInterval = 15
    /// Timeout for overall resource loading (seconds)
    static let resourceTimeout: TimeInterval = 30
    
    // MARK: - Shared URL Session
    
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = resourceTimeout
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
}
