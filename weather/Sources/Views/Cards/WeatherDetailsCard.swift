//
//  WeatherDetailsCard.swift
//  weather
//
//  Extracted from WeatherDetailView.swift for modularity.
//

import SwiftUI

// MARK: - Weather Details Card

struct WeatherDetailsCard: View {
    let current: CurrentWeather
    @Environment(SettingsManager.self) private var settings
    
    /// Meters per mile conversion factor
    private static let metersPerMile = WeatherAccessibility.metersPerMile
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Current Conditions")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // First Row: Wind & Humidity
            HStack(spacing: 0) {
                WeatherDetailItem(
                    title: "Wind Speed",
                    value: "\(Int(settings.convertedWindSpeed(current.windSpeed10m)))",
                    unit: settings.windSpeedUnit.symbol,
                    subtitle: windDirection,
                    icon: "wind",
                    color: .cyan
                )
                
                Divider()
                    .frame(height: 70)
                    .padding(.horizontal, 8)
                
                WeatherDetailItem(
                    title: "Humidity",
                    value: "\(current.relativeHumidity2m)",
                    unit: "%",
                    icon: "humidity.fill",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 70)
                    .padding(.horizontal, 8)
                
                WeatherDetailItem(
                    title: "Gusts",
                    value: "\(Int(settings.convertedWindSpeed(current.windGusts10m)))",
                    unit: settings.windSpeedUnit.symbol,
                    icon: "tornado",
                    color: .cyan
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(WeatherAccessibility.windLabel(speed: current.windSpeed10m, direction: Int(current.windDirection10m), unit: settings.windSpeedUnit) + ". " + WeatherAccessibility.humidityLabel(current.relativeHumidity2m))
            
            Divider()
            
            // Second Row: UV Index, Visibility, Pressure
            HStack(spacing: 0) {
                WeatherDetailItem(
                    title: "UV Index",
                    value: String(format: "%.1f", current.uvIndex),
                    subtitle: uvCategory,
                    icon: "sun.max.fill",
                    color: uvColor
                )
                
                Divider()
                    .frame(height: 70)
                    .padding(.horizontal, 8)
                
                WeatherDetailItem(
                    title: "Visibility",
                    value: String(format: "%.1f", current.visibility / Self.metersPerMile),
                    unit: "mi",
                    icon: "eye.fill",
                    color: .purple
                )
                
                Divider()
                    .frame(height: 70)
                    .padding(.horizontal, 8)
                
                WeatherDetailItem(
                    title: "Pressure",
                    value: String(format: "%.0f", current.pressure),
                    unit: "hPa",
                    icon: "gauge.with.needle.fill",
                    color: .orange
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(WeatherAccessibility.uvIndexLabel(current.uvIndex) + ". " + WeatherAccessibility.visibilityLabel(current.visibility) + ". " + WeatherAccessibility.pressureLabel(current.pressure))
            
            Divider()
            
            // Third Row: Cloud Cover, Dew Point, Precipitation
            HStack(spacing: 0) {
                WeatherDetailItem(
                    title: "Cloud Cover",
                    value: "\(current.cloudCover)",
                    unit: "%",
                    icon: "cloud.fill",
                    color: .gray
                )
                
                Divider()
                    .frame(height: 70)
                    .padding(.horizontal, 8)
                
                WeatherDetailItem(
                    title: "Dew Point",
                    value: settings.formatTemperature(current.dewPoint2m),
                    icon: "drop.fill",
                    color: .teal
                )
                
                Divider()
                    .frame(height: 70)
                    .padding(.horizontal, 8)
                
                WeatherDetailItem(
                    title: "Precip",
                    value: settings.formatPrecipitation(current.precipitation),
                    icon: "cloud.rain.fill",
                    color: .blue
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Cloud cover \(current.cloudCover) percent. Dew point \(settings.formatTemperature(current.dewPoint2m)). " + WeatherAccessibility.precipitationAmountLabel(current.precipitation))
        }
        .padding(20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private var windDirection: String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((current.windDirection10m + 22.5) / 45.0) % 8
        return directions[index]
    }
    
    private var uvCategory: String {
        UVIndexHelper.level(for: current.uvIndex)
    }
    
    private var uvColor: Color {
        UVIndexHelper.color(for: current.uvIndex)
    }
}

// MARK: - Weather Detail Item

struct WeatherDetailItem: View {
    let title: String
    let value: String
    var unit: String? = nil
    var subtitle: String? = nil
    let icon: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color.gradient)
                .frame(height: 28)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(spacing: 3) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.1), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
