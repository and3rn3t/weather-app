//
//  AirQualityCard.swift
//  weather
//
//  Extracted from WeatherDetailView.swift for modularity.
//

import SwiftUI

// MARK: - Health Recommendation Model

struct HealthRecommendation: Hashable {
    let icon: String
    let text: String
}

// MARK: - Air Quality Card

/// Air Quality Index card with real API data
struct AirQualityCard: View {
    let airQualityData: AirQualityData?
    
    // Computed AQI value - uses real data or shows unavailable state
    private var aqi: Int? {
        airQualityData?.current.usAqi
    }
    
    /// Cached category to avoid recomputing in every subview
    private var cachedCategory: (name: String, color: Color, description: String)? {
        guard let aqi = aqi else { return nil }
        return aqiCategory(for: aqi)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Air Quality")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                if let category = cachedCategory {
                    Text(category.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(category.color.opacity(0.2), in: Capsule())
                } else {
                    Text("Unavailable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.2), in: Capsule())
                }
            }
            
            if let aqi = aqi, let data = airQualityData?.current, let category = cachedCategory {
                HStack(spacing: 20) {
                    // AQI gauge
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: min(CGFloat(aqi) / 200.0, 1.0))
                            .stroke(
                                category.color.gradient,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text("\(aqi)")
                                .font(.title.weight(.bold))
                                .foregroundStyle(category.color)
                                .contentTransition(.numericText())
                            Text("AQI")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(WeatherAccessibility.airQualityLabel(aqi))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "PM2.5", value: String(format: "%.1f μg/m³", data.pm25))
                            .accessibilityLabel("PM 2.5: \(String(format: "%.1f", data.pm25)) micrograms per cubic meter")
                        InfoRow(label: "PM10", value: String(format: "%.1f μg/m³", data.pm10))
                            .accessibilityLabel("PM 10: \(String(format: "%.1f", data.pm10)) micrograms per cubic meter")
                        if let ozone = data.ozone {
                            InfoRow(label: "O₃", value: String(format: "%.0f μg/m³", ozone))
                                .accessibilityLabel("Ozone: \(String(format: "%.0f", ozone)) micrograms per cubic meter")
                        }
                    }
                }
                
                Text(category.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                
                // Health Recommendations
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 4)
                    
                    Text("Health Recommendations")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    ForEach(healthRecommendations(for: aqi), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: recommendation.icon)
                                .font(.caption)
                                .foregroundStyle(category.color)
                                .frame(width: 16)
                            Text(recommendation.text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "aqi.low")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("Air quality data is currently unavailable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Air Quality")
    }
    
    private func aqiCategory(for aqi: Int) -> (name: String, color: Color, description: String) {
        switch aqi {
        case 0..<51:
            return ("Good", .green, "Air quality is satisfactory. Outdoor activities are encouraged.")
        case 51..<101:
            return ("Moderate", .yellow, "Air quality is acceptable for most people.")
        case 101..<151:
            return ("Unhealthy for Sensitive Groups", .orange, "Sensitive individuals should limit prolonged outdoor exertion.")
        case 151..<201:
            return ("Unhealthy", .red, "Everyone may begin to experience health effects.")
        default:
            return ("Very Unhealthy", .purple, "Health alert: everyone may experience serious effects.")
        }
    }
    
    private func healthRecommendations(for aqi: Int) -> [HealthRecommendation] {
        switch aqi {
        case 0..<51:
            return [
                HealthRecommendation(icon: "figure.run", text: "Perfect for outdoor activities and exercise"),
                HealthRecommendation(icon: "lungs.fill", text: "Air quality is ideal for everyone")
            ]
        case 51..<101:
            return [
                HealthRecommendation(icon: "figure.walk", text: "Outdoor activities are generally safe"),
                HealthRecommendation(icon: "exclamationmark.triangle", text: "Unusually sensitive people should consider reducing prolonged outdoor exertion")
            ]
        case 101..<151:
            return [
                HealthRecommendation(icon: "figure.walk", text: "Sensitive groups should limit prolonged outdoor activities"),
                HealthRecommendation(icon: "allergyshot", text: "People with respiratory conditions should take extra precautions"),
                HealthRecommendation(icon: "wind", text: "Consider indoor activities if you're sensitive to air pollution")
            ]
        case 151..<201:
            return [
                HealthRecommendation(icon: "exclamationmark.triangle.fill", text: "Everyone should reduce prolonged outdoor exertion"),
                HealthRecommendation(icon: "allergyshot.fill", text: "Sensitive groups should avoid outdoor activities"),
                HealthRecommendation(icon: "house.fill", text: "Consider staying indoors and using air purifiers")
            ]
        default:
            return [
                HealthRecommendation(icon: "exclamationmark.octagon.fill", text: "Avoid all outdoor physical activities"),
                HealthRecommendation(icon: "house.fill", text: "Stay indoors and keep windows closed"),
                HealthRecommendation(icon: "allergyshot.fill", text: "Sensitive groups should remain indoors"),
                HealthRecommendation(icon: "cross.circle.fill", text: "Health alert: serious health effects for everyone")
            ]
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
    }
}
