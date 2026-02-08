//
//  WeatherRecommendationsCard.swift
//  weather
//
//  Extracted from WeatherDetailView.swift for modularity.
//

import SwiftUI

// MARK: - Recommendation Model

struct Recommendation: Hashable {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Weather Recommendations Card

/// Smart weather recommendations based on current conditions
struct WeatherRecommendationsCard: View {
    let current: CurrentWeather
    let hourly: HourlyWeather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 12) {
                ForEach(recommendations, id: \.title) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                }
            }
        }
        .padding(20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weather Recommendations")
    }
    
    private var recommendations: [Recommendation] {
        var recs: [Recommendation] = []
        
        // UV Index recommendation
        if current.uvIndex >= 6 {
            recs.append(Recommendation(
                icon: "sun.max.fill",
                title: "Sun Protection",
                description: "UV index is high. Wear sunscreen and protective clothing.",
                color: .orange
            ))
        }
        
        // Rain recommendation
        if let precipProbs = hourly.precipitationProbability,
           let rainChance = precipProbs.prefix(6).max(),
           rainChance > 30 {
            recs.append(Recommendation(
                icon: "umbrella.fill",
                title: "Bring Umbrella",
                description: "\(rainChance)% chance of rain in the next 6 hours.",
                color: .blue
            ))
        }
        
        // Temperature recommendation
        if current.apparentTemperature < 32 {
            recs.append(Recommendation(
                icon: "thermometer.snowflake",
                title: "Dress Warm",
                description: "Feels like \(Int(current.apparentTemperature))°. Bundle up!",
                color: .cyan
            ))
        } else if current.apparentTemperature > 90 {
            recs.append(Recommendation(
                icon: "thermometer.sun.fill",
                title: "Stay Cool",
                description: "Feels like \(Int(current.apparentTemperature))°. Stay hydrated!",
                color: .red
            ))
        }
        
        // Wind recommendation
        if current.windSpeed10m > 20 {
            recs.append(Recommendation(
                icon: "wind",
                title: "Windy Conditions",
                description: "Winds at \(Int(current.windSpeed10m)) mph. Secure loose objects.",
                color: .gray
            ))
        }
        
        // Visibility recommendation
        if current.visibility < 5000 {
            recs.append(Recommendation(
                icon: "eye.slash.fill",
                title: "Low Visibility",
                description: "Drive carefully. Visibility is reduced.",
                color: .purple
            ))
        }
        
        // Default good weather
        if recs.isEmpty {
            recs.append(Recommendation(
                icon: "checkmark.circle.fill",
                title: "Pleasant Weather",
                description: "Conditions are ideal. Enjoy your day!",
                color: .green
            ))
        }
        
        return recs
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let recommendation: Recommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendation.icon)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(recommendation.color.gradient)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline.weight(.semibold))
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(recommendation.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
