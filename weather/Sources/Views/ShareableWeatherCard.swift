//
//  ShareableWeatherCard.swift
//  weather
//
//  Created by Matt on 2/7/26.
//

import SwiftUI

// MARK: - Shareable Weather Card Sheet

struct ShareableWeatherCardSheet: View {
    let weatherData: WeatherData
    let locationName: String?
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStyle: CardStyle = .gradient
    @State private var renderedImage: UIImage?
    @State private var isRendering = false
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Style picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card Style")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CardStyle.allCases) { style in
                                    StylePickerItem(
                                        style: style,
                                        isSelected: selectedStyle == style
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedStyle = style
                                        }
                                        HapticFeedback.impact()
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    // Card preview
                    ShareCardContent(
                        weatherData: weatherData,
                        locationName: locationName,
                        style: selectedStyle,
                        settings: settings
                    )
                    .frame(width: 340, height: 440)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    
                    // Share button
                    Button {
                        HapticFeedback.impact()
                        renderAndShare()
                    } label: {
                        HStack(spacing: 8) {
                            if isRendering {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isRendering ? "Rendering…" : "Share Weather Card")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: selectedStyle.accentColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(isRendering)
                    .padding(.horizontal, 20)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Share Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }
    
    // MARK: - Rendering
    
    private func renderAndShare() {
        isRendering = true
        
        // Render on next run loop to show loading state
        Task { @MainActor in
            // Small delay so the loading indicator shows
            try? await Task.sleep(for: .milliseconds(100))
            
            let renderer = ImageRenderer(
                content: ShareCardContent(
                    weatherData: weatherData,
                    locationName: locationName,
                    style: selectedStyle,
                    settings: settings
                )
                .frame(width: 680, height: 880)
            )
            
            renderer.scale = 3.0 // Render at 3x for crisp output
            
            if let image = renderer.uiImage {
                renderedImage = image
                showShareSheet = true
            }
            
            isRendering = false
        }
    }
}

// MARK: - Card Styles

enum CardStyle: String, CaseIterable, Identifiable {
    case gradient
    case dark
    case minimal
    case vibrant
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .gradient: return "Gradient"
        case .dark: return "Dark"
        case .minimal: return "Minimal"
        case .vibrant: return "Vibrant"
        }
    }
    
    var icon: String {
        switch self {
        case .gradient: return "paintpalette.fill"
        case .dark: return "moon.fill"
        case .minimal: return "square.fill"
        case .vibrant: return "sparkles"
        }
    }
    
    var accentColors: [Color] {
        switch self {
        case .gradient: return [.blue, .cyan]
        case .dark: return [Color(white: 0.3), Color(white: 0.5)]
        case .minimal: return [.primary.opacity(0.8), .primary.opacity(0.6)]
        case .vibrant: return [.purple, .pink]
        }
    }
}

// MARK: - Style Picker Item

struct StylePickerItem: View {
    let style: CardStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: style.accentColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: style.icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                )
                
                Text(style.displayName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(style.displayName) card style")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Share Card Content (Rendered to Image)

struct ShareCardContent: View {
    let weatherData: WeatherData
    let locationName: String?
    let style: CardStyle
    let settings: SettingsManager
    
    private var condition: WeatherCondition {
        WeatherCondition(code: weatherData.current.weatherCode)
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundForStyle
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 30)
                
                // Weather icon
                Image(systemName: condition.symbolName)
                    .font(.system(size: 56))
                    .symbolRenderingMode(.multicolor)
                    .padding(.bottom, 8)
                
                // Temperature
                Text(settings.formatTemperature(weatherData.current.temperature2m))
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundStyle(textColor)
                
                // Condition
                Text(condition.description)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(textColor.opacity(0.9))
                    .padding(.bottom, 4)
                
                // Location
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(locationName ?? "Current Location")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(textColor.opacity(0.7))
                .padding(.bottom, 20)
                
                // Divider
                Rectangle()
                    .fill(textColor.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 16)
                
                // Stats grid
                HStack(spacing: 0) {
                    ShareStatItem(
                        icon: "thermometer.medium",
                        label: "Feels Like",
                        value: settings.formatTemperature(weatherData.current.apparentTemperature),
                        textColor: textColor
                    )
                    
                    ShareStatItem(
                        icon: "wind",
                        label: "Wind",
                        value: settings.formatWindSpeed(weatherData.current.windSpeed10m),
                        textColor: textColor
                    )
                    
                    ShareStatItem(
                        icon: "humidity.fill",
                        label: "Humidity",
                        value: "\(weatherData.current.relativeHumidity2m)%",
                        textColor: textColor
                    )
                }
                .padding(.bottom, 12)
                
                // High/Low
                if let high = weatherData.daily.temperature2mMax.first,
                   let low = weatherData.daily.temperature2mMin.first {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.caption2.weight(.bold))
                            Text(settings.formatTemperature(high))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.orange)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.caption2.weight(.bold))
                            Text(settings.formatTemperature(low))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.cyan)
                    }
                    .padding(.bottom, 12)
                }
                
                // Hourly mini forecast (next 5 hours)
                hourlyMiniRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                Spacer()
                
                // Branding
                HStack(spacing: 4) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.caption2)
                    Text("Andernet Weather")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(textColor.opacity(0.4))
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Hourly Mini Row
    
    private var hourlyMiniRow: some View {
        let hourlyTimes = weatherData.hourly.time
        let hourlyTemps = weatherData.hourly.temperature2m
        let hourlyCodes = weatherData.hourly.weatherCode
        
        // Find current hour index
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        // Get next 5 hours starting from current
        let startIndex = min(currentHour + 1, hourlyTimes.count - 5)
        let endIndex = min(startIndex + 5, hourlyTimes.count)
        
        return HStack(spacing: 0) {
            if startIndex < endIndex {
                ForEach(startIndex..<endIndex, id: \.self) { index in
                    VStack(spacing: 6) {
                        Text(SettingsManager.formatHour(hourlyTimes[index], timezone: weatherData.timezone))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(textColor.opacity(0.6))
                        
                        Image(systemName: WeatherCondition(code: hourlyCodes[index]).symbolName)
                            .font(.caption)
                            .symbolRenderingMode(.multicolor)
                        
                        Text(settings.formatTemperature(hourlyTemps[index]))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(textColor)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(textColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Style-based Properties
    
    private var textColor: Color {
        switch style {
        case .gradient, .dark, .vibrant:
            return .white
        case .minimal:
            return .primary
        }
    }
    
    @ViewBuilder
    private var backgroundForStyle: some View {
        switch style {
        case .gradient:
            LinearGradient(
                colors: weatherGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .dark:
            LinearGradient(
                colors: [Color(white: 0.1), Color(white: 0.18), Color(white: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .minimal:
            Color(.systemBackground)
            
        case .vibrant:
            LinearGradient(
                colors: vibrantGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var weatherGradientColors: [Color] {
        switch condition {
        case .clearSky:
            return [Color(red: 0.2, green: 0.5, blue: 0.95), Color(red: 0.4, green: 0.75, blue: 1.0)]
        case .partlyCloudy:
            return [Color(red: 0.3, green: 0.5, blue: 0.8), Color(red: 0.6, green: 0.7, blue: 0.85)]
        case .cloudy:
            return [Color(red: 0.4, green: 0.45, blue: 0.55), Color(red: 0.55, green: 0.6, blue: 0.68)]
        case .rain, .drizzle:
            return [Color(red: 0.2, green: 0.3, blue: 0.55), Color(red: 0.35, green: 0.45, blue: 0.65)]
        case .snow:
            return [Color(red: 0.65, green: 0.75, blue: 0.9), Color(red: 0.5, green: 0.65, blue: 0.85)]
        case .thunderstorm:
            return [Color(red: 0.2, green: 0.15, blue: 0.35), Color(red: 0.35, green: 0.25, blue: 0.5)]
        case .foggy:
            return [Color(red: 0.5, green: 0.55, blue: 0.6), Color(red: 0.65, green: 0.68, blue: 0.72)]
        case .unknown:
            return [Color(red: 0.3, green: 0.5, blue: 0.8), Color(red: 0.5, green: 0.7, blue: 0.9)]
        }
    }
    
    private var vibrantGradientColors: [Color] {
        switch condition {
        case .clearSky:
            return [.orange, .pink, .purple]
        case .partlyCloudy:
            return [.indigo, .blue, .cyan]
        case .cloudy:
            return [.gray, .blue.opacity(0.6), .purple.opacity(0.5)]
        case .rain, .drizzle:
            return [.blue, .indigo, .purple]
        case .snow:
            return [.cyan, .mint, .teal]
        case .thunderstorm:
            return [.purple, .indigo, Color(red: 0.3, green: 0, blue: 0.5)]
        case .foggy:
            return [.gray, .mint.opacity(0.5), .teal.opacity(0.5)]
        case .unknown:
            return [.blue, .purple, .pink]
        }
    }
}

// MARK: - Share Stat Item

struct ShareStatItem: View {
    let icon: String
    let label: String
    let value: String
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(textColor.opacity(0.6))
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(textColor.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - UIKit Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ShareableWeatherCardSheet(
        weatherData: WeatherData(
            latitude: 40.71,
            longitude: -74.01,
            timezone: "America/New_York",
            current: CurrentWeather(
                time: "2026-02-07T12:00",
                temperature2m: 45,
                apparentTemperature: 40,
                weatherCode: 0,
                windSpeed10m: 15.5,
                windDirection10m: 225,
                windGusts10m: 28.3,
                relativeHumidity2m: 65,
                dewPoint2m: 38,
                pressure: 1013,
                cloudCover: 20,
                visibility: 16000,
                uvIndex: 3.0,
                isDay: 1,
                precipitation: 0.0
            ),
            hourly: HourlyWeather(
                time: (0..<24).map { "2026-02-07T\(String(format: "%02d", $0)):00" },
                temperature2m: (0..<24).map { 40 + Double($0) * 0.5 },
                weatherCode: Array(repeating: 0, count: 24),
                precipitationProbability: Array(repeating: 10, count: 24),
                windSpeed10m: Array(repeating: 12.0, count: 24),
                windGusts10m: Array(repeating: 20.0, count: 24),
                relativeHumidity2m: Array(repeating: 65, count: 24),
                uvIndex: Array(repeating: 3.0, count: 24)
            ),
            daily: DailyWeather(
                time: ["2026-02-07"],
                weatherCode: [0],
                temperature2mMax: [52],
                temperature2mMin: [35],
                precipitationProbabilityMax: [10],
                sunrise: ["2026-02-07T07:10"],
                sunset: ["2026-02-07T17:30"],
                uvIndexMax: [3.0],
                windSpeed10mMax: [18.0],
                windGusts10mMax: [30.0]
            )
        ),
        locationName: "New York City"
    )
    .environment(SettingsManager())
}
