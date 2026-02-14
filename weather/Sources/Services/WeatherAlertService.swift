//
//  WeatherAlertService.swift
//  weather
//
//  Created by GitHub Copilot on 2/14/26.
//
//  Fetches severe weather alerts from NWS (US) and MeteoAlarm (Europe)
//

import Foundation
import CoreLocation
import OSLog

// MARK: - Weather Alert Service

@Observable
class WeatherAlertService {
    var activeAlerts: [WeatherAlert] = []
    var isLoading = false
    var lastUpdateTime: Date?
    
    private let nwsBaseURL = "https://api.weather.gov"
    private let meteoAlarmBaseURL = "https://api.meteoalarm.org"
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "weather", category: "WeatherAlerts")
    
    // MARK: - Fetch Alerts
    
    /// Fetch severe weather alerts for the given location
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    /// - Returns: Array of weather alerts
    func fetchAlerts(latitude: Double, longitude: Double) async -> [WeatherAlert] {
        isLoading = true
        defer { isLoading = false }
        
        var alerts: [WeatherAlert] = []
        
        // Determine which API to use based on location
        if isUSLocation(latitude: latitude, longitude: longitude) {
            alerts = await fetchNWSAlerts(latitude: latitude, longitude: longitude)
        } else if isEuropeanLocation(latitude: latitude, longitude: longitude) {
            alerts = await fetchMeteoAlarmAlerts(latitude: latitude, longitude: longitude)
        }
        
        activeAlerts = alerts
        lastUpdateTime = Date()
        
        return alerts
    }
    
    // MARK: - NWS API (United States)
    
    private func fetchNWSAlerts(latitude: Double, longitude: Double) async -> [WeatherAlert] {
        // NWS requires a User-Agent header
        let userAgent = "WeatherApp/2.3.0 (github.com/and3rn3t/weather-app)"
        
        // First, get the grid point for this location
        guard let gridPointURL = URL(string: "\(nwsBaseURL)/points/\(latitude),\(longitude)") else {
            Self.logger.error("Invalid NWS points URL")
            return []
        }
        
        var request = URLRequest(url: gridPointURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Self.logger.error("Invalid response from NWS points API")
                return []
            }
            
            guard httpResponse.statusCode == 200 else {
                Self.logger.error("NWS points API returned status \(httpResponse.statusCode)")
                return []
            }
            
            let pointsResponse = try JSONDecoder().decode(NWSPointsResponse.self, from: data)
            
            // Get the forecast zone for alerts
            return await fetchNWSAlertsByZone(zoneURL: pointsResponse.properties.forecastZone, userAgent: userAgent)
            
        } catch {
            Self.logger.error("Failed to fetch NWS grid point: \(error.localizedDescription)")
            // Fallback to active alerts by point
            return await fetchNWSAlertsByPoint(latitude: latitude, longitude: longitude, userAgent: userAgent)
        }
    }
    
    private func fetchNWSAlertsByPoint(latitude: Double, longitude: Double, userAgent: String) async -> [WeatherAlert] {
        // Fetch active alerts for this point
        guard let alertsURL = URL(string: "\(nwsBaseURL)/alerts/active?point=\(latitude),\(longitude)") else {
            Self.logger.error("Invalid NWS alerts URL")
            return []
        }
        
        var request = URLRequest(url: alertsURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Self.logger.error("Invalid response from NWS alerts API")
                return []
            }
            
            guard httpResponse.statusCode == 200 else {
                Self.logger.error("NWS alerts API returned status \(httpResponse.statusCode)")
                return []
            }
            
            let alertsResponse = try JSONDecoder().decode(NWSAlertsResponse.self, from: data)
            return alertsResponse.features.map { $0.toWeatherAlert() }
            
        } catch {
            Self.logger.error("Failed to fetch NWS alerts: \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchNWSAlertsByZone(zoneURL: String, userAgent: String) async -> [WeatherAlert] {
        // Extract zone ID from URL
        guard let zoneId = zoneURL.split(separator: "/").last else {
            return []
        }
        
        guard let alertsURL = URL(string: "\(nwsBaseURL)/alerts/active/zone/\(zoneId)") else {
            Self.logger.error("Invalid NWS zone alerts URL")
            return []
        }
        
        var request = URLRequest(url: alertsURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }
            
            let alertsResponse = try JSONDecoder().decode(NWSAlertsResponse.self, from: data)
            return alertsResponse.features.map { $0.toWeatherAlert() }
            
        } catch {
            Self.logger.error("Failed to fetch NWS zone alerts: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - MeteoAlarm API (Europe)
    
    private func fetchMeteoAlarmAlerts(latitude: Double, longitude: Double) async -> [WeatherAlert] {
        // MeteoAlarm uses CAP (Common Alerting Protocol)
        // Note: MeteoAlarm API requires country code, which we'd need to geocode
        // For now, return empty array - full implementation would require geocoding service
        Self.logger.info("MeteoAlarm integration requires geocoding - not yet implemented")
        return []
    }
    
    // MARK: - Location Detection
    
    private func isUSLocation(latitude: Double, longitude: Double) -> Bool {
        // Approximate bounding box for US territories
        // Continental US: lat 24.5-49.4, lon -125 to -66
        // Alaska: lat 51-71, lon -179 to -129
        // Hawaii: lat 18-29, lon -178 to -154
        // Puerto Rico & territories: lat 17-19, lon -68 to -64
        
        let isContiguousUS = latitude >= 24.5 && latitude <= 49.4 && longitude >= -125 && longitude <= -66
        let isAlaska = latitude >= 51 && latitude <= 71 && longitude >= -179 && longitude <= -129
        let isHawaii = latitude >= 18 && latitude <= 29 && longitude >= -178 && longitude <= -154
        let isPuertoRico = latitude >= 17 && latitude <= 19 && longitude >= -68 && longitude <= -64
        
        return isContiguousUS || isAlaska || isHawaii || isPuertoRico
    }
    
    private func isEuropeanLocation(latitude: Double, longitude: Double) -> Bool {
        // Approximate bounding box for Europe
        // lat 35-71, lon -10 to 40
        return latitude >= 35 && latitude <= 71 && longitude >= -10 && longitude <= 40
    }
}

// MARK: - NWS API Models

struct NWSPointsResponse: Codable {
    let properties: NWSPointsProperties
}

struct NWSPointsProperties: Codable {
    let forecastZone: String
    let county: String
    
    enum CodingKeys: String, CodingKey {
        case forecastZone, county
    }
}

struct NWSAlertsResponse: Codable {
    let features: [NWSAlertFeature]
}

struct NWSAlertFeature: Codable {
    let properties: NWSAlertProperties
    
    func toWeatherAlert() -> WeatherAlert {
        let dateFormatter = ISO8601DateFormatter()
        
        let effective = dateFormatter.date(from: properties.effective) ?? Date()
        let expires = dateFormatter.date(from: properties.expires) ?? Date().addingTimeInterval(3600)
        
        return WeatherAlert(
            event: properties.event,
            headline: properties.headline ?? properties.event,
            description: properties.description ?? "",
            severity: properties.severity,
            urgency: properties.urgency,
            areas: properties.areaDesc,
            effective: effective,
            expires: expires,
            senderName: properties.senderName
        )
    }
}

struct NWSAlertProperties: Codable {
    let event: String
    let headline: String?
    let description: String?
    let severity: String
    let urgency: String
    let areaDesc: String
    let effective: String
    let expires: String
    let senderName: String
    
    enum CodingKeys: String, CodingKey {
        case event, headline, description, severity, urgency
        case areaDesc, effective, expires, senderName
    }
}

// MARK: - Alert Severity Extension

extension WeatherAlert {
    /// Visual priority for sorting and display
    var priority: Int {
        switch severity.lowercased() {
        case "extreme": return 5
        case "severe": return 4
        case "moderate": return 3
        case "minor": return 2
        default: return 1
        }
    }
    
    /// Color coding for alerts
    var alertColor: String {
        switch severity.lowercased() {
        case "extreme": return "red"
        case "severe": return "orange"
        case "moderate": return "yellow"
        default: return "blue"
        }
    }
    
    /// Icon for alert type
    var icon: String {
        let eventLower = event.lowercased()
        
        if eventLower.contains("tornado") {
            return "tornado"
        } else if eventLower.contains("hurricane") || eventLower.contains("typhoon") {
            return "hurricane"
        } else if eventLower.contains("flood") {
            return "water.waves"
        } else if eventLower.contains("fire") {
            return "flame"
        } else if eventLower.contains("winter") || eventLower.contains("snow") || eventLower.contains("ice") {
            return "snowflake"
        } else if eventLower.contains("heat") {
            return "thermometer.sun"
        } else if eventLower.contains("wind") {
            return "wind"
        } else if eventLower.contains("thunder") || eventLower.contains("lightning") {
            return "cloud.bolt"
        } else {
            return "exclamationmark.triangle"
        }
    }
    
    /// Whether this alert has expired
    var isExpired: Bool {
        expires < Date()
    }
    
    /// Whether this alert is currently active
    var isActive: Bool {
        effective <= Date() && expires > Date()
    }
}
