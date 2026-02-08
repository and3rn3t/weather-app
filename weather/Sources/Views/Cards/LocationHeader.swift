//
//  LocationHeader.swift
//  weather
//
//  Extracted from WeatherDetailView.swift for modularity.
//

import SwiftUI

// MARK: - Location Header

struct LocationHeader: View {
    let locationName: String?
    let weatherData: WeatherData
    let onSearchTapped: () -> Void
    var onShareCardTapped: (() -> Void)? = nil
    @Environment(SettingsManager.self) var settings
    
    private var shareText: String {
        let location = locationName ?? "Current Location"
        let condition = WeatherCondition(code: weatherData.current.weatherCode).description
        let temp = settings.formatTemperature(weatherData.current.temperature2m)
        let feelsLike = settings.formatTemperature(weatherData.current.apparentTemperature)
        
        let text = """
        📍 \(location)
        🌡️ \(temp) (Feels like \(feelsLike))
        ☁️ \(condition)
        💨 Wind: \(settings.formatWindSpeed(weatherData.current.windSpeed10m))
        💧 Humidity: \(weatherData.current.relativeHumidity2m)%
        ☀️ UV Index: \(String(format: "%.1f", weatherData.current.uvIndex))
        
        Shared from Andernet Weather
        """
        
        return text
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue.gradient)
                    
                    if let locationName = locationName {
                        Text(locationName)
                            .font(.title2.weight(.semibold))
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Finding location...")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Last updated time
                Text("Updated \(Date.now, format: .dateTime.hour().minute())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // Share button
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share weather text")
                
                // Share weather card button
                if let onShareCardTapped {
                    Button(action: {
                        HapticFeedback.impact()
                        onShareCardTapped()
                    }) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.blue)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share weather card")
                }
                
                // Search button
                Button(action: {
                    HapticFeedback.impact()
                    onSearchTapped()
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search locations")
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}
