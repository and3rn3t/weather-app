//
//  CurrentWeatherCard.swift
//  weather
//
//  Extracted from WeatherDetailView.swift for modularity.
//

import SwiftUI

struct CurrentWeatherCard: View {
    let current: CurrentWeather
    let todayHigh: Double?
    let todayLow: Double?
    @State private var isTapped = false
    @State private var isVisible = false
    @Environment(SettingsManager.self) var settings
    
    var body: some View {
        VStack(spacing: 16) {
            let condition = WeatherCondition(code: current.weatherCode)
            
            // Large weather icon with scaling effect
            Image(systemName: condition.symbolName)
                .font(.system(size: 100))
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.bounce, value: current.temperature2m)
                .symbolEffect(.breathe.pulse, isActive: isVisible)
                .padding(.top, 8)
                .accessibilityLabel("Weather condition: \(condition.description)")
            
            // Temperature display - tap it for interaction!
            Button(action: {
                // Haptic feedback
                HapticFeedback.impact()
                
                // Bounce animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isTapped.toggle()
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    isTapped = false
                }
            }) {
                Text(settings.formatTemperature(current.temperature2m))
                    .font(.system(size: 80, weight: .thin, design: .rounded))
                    .foregroundStyle(temperatureGradient)
                    .contentTransition(.numericText())
                    .scaleEffect(isTapped ? 1.1 : 1.0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Current temperature")
            .accessibilityValue(settings.formatTemperature(current.temperature2m))
            .accessibilityHint("Tap for animation")
            
            // Condition description with icon
            HStack(spacing: 8) {
                Text(condition.description)
                    .font(.title2.weight(.medium))
                
                // High/Low for today
                if let high = todayHigh, let low = todayLow {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("H:\(settings.formatTemperature(high))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                    Text("L:\(settings.formatTemperature(low))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.cyan)
                        .contentTransition(.numericText())
                }
            }
            
            // Feels like temperature
            if settings.showFeelsLike {
                HStack(spacing: 6) {
                    Image(systemName: feelsLikeIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Feels like \(settings.formatTemperature(current.apparentTemperature))")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
                .padding(.bottom, 8)
                .accessibilityLabel("Feels like temperature: \(settings.formatTemperature(current.apparentTemperature))")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .glassEffect(Glass.regular, in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                isVisible = true
            }
        }
    }
    
    // Temperature gradient based on actual temp (always in Fahrenheit from API)
    private var temperatureGradient: LinearGradient {
        let temp = current.temperature2m // Always Fahrenheit from API
        let colors: [Color]
        
        switch temp {
        case ..<32:
            colors = [.cyan, .blue]
        case 32..<50:
            colors = [.blue, .teal]
        case 50..<70:
            colors = [.teal, .green]
        case 70..<85:
            colors = [.yellow, .orange]
        default:
            colors = [.orange, .red]
        }
        
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
    
    private var feelsLikeIcon: String {
        let diff = current.apparentTemperature - current.temperature2m
        if diff > 5 {
            return "thermometer.sun.fill"
        } else if diff < -5 {
            return "thermometer.snowflake"
        } else {
            return "thermometer.medium"
        }
    }
}
