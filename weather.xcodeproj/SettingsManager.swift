//
//  SettingsManager.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import Foundation
import SwiftUI

// MARK: - Simple Settings Manager

@Observable
final class SimpleSettingsManager {
    // Unit Preferences
    var useCelsius: Bool {
        didSet { UserDefaults.standard.set(useCelsius, forKey: "useCelsius") }
    }
    
    var showAnimatedBackgrounds: Bool {
        didSet { UserDefaults.standard.set(showAnimatedBackgrounds, forKey: "showAnimatedBackgrounds") }
    }
    
    var showWeatherParticles: Bool {
        didSet { UserDefaults.standard.set(showWeatherParticles, forKey: "showWeatherParticles") }
    }
    
    var showFeelsLike: Bool {
        didSet { UserDefaults.standard.set(showFeelsLike, forKey: "showFeelsLike") }
    }
    
    init() {
        self.useCelsius = UserDefaults.standard.object(forKey: "useCelsius") as? Bool ?? false
        self.showAnimatedBackgrounds = UserDefaults.standard.object(forKey: "showAnimatedBackgrounds") as? Bool ?? true
        self.showWeatherParticles = UserDefaults.standard.object(forKey: "showWeatherParticles") as? Bool ?? true
        self.showFeelsLike = UserDefaults.standard.object(forKey: "showFeelsLike") as? Bool ?? true
    }
    
    // MARK: - Formatting Helpers
    
    func formatTemperature(_ fahrenheit: Double) -> String {
        if useCelsius {
            let celsius = (fahrenheit - 32) * 5 / 9
            return "\(Int(celsius))°C"
        } else {
            return "\(Int(fahrenheit))°F"
        }
    }
    
    func formatWindSpeed(_ mph: Double) -> String {
        return "\(Int(mph)) mph"
    }
    
    func formatPrecipitation(_ inches: Double) -> String {
        return String(format: "%.2f in", inches)
    }
}

// MARK: - Legacy Types (for compatibility)

enum TemperatureUnit: String, CaseIterable, Codable {
    case fahrenheit = "Fahrenheit (°F)"
    case celsius = "Celsius (°C)"
    
    var apiValue: String {
        switch self {
        case .fahrenheit:
            return "fahrenheit"
        case .celsius:
            return "°C"
        }
    }
}

// MARK: - Wind Speed Unit

enum WindSpeedUnit: String, CaseIterable, Codable {
    case mph = "Miles per hour (mph)"
    case kmh = "Kilometers per hour (km/h)"
    case ms = "Meters per second (m/s)"
    case knots = "Knots"
    
    var apiValue: String {
        switch self {
        case .mph:
            return "mph"
        case .kmh:
            return "kmh"
        case .ms:
            return "ms"
        case .knots:
            return "kn"
        }
    }
    
    var symbol: String {
        switch self {
        case .mph:
            return "mph"
        case .kmh:
            return "km/h"
        case .ms:
            return "m/s"
        case .knots:
            return "kts"
        }
    }
}

// MARK: - Precipitation Unit

enum PrecipitationUnit: String, CaseIterable, Codable {
    case inches = "Inches"
    case millimeters = "Millimeters"
    
    var apiValue: String {
        switch self {
        case .inches:
            return "inch"
        case .millimeters:
            return "mm"
        }
    }
    
    var symbol: String {
        switch self {
        case .inches:
            return "in"
        case .millimeters:
            return "mm"
        }
    }
}

// MARK: - Settings Manager

@Observable
class SettingsManager {
    // Units
    var temperatureUnit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(try? JSONEncoder().encode(temperatureUnit), forKey: "temperatureUnit")
        }
    }
    
    var windSpeedUnit: WindSpeedUnit {
        didSet {
            UserDefaults.standard.set(try? JSONEncoder().encode(windSpeedUnit), forKey: "windSpeedUnit")
        }
    }
    
    var precipitationUnit: PrecipitationUnit {
        didSet {
            UserDefaults.standard.set(try? JSONEncoder().encode(precipitationUnit), forKey: "precipitationUnit")
        }
    }
    
    // Appearance
    var useSystemAppearance: Bool {
        didSet {
            UserDefaults.standard.set(useSystemAppearance, forKey: "useSystemAppearance")
        }
    }
    
    var preferredColorScheme: ColorScheme? {
        didSet {
            if let scheme = preferredColorScheme {
                UserDefaults.standard.set(scheme == .dark ? "dark" : "light", forKey: "preferredColorScheme")
            } else {
                UserDefaults.standard.removeObject(forKey: "preferredColorScheme")
            }
        }
    }
    
    // Notifications
    var dailyForecastEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyForecastEnabled, forKey: "dailyForecastEnabled")
        }
    }
    
    var severeWeatherAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(severeWeatherAlertsEnabled, forKey: "severeWeatherAlertsEnabled")
        }
    }
    
    var rainAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(rainAlertsEnabled, forKey: "rainAlertsEnabled")
        }
    }
    
    var notificationTime: Date {
        didSet {
            UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
        }
    }
    
    // Display Options
    var showFeelsLike: Bool {
        didSet {
            UserDefaults.standard.set(showFeelsLike, forKey: "showFeelsLike")
        }
    }
    
    var show24HourFormat: Bool {
        didSet {
            UserDefaults.standard.set(show24HourFormat, forKey: "show24HourFormat")
        }
    }
    
    var showAnimatedBackgrounds: Bool {
        didSet {
            UserDefaults.standard.set(showAnimatedBackgrounds, forKey: "showAnimatedBackgrounds")
        }
    }
    
    var showWeatherParticles: Bool {
        didSet {
            UserDefaults.standard.set(showWeatherParticles, forKey: "showWeatherParticles")
        }
    }
    
    // Data
    var autoRefreshInterval: Int {
        didSet {
            UserDefaults.standard.set(autoRefreshInterval, forKey: "autoRefreshInterval")
        }
    }
    
    init() {
        // Load temperature unit
        if let data = UserDefaults.standard.data(forKey: "temperatureUnit"),
           let unit = try? JSONDecoder().decode(TemperatureUnit.self, from: data) {
            self.temperatureUnit = unit
        } else {
            self.temperatureUnit = .fahrenheit
        }
        
        // Load wind speed unit
        if let data = UserDefaults.standard.data(forKey: "windSpeedUnit"),
           let unit = try? JSONDecoder().decode(WindSpeedUnit.self, from: data) {
            self.windSpeedUnit = unit
        } else {
            self.windSpeedUnit = .mph
        }
        
        // Load precipitation unit
        if let data = UserDefaults.standard.data(forKey: "precipitationUnit"),
           let unit = try? JSONDecoder().decode(PrecipitationUnit.self, from: data) {
            self.precipitationUnit = unit
        } else {
            self.precipitationUnit = .inches
        }
        
        // Load appearance settings
        self.useSystemAppearance = UserDefaults.standard.object(forKey: "useSystemAppearance") as? Bool ?? true
        
        if let schemeString = UserDefaults.standard.string(forKey: "preferredColorScheme") {
            self.preferredColorScheme = schemeString == "dark" ? .dark : .light
        } else {
            self.preferredColorScheme = nil
        }
        
        // Load notification settings
        self.dailyForecastEnabled = UserDefaults.standard.object(forKey: "dailyForecastEnabled") as? Bool ?? false
        self.severeWeatherAlertsEnabled = UserDefaults.standard.object(forKey: "severeWeatherAlertsEnabled") as? Bool ?? true
        self.rainAlertsEnabled = UserDefaults.standard.object(forKey: "rainAlertsEnabled") as? Bool ?? false
        
        if let time = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
            self.notificationTime = time
        } else {
            // Default to 8:00 AM
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            self.notificationTime = Calendar.current.date(from: components) ?? Date()
        }
        
        // Load display options
        self.showFeelsLike = UserDefaults.standard.object(forKey: "showFeelsLike") as? Bool ?? true
        self.show24HourFormat = UserDefaults.standard.object(forKey: "show24HourFormat") as? Bool ?? false
        self.showAnimatedBackgrounds = UserDefaults.standard.object(forKey: "showAnimatedBackgrounds") as? Bool ?? true
        self.showWeatherParticles = UserDefaults.standard.object(forKey: "showWeatherParticles") as? Bool ?? true
        
        // Load data settings
        self.autoRefreshInterval = UserDefaults.standard.object(forKey: "autoRefreshInterval") as? Int ?? 30
    }
    
    func resetToDefaults() {
        temperatureUnit = .fahrenheit
        windSpeedUnit = .mph
        precipitationUnit = .inches
        useSystemAppearance = true
        preferredColorScheme = nil
        dailyForecastEnabled = false
        severeWeatherAlertsEnabled = true
        rainAlertsEnabled = false
        showFeelsLike = true
        show24HourFormat = false
        showAnimatedBackgrounds = true
        showWeatherParticles = true
        autoRefreshInterval = 30
    }
}

// MARK: - Formatting Extensions

extension SettingsManager {
    func formatTemperature(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(formatted)\(temperatureUnit.symbol)"
    }
    
    func formatWindSpeed(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
        return "\(formatted) \(windSpeedUnit.symbol)"
    }
    
    func formatPrecipitation(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "\(formatted) \(precipitationUnit.symbol)"
    }
    
    func formatTime(_ dateString: String, timezone: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = show24HourFormat ? .short : .short
        displayFormatter.dateStyle = .none
        displayFormatter.timeZone = TimeZone(identifier: timezone)
        
        if !show24HourFormat {
            displayFormatter.dateFormat = "h:mm a"
        } else {
            displayFormatter.dateFormat = "HH:mm"
        }
        
        return displayFormatter.string(from: date)
    }
}
