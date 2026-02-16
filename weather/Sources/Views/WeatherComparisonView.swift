//
//  WeatherComparisonView.swift
//  weather
//
//  Created by GitHub Copilot on 2/6/26.
//

import SwiftUI
import SwiftData

struct WeatherComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsManager.self) private var settings
    @Query private var favorites: [SavedLocation]
    
    @State private var locationWeatherData: [String: WeatherData] = [:]
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if favorites.isEmpty {
                        emptyState
                    } else if locationWeatherData.isEmpty {
                        loadingState
                    } else {
                        // Best weather finder
                        bestWeatherCard
                        
                        // Comparison grid
                        comparisonGrid
                    }
                }
                .padding()
            }
            .navigationTitle("Compare Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadWeatherForAllFavorites()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Favorite Locations")
                .font(.title2.weight(.semibold))
            
            Text("Add favorite locations to compare weather conditions across different places")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading weather data...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var bestWeatherCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Best Weather Now", systemImage: "sun.max.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.orange.gradient)
            
            if let best = findBestWeather() {
                HStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow.gradient)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(best.location.name)
                            .font(.title3.weight(.semibold))
                        
                        HStack(spacing: 8) {
                            Text(settings.formatTemperature(best.weather.current.temperature2m))
                                .font(.title2.weight(.bold))
                            
                            Image(systemName: WeatherCondition(code: best.weather.current.weatherCode).symbolName)
                                .font(.title3)
                                .symbolRenderingMode(.multicolor)
                        }
                        
                        Text(bestWeatherReason(best.weather))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private var comparisonGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
            ForEach(favorites) { favorite in
                if let weather = locationWeatherData[favorite.id.uuidString] {
                    ComparisonCard(
                        location: favorite,
                        weather: weather,
                        settings: settings
                    )
                }
            }
        }
    }
    
    private func loadWeatherForAllFavorites() async {
        isLoading = true
        
        // Fetch all locations in parallel using static method (no shared state)
        let results = await withTaskGroup(of: (String, WeatherData?).self, returning: [String: WeatherData].self) { group in
            for favorite in favorites {
                let lat = favorite.latitude
                let lon = favorite.longitude
                let id = favorite.id.uuidString
                
                group.addTask {
                    let service = await MainActor.run { WeatherService() }
                    await service.fetchWeatherData(latitude: lat, longitude: lon)
                    let data = await MainActor.run { service.weatherData }
                    return (id, data)
                }
            }
            
            var collected: [String: WeatherData] = [:]
            for await (id, data) in group {
                if let data = data {
                    collected[id] = data
                }
            }
            return collected
        }
        
        locationWeatherData = results
        isLoading = false
    }
    
    private func findBestWeather() -> (location: SavedLocation, weather: WeatherData)? {
        var bestScore: Double = -1000
        var bestPair: (SavedLocation, WeatherData)?
        
        for favorite in favorites {
            guard let weather = locationWeatherData[favorite.id.uuidString] else { continue }
            
            let score = calculateWeatherScore(weather)
            if score > bestScore {
                bestScore = score
                bestPair = (favorite, weather)
            }
        }
        
        return bestPair
    }
    
    private func calculateWeatherScore(_ weather: WeatherData) -> Double {
        var score: Double = 0
        
        // Temperature score (ideal: 65-75°F / 18-24°C)
        // API always returns Fahrenheit, so score on raw Fahrenheit values
        let temp = weather.current.temperature2m
        if temp >= 65 && temp <= 75 {
            score += 30
        } else if temp >= 55 && temp <= 85 {
            score += 15
        } else if temp < 32 || temp > 95 {
            score -= 20
        }
        
        // Weather condition score
        let code = weather.current.weatherCode
        switch code {
        case 0: score += 30  // Clear sky
        case 1, 2: score += 20  // Partly cloudy
        case 3: score += 10  // Cloudy
        case 45, 48: score -= 10  // Fog
        case 71...77, 85, 86: score -= 25  // Snow
        case 51...67, 80...82: score -= 20  // Rain/drizzle
        case 95...99: score -= 30  // Thunderstorm
        default: break
        }
        
        // Wind score
        if weather.current.windSpeed10m < 10 {
            score += 20
        } else if weather.current.windSpeed10m > 25 {
            score -= 15
        }
        
        // Humidity score (ideal: 30-60%)
        let humidity = weather.current.relativeHumidity2m
        if humidity >= 30 && humidity <= 60 {
            score += 10
        } else if humidity > 80 {
            score -= 10
        }
        
        return score
    }
    
    private func bestWeatherReason(_ weather: WeatherData) -> String {
        let temp = weather.current.temperature2m
        let reasons = [
            weather.current.weatherCode == 0 ? "Clear skies" : nil,
            (65...75).contains(Int(temp)) ? "Perfect temperature" : nil,
            weather.current.windSpeed10m < 10 ? "Calm winds" : nil,
            (30...60).contains(weather.current.relativeHumidity2m) ? "Comfortable humidity" : nil
        ].compactMap { $0 }
        
        return reasons.isEmpty ? "Most favorable conditions" : reasons.joined(separator: " • ")
    }
}

struct ComparisonCard: View {
    let location: SavedLocation
    let weather: WeatherData
    let settings: SettingsManager
    
    private var condition: WeatherCondition {
        WeatherCondition(code: weather.current.weatherCode)
    }
    
    private var todayHigh: Double {
        weather.daily.temperature2mMax.first ?? 0
    }
    
    private var todayLow: Double {
        weather.daily.temperature2mMin.first ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline.weight(.semibold))
                    
                    Text(condition.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: condition.symbolName)
                    .font(.largeTitle)
                    .symbolRenderingMode(.multicolor)
            }
            
            // Temperature
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(settings.formatTemperature(weather.current.temperature2m))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                
                Text("feels like \(settings.formatTemperature(weather.current.apparentTemperature))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
            
            Divider()
            
            // Details Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DetailItem(icon: "drop.fill", label: "Humidity", value: "\(weather.current.relativeHumidity2m)%", color: .blue)
                DetailItem(icon: "wind", label: "Wind", value: settings.formatWindSpeed(weather.current.windSpeed10m), color: .gray)
                DetailItem(icon: "eye.fill", label: "Visibility", value: String(format: "%.1f mi", weather.current.visibility / WeatherAccessibility.metersPerMile), color: .cyan)
                DetailItem(icon: "barometer", label: "Pressure", value: String(format: "%.0f mb", weather.current.pressure), color: .purple)
            }
            
            // High/Low
            HStack {
                Label("High: \(settings.formatTemperature(todayHigh))", systemImage: "arrow.up")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
                
                Spacer()
                
                Label("Low: \(settings.formatTemperature(todayLow))", systemImage: "arrow.down")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
            }
            
            Spacer()
        }
    }
}

#Preview {
    WeatherComparisonView()
        .modelContainer(for: SavedLocation.self, inMemory: true)
}
