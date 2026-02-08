//
//  WeatherSnippetView.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI

/// A compact view shown by Siri when displaying weather results
struct WeatherSnippetView: View {
    let temperature: Double
    let condition: WeatherCondition
    let locationName: String
    let high: Double
    let low: Double
    let settings: SettingsManager?
    
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
                Text(formattedTemperature(temperature))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                
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
                    Text(formattedTemperature(high))
                        .font(.headline)
                        .contentTransition(.numericText())
                }
                .foregroundStyle(.orange)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption.bold())
                    Text(formattedTemperature(low))
                        .font(.headline)
                        .contentTransition(.numericText())
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
    
    private func formattedTemperature(_ value: Double) -> String {
        if let settings = settings {
            return settings.formatTemperature(value)
        }
        return "\(Int(value))°"
    }
    
    // Full initializer with settings
    init(temperature: Double, condition: WeatherCondition, locationName: String, high: Double, low: Double, settings: SettingsManager? = nil) {
        self.temperature = temperature
        self.condition = condition
        self.locationName = locationName
        self.high = high
        self.low = low
        self.settings = settings
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
