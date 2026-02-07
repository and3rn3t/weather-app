//
//  SettingsManager.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import Foundation
import SwiftUI

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
    
    // Live Activities
    var liveActivitiesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(liveActivitiesEnabled, forKey: "liveActivitiesEnabled")
        }
    }
    
    // Data
    var autoRefreshInterval: Int {
        didSet {
            UserDefaults.standard.set(autoRefreshInterval, forKey: "autoRefreshInterval")
        }
    }
    
    // Shared decoder for init - avoids creating 3 separate decoders
    private static let settingsDecoder = JSONDecoder()
    
    init() {
        // MARK: - Performance: Single snapshot of UserDefaults
        // Read all defaults once instead of 15+ individual lookups
        let defaults = UserDefaults.standard.dictionaryRepresentation()
        let decoder = Self.settingsDecoder
        
        // Load temperature unit
        if let data = defaults["temperatureUnit"] as? Data,
           let unit = try? decoder.decode(TemperatureUnit.self, from: data) {
            self.temperatureUnit = unit
        } else {
            self.temperatureUnit = .fahrenheit
        }
        
        // Load wind speed unit
        if let data = defaults["windSpeedUnit"] as? Data,
           let unit = try? decoder.decode(WindSpeedUnit.self, from: data) {
            self.windSpeedUnit = unit
        } else {
            self.windSpeedUnit = .mph
        }
        
        // Load precipitation unit
        if let data = defaults["precipitationUnit"] as? Data,
           let unit = try? decoder.decode(PrecipitationUnit.self, from: data) {
            self.precipitationUnit = unit
        } else {
            self.precipitationUnit = .inches
        }
        
        // Load appearance settings
        self.useSystemAppearance = defaults["useSystemAppearance"] as? Bool ?? true
        
        if let schemeString = defaults["preferredColorScheme"] as? String {
            self.preferredColorScheme = schemeString == "dark" ? .dark : .light
        } else {
            self.preferredColorScheme = nil
        }
        
        // Load notification settings
        self.dailyForecastEnabled = defaults["dailyForecastEnabled"] as? Bool ?? false
        self.severeWeatherAlertsEnabled = defaults["severeWeatherAlertsEnabled"] as? Bool ?? true
        self.rainAlertsEnabled = defaults["rainAlertsEnabled"] as? Bool ?? false
        
        if let time = defaults["notificationTime"] as? Date {
            self.notificationTime = time
        } else {
            // Default to 8:00 AM
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            self.notificationTime = Calendar.current.date(from: components) ?? Date()
        }
        
        // Load display options
        self.showFeelsLike = defaults["showFeelsLike"] as? Bool ?? true
        self.show24HourFormat = defaults["show24HourFormat"] as? Bool ?? false
        self.showAnimatedBackgrounds = defaults["showAnimatedBackgrounds"] as? Bool ?? true
        self.showWeatherParticles = defaults["showWeatherParticles"] as? Bool ?? true
        
        // Load Live Activities setting
        self.liveActivitiesEnabled = defaults["liveActivitiesEnabled"] as? Bool ?? true
        
        // Load data settings
        self.autoRefreshInterval = defaults["autoRefreshInterval"] as? Int ?? 30
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
        liveActivitiesEnabled = true
        autoRefreshInterval = 30
    }
}

// MARK: - Formatting Extensions

extension SettingsManager {
    // MARK: - Cached Formatters (Creating formatters is expensive)
    
    private static let temperatureFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private static let windSpeedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    private static let precipitationFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    // MARK: - Cached Date Formatters for Views
    
    /// ISO8601 parser for hourly time strings (no fractional seconds)
    static let isoParser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        return formatter
    }()
    
    /// ISO8601 parser for full date only
    static let isoDateOnlyParser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
    
    /// Simple date parser for "yyyy-MM-dd'T'HH:mm" format (sunrise/sunset)
    private static let simpleDateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Day name formatter (e.g., "Mon")
    static let dayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    /// Hour formatter (e.g., "3PM")
    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()
    
    /// Time formatter 12h (e.g., "7:10 AM")
    private static let time12Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    /// Time formatter 24h (e.g., "19:10")
    private static let time24Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    // MARK: - Formatting
    
    func formatTemperature(_ value: Double) -> String {
        let convertedValue: Double
        switch temperatureUnit {
        case .celsius:
            // API returns Fahrenheit, convert to Celsius
            convertedValue = (value - 32) * 5 / 9
        case .fahrenheit:
            convertedValue = value
        }
        
        let formatted = Self.temperatureFormatter.string(from: NSNumber(value: convertedValue)) ?? "\(Int(convertedValue))"
        return "\(formatted)\(temperatureUnit.symbol)"
    }
    
    /// Convert temperature value only (no symbol), for threshold comparisons
    func convertedTemperature(_ fahrenheitValue: Double) -> Double {
        switch temperatureUnit {
        case .celsius:
            return (fahrenheitValue - 32) * 5 / 9
        case .fahrenheit:
            return fahrenheitValue
        }
    }
    
    func formatWindSpeed(_ value: Double) -> String {
        // API returns mph, convert to user's preferred unit
        let convertedValue: Double
        switch windSpeedUnit {
        case .mph:
            convertedValue = value
        case .kmh:
            convertedValue = value * 1.60934
        case .ms:
            convertedValue = value * 0.44704
        case .knots:
            convertedValue = value * 0.868976
        }
        
        let formatted = Self.windSpeedFormatter.string(from: NSNumber(value: convertedValue)) ?? String(format: "%.1f", convertedValue)
        return "\(formatted) \(windSpeedUnit.symbol)"
    }
    
    /// Format wind speed value only (no symbol)
    func convertedWindSpeed(_ mphValue: Double) -> Double {
        switch windSpeedUnit {
        case .mph: return mphValue
        case .kmh: return mphValue * 1.60934
        case .ms: return mphValue * 0.44704
        case .knots: return mphValue * 0.868976
        }
    }
    
    func formatPrecipitation(_ value: Double) -> String {
        // API returns inches, convert to user's preferred unit
        let convertedValue: Double
        switch precipitationUnit {
        case .inches:
            convertedValue = value
        case .millimeters:
            convertedValue = value * 25.4
        }
        
        let formatted = Self.precipitationFormatter.string(from: NSNumber(value: convertedValue)) ?? String(format: "%.2f", convertedValue)
        return "\(formatted) \(precipitationUnit.symbol)"
    }
    
    func formatTime(_ dateString: String, timezone: String) -> String {
        guard let date = Self.isoDateFormatter.date(from: dateString) else {
            return dateString
        }
        
        // Create per-call formatter to avoid mutating shared static's timeZone (not thread-safe)
        let formatter = DateFormatter()
        formatter.dateFormat = show24HourFormat ? "HH:mm" : "h:mm a"
        formatter.timeZone = TimeZone(identifier: timezone)
        
        return formatter.string(from: date)
    }
    
    /// Format a sunrise/sunset time string ("yyyy-MM-dd'T'HH:mm" format)
    /// Note: Creates per-call formatters because timezone mutation on shared static formatters is not thread-safe
    static func formatSunTime(_ isoString: String, timezone: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm"
        parser.locale = Locale(identifier: "en_US_POSIX")
        if let timeZone = TimeZone(identifier: timezone) {
            parser.timeZone = timeZone
        }
        guard let date = parser.date(from: isoString) else { return "N/A" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = parser.timeZone
        return formatter.string(from: date)
    }
    
    /// Format an ISO time string to hour format (e.g., "3PM")
    /// Note: Creates per-call formatter when timezone is specified because mutating shared static formatters is not thread-safe
    static func formatHour(_ isoString: String, timezone: String? = nil) -> String {
        guard let date = isoParser.date(from: isoString) else { return "" }
        
        if let tz = timezone, let timeZone = TimeZone(identifier: tz) {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            formatter.timeZone = timeZone
            return formatter.string(from: date)
        }
        return Self.hourFormatter.string(from: date)
    }
    
    /// Format a date string to day abbreviation (e.g., "Mon")
    static func formatDayName(_ dateString: String) -> String {
        let parser = Self.isoDateOnlyParser
        guard let date = parser.date(from: dateString) else { return "" }
        return Self.dayNameFormatter.string(from: date)
    }
}
