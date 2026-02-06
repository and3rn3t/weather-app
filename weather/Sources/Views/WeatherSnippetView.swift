//
//  WeatherSnippetView.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI

/// A compact view shown by Siri when displaying weather results
struct WeatherSnippetView: View {
    let temperature: Int
    let condition: WeatherConditionSnippet
    let locationName: String
    let high: Int
    let low: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Weather Icon
            Image(systemName: condition.symbolName)
                .font(.system(size: 44))
                .symbolRenderingMode(.multicolor)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                // Location
                Text(locationName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Temperature
                Text("\(temperature)°")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                
                // Condition
                Text(condition.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // High/Low
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption.bold())
                    Text("\(high)°")
                        .font(.headline)
                }
                .foregroundStyle(.orange)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption.bold())
                    Text("\(low)°")
                        .font(.headline)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // Internal initializer that accepts WeatherConditionSnippet
    init(temperature: Int, condition: WeatherConditionSnippet, locationName: String, high: Int, low: Int) {
        self.temperature = temperature
        self.condition = condition
        self.locationName = locationName
        self.high = high
        self.low = low
    }
}

// Separate type to avoid collision with other WeatherCondition enums
enum WeatherConditionSnippet {
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
    
    var description: String {
        switch self {
        case .clearSky: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .foggy: return "Foggy"
        case .drizzle: return "Drizzle"
        case .rain: return "Rainy"
        case .snow: return "Snowy"
        case .thunderstorm: return "Stormy"
        case .unknown: return "Unknown"
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
}

#Preview {
    WeatherSnippetView(
        temperature: 72,
        condition: .partlyCloudy,
        locationName: "San Francisco",
        high: 78,
        low: 58
    )
    .padding()
}
