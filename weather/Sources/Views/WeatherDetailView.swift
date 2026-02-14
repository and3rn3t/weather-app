//
//  WeatherDetailView.swift
//  weather
//
//  Created by Matt on 2/4/26.
//
//  Main weather detail screen. Card components are in Views/Cards/.
//

import SwiftUI
import Charts
import CoreLocation

struct WeatherDetailView: View {
    let weatherData: WeatherData
    let locationName: String?
    let onRefresh: () async -> Void
    let onSearchTapped: () -> Void
    let onShareCardTapped: () -> Void
    let airQualityData: AirQualityData?
    
    @Namespace private var glassNamespace
    var settings: SettingsManager
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var showMoreDetails = false
    @State private var showMeshGradient = false
    
    var body: some View {
        ZStack {
            // Weather background
            weatherBackground
            
            ScrollView {
                VStack(spacing: 16) {
                    // Location Header with search button
                    LocationHeader(
                        locationName: locationName,
                        weatherData: weatherData,
                        onSearchTapped: onSearchTapped,
                        onShareCardTapped: onShareCardTapped
                    )
                        .environment(settings)
                    
                    // Current Weather - Prominent card
                    CurrentWeatherCard(
                        current: weatherData.current,
                        todayHigh: weatherData.daily.temperature2mMax.first,
                        todayLow: weatherData.daily.temperature2mMin.first
                    )
                        .environment(settings)
                    
                    // Weather Recommendations - Smart suggestions
                    WeatherRecommendationsCard(
                        current: weatherData.current,
                        hourly: weatherData.hourly
                    )
                    
                    // Sun & Moon Info
                    SunMoonCard(
                        daily: weatherData.daily,
                        isDay: weatherData.current.isDay == 1,
                        timezone: weatherData.timezone
                    )
                    
                    // MARK: - Forecast Section
                    SectionLabel(title: "Forecast", icon: "calendar")
                    
                    // Hourly Forecast with interactive chart
                    HourlyForecastCard(hourly: weatherData.hourly, timezone: weatherData.timezone)
                        .environment(settings)
                    
                    // Daily Forecast
                    DailyForecastCard(daily: weatherData.daily)
                        .environment(settings)
                    
                    // MARK: - More Details (Collapsible)
                    MoreDetailsSection(
                        isExpanded: $showMoreDetails,
                        weatherData: weatherData,
                        airQualityData: airQualityData,
                        settings: settings
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .refreshable {
                await onRefresh()
            }
        }
    }
    
    private var weatherBackground: some View {
        let theme = themeManager.adaptiveTheme(
            for: weatherData.current.weatherCode,
            isDay: weatherData.current.isDay == 1
        )
        return ZStack {
            // Base gradient — uses theme colors
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle mesh gradient overlay for depth — deferred to avoid blocking first frame
            if showMeshGradient && settings.showAnimatedBackgrounds {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: meshColors(for: theme)
                )
                .opacity(0.3)
                .transition(.opacity)
            }
            
            // Weather particle effects — deferred to avoid blocking first frame
            if showMeshGradient && settings.showWeatherParticles {
                WeatherParticleContainer(
                    weatherCode: weatherData.current.weatherCode,
                    isDay: weatherData.current.isDay == 1
                )
            }
        }
        .ignoresSafeArea()
        .task {
            // Defer heavy visual effects until after the first frame is on screen
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeIn(duration: 0.4)) {
                showMeshGradient = true
            }
        }
    }
    
    private func meshColors(for theme: AppTheme) -> [Color] {
        let base = theme.gradientColors
        guard base.count >= 2 else {
            return Array(repeating: Color.blue, count: 9)
        }
        return [
            base[0], base[0].opacity(0.8), base.count > 2 ? base[2] : base[1],
            base[0].opacity(0.9), base[1].opacity(0.7), base[1].opacity(0.9),
            base[1], base[1].opacity(0.8), base[0]
        ]
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(1.2)
            
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 0.5)
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }
}

// MARK: - Collapsible More Details Section

struct MoreDetailsSection: View {
    @Binding var isExpanded: Bool
    let weatherData: WeatherData
    let airQualityData: AirQualityData?
    var settings: SettingsManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Expand/collapse button
            Button {
                HapticFeedback.impact()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(isExpanded ? "Less" : "More Details")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse details" : "Show more details")
            .accessibilityHint("Shows wind, air quality, historical weather, and current conditions")
            
            // Expanded cards
            if isExpanded {
                VStack(spacing: 16) {
                    // Wind Compass
                    WindCompassCard(current: weatherData.current)
                        .environment(settings)
                    
                    // Air Quality Index
                    AirQualityCard(airQualityData: airQualityData)
                    
                    // Historical Weather Comparison (This Time Last Year)
                    HistoricalWeatherCard(
                        currentWeather: weatherData.current,
                        currentDaily: weatherData.daily,
                        latitude: weatherData.latitude,
                        longitude: weatherData.longitude
                    )
                        .environment(settings)
                    
                    // Pollen & Allergy Forecast
                    PollenForecastCard(
                        latitude: weatherData.latitude,
                        longitude: weatherData.longitude
                    )
                    
                    // Additional Details
                    WeatherDetailsCard(current: weatherData.current)
                        .environment(settings)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
            }
        }
    }
}
