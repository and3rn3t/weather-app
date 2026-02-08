//
//  AccessibilityHelpers.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI

// MARK: - Accessibility Labels

/// Centralized accessibility labels for weather data
enum WeatherAccessibility {
    
    /// Meters per mile conversion factor (shared across the app)
    static let metersPerMile = 1609.34
    
    // MARK: - Temperature Labels
    
    static func temperatureLabel(_ temp: Double, unit: TemperatureUnit = .fahrenheit) -> String {
        let value = Int(temp)
        let unitName = unit == .fahrenheit ? "degrees Fahrenheit" : "degrees Celsius"
        return "\(value) \(unitName)"
    }
    
    static func temperatureRangeLabel(high: Double, low: Double, unit: TemperatureUnit = .fahrenheit) -> String {
        let unitName = unit == .fahrenheit ? "Fahrenheit" : "Celsius"
        return "High of \(Int(high)), low of \(Int(low)) \(unitName)"
    }
    
    static func feelsLikeLabel(_ temp: Double, unit: TemperatureUnit = .fahrenheit) -> String {
        let unitName = unit == .fahrenheit ? "degrees Fahrenheit" : "degrees Celsius"
        return "Feels like \(Int(temp)) \(unitName)"
    }
    
    // MARK: - Weather Condition Labels
    
    static func conditionLabel(code: Int) -> String {
        let condition = WeatherCondition(code: code)
        return "Weather condition: \(condition.fullDescription)"
    }
    
    // MARK: - Wind Labels
    
    static func windLabel(speed: Double, direction: Int, unit: WindSpeedUnit = .mph) -> String {
        let directionName = compassDirection(for: direction)
        return "Wind \(Int(speed)) \(unit.rawValue) from the \(directionName)"
    }
    
    static func compassDirection(for degrees: Int) -> String {
        let directions = ["north", "north-northeast", "northeast", "east-northeast",
                          "east", "east-southeast", "southeast", "south-southeast",
                          "south", "south-southwest", "southwest", "west-southwest",
                          "west", "west-northwest", "northwest", "north-northwest"]
        let index = Int((Double(degrees) / 22.5).rounded()) % 16
        return directions[index]
    }
    
    // MARK: - Humidity & Pressure Labels
    
    static func humidityLabel(_ percent: Int) -> String {
        return "Humidity: \(percent) percent"
    }
    
    static func pressureLabel(_ hPa: Double) -> String {
        return "Barometric pressure: \(Int(hPa)) hectopascals"
    }
    
    static func visibilityLabel(_ meters: Double) -> String {
        let miles = meters / metersPerMile
        if miles >= 10 {
            return "Visibility: excellent, more than 10 miles"
        } else if miles >= 5 {
            return "Visibility: good, about \(Int(miles)) miles"
        } else if miles >= 1 {
            return "Visibility: moderate, about \(Int(miles)) miles"
        } else {
            return "Visibility: poor, less than 1 mile"
        }
    }
    
    // MARK: - UV Index Labels
    
    static func uvIndexLabel(_ index: Double) -> String {
        let level: String
        switch index {
        case 0..<3: level = "low"
        case 3..<6: level = "moderate"
        case 6..<8: level = "high"
        case 8..<11: level = "very high"
        default: level = "extreme"
        }
        return "UV index: \(Int(index)), \(level) risk"
    }
    
    // MARK: - Precipitation Labels
    
    static func precipitationProbabilityLabel(_ percent: Int) -> String {
        if percent == 0 {
            return "No precipitation expected"
        } else if percent < 30 {
            return "\(percent) percent chance of precipitation, unlikely"
        } else if percent < 60 {
            return "\(percent) percent chance of precipitation, possible"
        } else {
            return "\(percent) percent chance of precipitation, likely"
        }
    }
    
    static func precipitationAmountLabel(_ inches: Double) -> String {
        if inches == 0 {
            return "No precipitation"
        } else if inches < 0.1 {
            return "Trace amounts of precipitation"
        } else if inches < 0.5 {
            return "Light precipitation, about \(String(format: "%.1f", inches)) inches"
        } else if inches < 1.0 {
            return "Moderate precipitation, about \(String(format: "%.1f", inches)) inches"
        } else {
            return "Heavy precipitation, about \(String(format: "%.1f", inches)) inches"
        }
    }
    
    // MARK: - Air Quality Labels
    
    static func airQualityLabel(_ aqi: Int) -> String {
        let level: String
        let advice: String
        
        switch aqi {
        case 0...50:
            level = "good"
            advice = "Air quality is satisfactory"
        case 51...100:
            level = "moderate"
            advice = "Air quality is acceptable"
        case 101...150:
            level = "unhealthy for sensitive groups"
            advice = "Sensitive individuals should reduce outdoor activity"
        case 151...200:
            level = "unhealthy"
            advice = "Everyone should reduce prolonged outdoor exertion"
        case 201...300:
            level = "very unhealthy"
            advice = "Avoid outdoor activity"
        default:
            level = "hazardous"
            advice = "Everyone should avoid all outdoor activity"
        }
        
        return "Air quality index: \(aqi), \(level). \(advice)"
    }
    
    // MARK: - Cached Formatters
    
    private static let speechISOParser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        return formatter
    }()
    
    private static let speechTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let speechDayParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    private static let speechDayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    // MARK: - Time Labels
    
    static func sunriseLabel(_ time: String) -> String {
        return "Sunrise at \(formatTimeForSpeech(time))"
    }
    
    static func sunsetLabel(_ time: String) -> String {
        return "Sunset at \(formatTimeForSpeech(time))"
    }
    
    private static func formatTimeForSpeech(_ isoTime: String) -> String {
        guard let date = speechISOParser.date(from: isoTime) else {
            return isoTime
        }
        return speechTimeFormatter.string(from: date)
    }
    
    // MARK: - Forecast Summary
    
    static func dailyForecastLabel(day: String, high: Double, low: Double, code: Int) -> String {
        let condition = WeatherCondition(code: code)
        let dayName = formatDayForSpeech(day)
        return "\(dayName): \(condition.fullDescription), high \(Int(high)), low \(Int(low))"
    }
    
    private static func formatDayForSpeech(_ isoDay: String) -> String {
        guard let date = speechDayParser.date(from: isoDay) else {
            return isoDay
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            return speechDayNameFormatter.string(from: date)
        }
    }
}

// MARK: - Weather Condition Accessibility Extension

extension WeatherCondition {
    /// Detailed description for accessibility/VoiceOver
    var fullDescription: String {
        switch self {
        case .clearSky: return "clear skies"
        case .partlyCloudy: return "partly cloudy"
        case .cloudy: return "cloudy"
        case .foggy: return "foggy with reduced visibility"
        case .drizzle: return "light drizzle"
        case .rain: return "rain"
        case .snow: return "snow"
        case .thunderstorm: return "thunderstorm"
        case .unknown: return "unknown conditions"
        }
    }
}

// MARK: - Dynamic Type Support

extension View {
    /// Scales content appropriately for Dynamic Type
    @ViewBuilder
    func dynamicTypeSize(minimum: DynamicTypeSize = .xSmall, maximum: DynamicTypeSize = .accessibility5) -> some View {
        self.dynamicTypeSize(minimum...maximum)
    }
}

// MARK: - Accessibility Announcements

enum AccessibilityAnnouncement {
    static func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    static func weatherUpdated(location: String?, temperature: Double) {
        let locationText = location ?? "your location"
        announce("Weather updated for \(locationText). Current temperature is \(Int(temperature)) degrees.")
    }
    
    static func errorOccurred(_ error: WeatherError) {
        announce("Error: \(error.errorDescription ?? "Unknown error"). \(error.recoverySuggestion ?? "")")
    }
}
