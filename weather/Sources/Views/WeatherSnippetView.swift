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
    let condition: WeatherCondition
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
    
    // Internal initializer that accepts WeatherCondition
    init(temperature: Int, condition: WeatherCondition, locationName: String, high: Int, low: Int) {
        self.temperature = temperature
        self.condition = condition
        self.locationName = locationName
        self.high = high
        self.low = low
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
