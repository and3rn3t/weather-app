//
//  Andernet_Weather_WidgetLiveActivity.swift
//  Andernet Weather Widget
//
//  Created by Matt on 2/5/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Weather Activity Attributes

struct WeatherActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that updates
        var temperature: Double
        var weatherCode: Int
        var highTemp: Double
        var lowTemp: Double
        var humidity: Int
        var windSpeed: Double
        var lastUpdated: Date
    }
    
    // Fixed properties set at start
    var locationName: String
}

// MARK: - Weather Condition (for Live Activity)

private enum WeatherConditionLA {
    case clearSky, partlyCloudy, cloudy, foggy, drizzle, rain, snow, thunderstorm, unknown
    
    init(code: Int) {
        switch code {
        case 0: self = .clearSky
        case 1, 2: self = .partlyCloudy
        case 3: self = .cloudy
        case 45, 48: self = .foggy
        case 51, 53, 55: self = .drizzle
        case 61, 63, 65, 80, 81, 82: self = .rain
        case 71, 73, 75, 77, 85, 86: self = .snow
        case 95, 96, 99: self = .thunderstorm
        default: self = .unknown
        }
    }
    
    var symbolName: String {
        switch self {
        case .clearSky: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .clearSky: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .foggy: return "Foggy"
        case .drizzle: return "Drizzle"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .thunderstorm: return "Thunderstorm"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Live Activity Widget

struct Andernet_Weather_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WeatherActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: WeatherConditionLA(code: context.state.weatherCode).symbolName)
                            .font(.title2)
                            .symbolRenderingMode(.multicolor)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(context.state.temperature))°")
                            .font(.title.bold())
                        Text("H:\(Int(context.state.highTemp))° L:\(Int(context.state.lowTemp))°")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.locationName)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        Label("\(context.state.humidity)%", systemImage: "humidity")
                            .font(.caption)
                        Label("\(Int(context.state.windSpeed)) mph", systemImage: "wind")
                            .font(.caption)
                        Text(WeatherConditionLA(code: context.state.weatherCode).description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: WeatherConditionLA(code: context.state.weatherCode).symbolName)
                    .symbolRenderingMode(.multicolor)
            } compactTrailing: {
                Text("\(Int(context.state.temperature))°")
                    .font(.caption.bold())
            } minimal: {
                Image(systemName: WeatherConditionLA(code: context.state.weatherCode).symbolName)
                    .symbolRenderingMode(.multicolor)
            }
            .widgetURL(URL(string: "weather://current"))
            .keylineTint(.cyan)
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<WeatherActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // Weather icon
            Image(systemName: WeatherConditionLA(code: context.state.weatherCode).symbolName)
                .font(.system(size: 40))
                .symbolRenderingMode(.multicolor)
            
            // Temperature and location
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(context.state.temperature))°")
                        .font(.system(size: 36, weight: .semibold))
                    
                    Text(WeatherConditionLA(code: context.state.weatherCode).description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // High/Low and details
            VStack(alignment: .trailing, spacing: 6) {
                Text("H:\(Int(context.state.highTemp))° L:\(Int(context.state.lowTemp))°")
                    .font(.caption)
                
                HStack(spacing: 12) {
                    Label("\(context.state.humidity)%", systemImage: "humidity")
                        .font(.caption2)
                    Label("\(Int(context.state.windSpeed))", systemImage: "wind")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.5))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Preview

extension WeatherActivityAttributes {
    fileprivate static var preview: WeatherActivityAttributes {
        WeatherActivityAttributes(locationName: "San Francisco")
    }
}

extension WeatherActivityAttributes.ContentState {
    fileprivate static var sunny: WeatherActivityAttributes.ContentState {
        WeatherActivityAttributes.ContentState(
            temperature: 72,
            weatherCode: 0,
            highTemp: 78,
            lowTemp: 62,
            humidity: 45,
            windSpeed: 8,
            lastUpdated: Date()
        )
    }
    
    fileprivate static var rainy: WeatherActivityAttributes.ContentState {
        WeatherActivityAttributes.ContentState(
            temperature: 58,
            weatherCode: 61,
            highTemp: 62,
            lowTemp: 54,
            humidity: 85,
            windSpeed: 12,
            lastUpdated: Date()
        )
    }
}

#Preview("Notification", as: .content, using: WeatherActivityAttributes.preview) {
    Andernet_Weather_WidgetLiveActivity()
} contentStates: {
    WeatherActivityAttributes.ContentState.sunny
    WeatherActivityAttributes.ContentState.rainy
}

