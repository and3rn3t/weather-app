//
//  WeatherControlWidget.swift
//  Andernet Weather Widget
//
//  Created by Matt on 2/5/26.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - App Group Identifier (shared with main app)

private enum ControlAppGroup {
    static let identifier = "group.dev.andernet.weather"
    
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

// MARK: - Control Widget Data

private struct ControlWeatherData: Codable {
    let temperature: Double
    let weatherCode: Int
    let precipitationProbability: Int
}

private func loadControlData() -> ControlWeatherData? {
    guard let sharedDefaults = ControlAppGroup.sharedDefaults,
          let data = sharedDefaults.data(forKey: "sharedWeatherData") else {
        return nil
    }
    
    // Decode just the fields we need
    struct PartialData: Codable {
        let temperature: Double
        let weatherCode: Int
        let precipitationProbability: Int?
    }
    
    do {
        let partial = try JSONDecoder().decode(PartialData.self, from: data)
        return ControlWeatherData(
            temperature: partial.temperature,
            weatherCode: partial.weatherCode,
            precipitationProbability: partial.precipitationProbability ?? 0
        )
    } catch {
        return nil
    }
}

// MARK: - Weather Symbol Helper

private func weatherSymbol(for code: Int) -> String {
    switch code {
    case 0: return "sun.max.fill"
    case 1, 2: return "cloud.sun.fill"
    case 3: return "cloud.fill"
    case 45, 48: return "cloud.fog.fill"
    case 51, 53, 55: return "cloud.drizzle.fill"
    case 61, 63, 65, 80, 81, 82: return "cloud.rain.fill"
    case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
    case 95, 96, 99: return "cloud.bolt.fill"
    default: return "cloud.fill"
    }
}

private func conditionName(for code: Int) -> String {
    switch code {
    case 0: return "Clear"
    case 1, 2: return "Partly Cloudy"
    case 3: return "Cloudy"
    case 45, 48: return "Foggy"
    case 51, 53, 55: return "Drizzle"
    case 61, 63, 65, 80, 81, 82: return "Rain"
    case 71, 73, 75, 77, 85, 86: return "Snow"
    case 95, 96, 99: return "Thunderstorm"
    default: return "Unknown"
    }
}

// MARK: - Open App Intent

struct OpenWeatherAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Weather"
    static let description = IntentDescription("Opens the Weather app")
    static let openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Weather Control Widget

/// A Control Center widget that shows current temperature and conditions
@available(iOS 18.0, *)
struct WeatherControlWidget: ControlWidget {
    static let kind: String = "dev.andernet.weather.control"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenWeatherAppIntent()) {
                let data = loadControlData()
                
                Label {
                    Text(data.map { "\(Int($0.temperature))°" } ?? "--°")
                } icon: {
                    Image(systemName: data.map { weatherSymbol(for: $0.weatherCode) } ?? "cloud.fill")
                }
            }
        }
        .displayName("Weather")
        .description("View current temperature and open weather app.")
    }
}

// MARK: - Temperature Control Widget

/// A Control Center widget showing just the temperature
@available(iOS 18.0, *)
struct TemperatureControlWidget: ControlWidget {
    static let kind: String = "dev.andernet.weather.temperature"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenWeatherAppIntent()) {
                let data = loadControlData()
                
                Label {
                    if let weatherData = data {
                        Text("\(Int(weatherData.temperature))°F")
                    } else {
                        Text("--°")
                    }
                } icon: {
                    Image(systemName: "thermometer.medium")
                }
            }
        }
        .displayName("Temperature")
        .description("View current temperature.")
    }
}

// MARK: - Conditions Control Widget

/// A Control Center widget showing weather conditions
@available(iOS 18.0, *)
struct ConditionsControlWidget: ControlWidget {
    static let kind: String = "dev.andernet.weather.conditions"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenWeatherAppIntent()) {
                let data = loadControlData()
                
                Label {
                    Text(data.map { conditionName(for: $0.weatherCode) } ?? "Unknown")
                } icon: {
                    Image(systemName: data.map { weatherSymbol(for: $0.weatherCode) } ?? "questionmark.circle")
                }
            }
        }
        .displayName("Conditions")
        .description("View current weather conditions.")
    }
}

// MARK: - Rain Chance Control Widget

/// A Control Center widget showing precipitation probability
@available(iOS 18.0, *)
struct RainChanceControlWidget: ControlWidget {
    static let kind: String = "dev.andernet.weather.rainchance"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenWeatherAppIntent()) {
                let data = loadControlData()
                
                Label {
                    if let weatherData = data {
                        Text("\(weatherData.precipitationProbability)%")
                    } else {
                        Text("--%")
                    }
                } icon: {
                    Image(systemName: "drop.fill")
                }
            }
        }
        .displayName("Rain Chance")
        .description("View precipitation probability.")
    }
}
