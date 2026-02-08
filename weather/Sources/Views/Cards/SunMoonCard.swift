//
//  SunMoonCard.swift
//  weather
//
//  Extracted from WeatherDetailView.swift for modularity.
//

import SwiftUI

struct SunMoonCard: View {
    let daily: DailyWeather
    let isDay: Bool
    let timezone: String
    
    /// Cached moon phase — computed once instead of on every re-render
    @State private var moonPhase = MoonPhase.current()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(isDay ? "Daylight" : "Tonight")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                // Show timezone abbreviation
                Text(timezoneAbbreviation)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.15), in: Capsule())
            }
            
            HStack(spacing: 40) {
                // Sunrise
                VStack(spacing: 8) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 40))
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(.orange.gradient)
                        .frame(height: 40)
                        .accessibilityHidden(true)
                    
                    Text("Sunrise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    if let sunrise = daily.sunrise.first {
                        Text(SettingsManager.formatSunTime(sunrise, timezone: timezone))
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    } else {
                        Text("--:--")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(sunriseAccessibilityLabel)
                
                Divider()
                    .frame(height: 80)
                    .accessibilityHidden(true)
                
                // Sunset
                VStack(spacing: 8) {
                    Image(systemName: "sunset.fill")
                        .font(.system(size: 40))
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(.orange.gradient)
                        .frame(height: 40)
                        .accessibilityHidden(true)
                    
                    Text("Sunset")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    if let sunset = daily.sunset.first {
                        Text(SettingsManager.formatSunTime(sunset, timezone: timezone))
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    } else {
                        Text("--:--")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(sunsetAccessibilityLabel)
            }
            
            // Day length and Moon phase
            VStack(spacing: 8) {
                if let sunrise = daily.sunrise.first,
                   let sunset = daily.sunset.first,
                   let dayLength = calculateDayLength(sunrise: sunrise, sunset: sunset) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("Daylight: \(dayLength)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Total daylight: \(dayLength)")
                }
                
                // Moon phase
                HStack(spacing: 6) {
                    Text(moonPhase.emoji)
                        .font(.body)
                        .accessibilityHidden(true)
                    Text("\(moonPhase.name) • \(Int(moonPhase.illumination * 100))% illuminated")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
                .accessibilityLabel("Moon phase: \(moonPhase.name), \(Int(moonPhase.illumination * 100)) percent illuminated")
            }
            .padding(.top, 4)
        }
        .padding(20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sun and Moon information")
    }
    
    private var sunriseAccessibilityLabel: String {
        if let sunrise = daily.sunrise.first {
            return WeatherAccessibility.sunriseLabel(sunrise)
        }
        return "Sunrise time unavailable"
    }
    
    private var sunsetAccessibilityLabel: String {
        if let sunset = daily.sunset.first {
            return WeatherAccessibility.sunsetLabel(sunset)
        }
        return "Sunset time unavailable"
    }
    
    private var timezoneAbbreviation: String {
        guard let timeZone = TimeZone(identifier: timezone) else {
            return timezone
        }
        return timeZone.abbreviation() ?? timezone
    }
    
    private func calculateDayLength(sunrise: String, sunset: String) -> String? {
        let parser = SettingsManager.isoParser
        guard let sunriseDate = parser.date(from: sunrise),
              let sunsetDate = parser.date(from: sunset) else { return nil }
        
        let interval = sunsetDate.timeIntervalSince(sunriseDate)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return "\(hours)h \(minutes)m"
    }
}
