//
//  DailyForecastCard.swift
//  weather
//
//  Extracted from WeatherDetailView.swift for modularity.
//

import SwiftUI

// MARK: - Daily Forecast Card

struct DailyForecastCard: View {
    let daily: DailyWeather
    @State private var showExtendedForecast = false
    @State private var expandedDay: Int? = nil
    
    var displayedDays: Int {
        showExtendedForecast ? min(daily.time.count, 14) : 7
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("14-Day Forecast")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Button {
                    HapticFeedback.impact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showExtendedForecast.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showExtendedForecast ? "Show Less" : "Show All")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: showExtendedForecast ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(Array(daily.time.prefix(displayedDays).enumerated()), id: \.offset) { index, time in
                    DailyWeatherRow(
                        date: time,
                        weatherCode: daily.weatherCode[index],
                        high: daily.temperature2mMax[index],
                        low: daily.temperature2mMin[index],
                        precipProbability: daily.precipitationProbabilityMax[index],
                        uvIndex: daily.uvIndexMax[index] ?? 0,
                        windSpeed: daily.windSpeed10mMax[index] ?? 0,
                        isExpanded: expandedDay == index,
                        onTap: {
                            HapticFeedback.impact()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                expandedDay = expandedDay == index ? nil : index
                            }
                        }
                    )
                    
                    if index < displayedDays - 1 {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 16)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Daily Weather Row

struct DailyWeatherRow: View {
    let date: String
    let weatherCode: Int
    let high: Double
    let low: Double
    let precipProbability: Int
    let uvIndex: Double
    let windSpeed: Double
    let isExpanded: Bool
    let onTap: () -> Void
    @Environment(SettingsManager.self) var settings
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 12) {
                    // Day name
                    Text(formattedDate)
                        .frame(width: 80, alignment: .leading)
                        .font(.body.weight(.medium))
                    
                    // Weather icon
                    Image(systemName: WeatherCondition(code: weatherCode).symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.title3)
                        .frame(width: 36)
                    
                    // Precipitation
                    if precipProbability > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "drop.fill")
                                .font(.caption2)
                            Text("\(precipProbability)%")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.blue)
                        .frame(width: 55, alignment: .leading)
                    } else {
                        Spacer()
                            .frame(width: 55)
                    }
                    
                    Spacer()
                    
                    // Temperatures
                    HStack(spacing: 12) {
                        Text(settings.formatTemperature(low))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: 48, alignment: .trailing)
                            .contentTransition(.numericText())
                        
                        Text(settings.formatTemperature(high))
                            .font(.body.weight(.semibold))
                            .monospacedDigit()
                            .frame(width: 48, alignment: .trailing)
                            .contentTransition(.numericText())
                    }
                }
                .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
            
            // Additional info row — only shown when expanded (tap to reveal)
            if isExpanded {
                HStack(spacing: 10) {
                    Spacer()
                        .frame(width: 80)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "wind")
                            .font(.caption2)
                        Text(settings.formatWindSpeed(windSpeed))
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.15), in: Capsule())
                    .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .font(.caption2)
                        Text("UV \(Int(uvIndex))")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(uvColor.opacity(0.2), in: Capsule())
                    .foregroundStyle(uvColor)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.9, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .top))
                ))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WeatherAccessibility.dailyForecastLabel(day: date, high: high, low: low, code: weatherCode) + ". " + WeatherAccessibility.precipitationProbabilityLabel(precipProbability))
        .accessibilityHint("Double tap to \(isExpanded ? "hide" : "show") wind and UV details")
    }
    
    private var formattedDate: String {
        SettingsManager.formatDayName(date)
    }
    
    private var uvColor: Color {
        UVIndexHelper.color(for: uvIndex)
    }
}
