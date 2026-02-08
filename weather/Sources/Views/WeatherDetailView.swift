//
//  WeatherDetailView.swift
//  weather
//
//  Created by Matt on 2/4/26.
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
                    
                    // Hourly Forecast with interactive chart
                    HourlyForecastCard(hourly: weatherData.hourly, timezone: weatherData.timezone)
                        .environment(settings)
                    
                    // Daily Forecast
                    DailyForecastCard(daily: weatherData.daily)
                        .environment(settings)
                    
                    // Wind Compass
                    WindCompassCard(current: weatherData.current)
                        .environment(settings)
                    
                    // On This Day - Historical Weather
                    OnThisDayCard(
                        currentWeather: weatherData.current,
                        latitude: weatherData.latitude,
                        longitude: weatherData.longitude
                    )
                        .environment(settings)
                    
                    // Air Quality Index
                    AirQualityCard(airQualityData: airQualityData)
                    
                    // Additional Details
                    WeatherDetailsCard(current: weatherData.current)
                        .environment(settings)
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
        let condition = WeatherCondition(code: weatherData.current.weatherCode)
        return ZStack {
            // Base gradient
            LinearGradient(
                colors: backgroundColors(for: condition),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle mesh gradient overlay for depth (iOS 18+)
            if settings.showAnimatedBackgrounds {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: meshColors(for: condition)
                )
                .opacity(0.3)
            }
            
            // Weather particle effects
            if settings.showWeatherParticles {
                WeatherParticleContainer(
                    weatherCode: weatherData.current.weatherCode,
                    isDay: weatherData.current.isDay == 1
                )
            }
        }
        .ignoresSafeArea()
    }
    
    private func backgroundColors(for condition: WeatherCondition) -> [Color] {
        switch condition {
        case .clearSky:
            return [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.6, green: 0.85, blue: 1.0)]
        case .partlyCloudy:
            return [Color(red: 0.5, green: 0.6, blue: 0.8), Color(red: 0.7, green: 0.75, blue: 0.85)]
        case .cloudy:
            return [Color(red: 0.6, green: 0.65, blue: 0.7), Color(red: 0.75, green: 0.78, blue: 0.82)]
        case .rain, .drizzle:
            return [Color(red: 0.3, green: 0.4, blue: 0.6), Color(red: 0.5, green: 0.6, blue: 0.7)]
        case .snow:
            return [Color(red: 0.85, green: 0.9, blue: 0.95), Color(red: 0.7, green: 0.8, blue: 0.95)]
        case .thunderstorm:
            return [Color(red: 0.3, green: 0.25, blue: 0.4), Color(red: 0.5, green: 0.4, blue: 0.55)]
        default:
            return [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.6, green: 0.85, blue: 1.0)]
        }
    }
    
    private func meshColors(for condition: WeatherCondition) -> [Color] {
        let base = backgroundColors(for: condition)
        return [
            base[0], base[0].opacity(0.8), base[1],
            base[0].opacity(0.9), base[1].opacity(0.7), base[1].opacity(0.9),
            base[1], base[1].opacity(0.8), base[0]
        ]
    }
}

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
                    Text("L:\(settings.formatTemperature(low))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.cyan)
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

struct HourlyForecastCard: View {
    let hourly: HourlyWeather
    let timezone: String
    @State private var selectedHour: Int?
    @State private var showUVIndex = false
    @Environment(SettingsManager.self) var settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Hourly Forecast")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                // Toggle between temperature and UV index
                if hourly.uvIndex != nil {
                    Button {
                        HapticFeedback.impact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showUVIndex.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showUVIndex ? "thermometer" : "sun.max.fill")
                                .font(.caption)
                            Text(showUVIndex ? "Temp" : "UV")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15), in: Capsule())
                    }
                }
                
                // Temperature trend indicator
                if !showUVIndex, let trend = temperatureTrend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text(trend.text)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(trend.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trend.color.opacity(0.15), in: Capsule())
                }
            }
            .padding(.horizontal, 20)
            
            // Interactive Chart
            if showUVIndex {
                UVIndexChart(
                    hourly: hourly,
                    timezone: timezone,
                    selectedHour: $selectedHour
                )
                .frame(height: 200)
                .padding(.horizontal, 16)
            } else {
                TemperatureChart(
                    hourly: hourly,
                    timezone: timezone,
                    selectedHour: $selectedHour
                )
                .frame(height: 200)
                .padding(.horizontal, 16)
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(Array(hourly.time.prefix(24).enumerated()), id: \.offset) { index, time in
                        if showUVIndex, let uvValues = hourly.uvIndex {
                            HourlyUVItem(
                                time: time,
                                uvIndex: uvValues[index] ?? 0,
                                weatherCode: hourly.weatherCode[index],
                                timezone: timezone,
                                isSelected: selectedHour == index
                            )
                            .onTapGesture {
                                HapticFeedback.impact()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedHour = selectedHour == index ? nil : index
                                }
                            }
                        } else {
                            HourlyWeatherItem(
                                time: time,
                                temperature: hourly.temperature2m[index],
                                weatherCode: hourly.weatherCode[index],
                                timezone: timezone,
                                isSelected: selectedHour == index
                            )
                            .onTapGesture {
                                HapticFeedback.impact()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedHour = selectedHour == index ? nil : index
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 16)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private var temperatureTrend: (icon: String, text: String, color: Color)? {
        guard hourly.temperature2m.count >= 6 else { return nil }
        
        let firstThree = hourly.temperature2m.prefix(3).reduce(0, +) / 3
        let nextThree = hourly.temperature2m.dropFirst(3).prefix(3).reduce(0, +) / 3
        let diff = nextThree - firstThree
        
        if diff > 2 {
            return ("arrow.up.right", "Warming", .orange)
        } else if diff < -2 {
            return ("arrow.down.right", "Cooling", .blue)
        } else {
            return ("minus", "Steady", .secondary)
        }
    }
}

struct HourlyWeatherItem: View {
    let time: String
    let temperature: Double
    let weatherCode: Int
    let timezone: String
    var isSelected: Bool = false
    @Environment(SettingsManager.self) var settings
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formattedTime)
                .font(.caption.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
            
            Image(systemName: WeatherCondition(code: weatherCode).symbolName)
                .font(.title2)
                .symbolRenderingMode(.multicolor)
                .frame(height: 28)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .symbolEffect(.bounce, value: isSelected)
            
            Text(settings.formatTemperature(temperature))
                .font(.body.weight(isSelected ? .bold : .semibold))
                .monospacedDigit()
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            isSelected ? Color.blue.opacity(0.15) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var formattedTime: String {
        SettingsManager.formatHour(time, timezone: timezone)
    }
}

struct HourlyUVItem: View {
    let time: String
    let uvIndex: Double
    let weatherCode: Int
    let timezone: String
    var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formattedTime)
                .font(.caption.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
            
            Image(systemName: "sun.max.fill")
                .font(.title2)
                .foregroundStyle(uvColor.gradient)
                .frame(height: 28)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .symbolEffect(.bounce, value: isSelected)
            
            Text(String(format: "%.1f", uvIndex))
                .font(.body.weight(isSelected ? .bold : .semibold))
                .monospacedDigit()
                .foregroundStyle(isSelected ? .primary : .secondary)
            
            Text(uvLevel)
                .font(.caption2.weight(.medium))
                .foregroundStyle(uvColor)
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            isSelected ? uvColor.opacity(0.15) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var formattedTime: String {
        SettingsManager.formatHour(time, timezone: timezone)
    }
    
    private var uvColor: Color {
        UVIndexHelper.color(for: uvIndex)
    }
    
    private var uvLevel: String {
        UVIndexHelper.level(for: uvIndex)
    }
}

struct UVIndexChart: View {
    let hourly: HourlyWeather
    let timezone: String
    @Binding var selectedHour: Int?
    
    var body: some View {
        Chart {
            ForEach(Array(hourly.time.prefix(24).enumerated()), id: \.offset) { index, time in
                if let uvValues = hourly.uvIndex, let uvValue = uvValues[index] {
                    BarMark(
                        x: .value("Time", formattedTime(time)),
                        y: .value("UV Index", uvValue)
                    )
                    .foregroundStyle(uvGradient(for: uvValue))
                    .opacity(selectedHour == nil || selectedHour == index ? 1.0 : 0.3)
                    .annotation(position: .top) {
                        if selectedHour == index {
                            VStack(spacing: 2) {
                                Text(String(format: "%.1f", uvValue))
                                    .font(.caption.bold())
                                    .foregroundStyle(uvColor(for: uvValue))
                                Text(uvLevel(for: uvValue))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 3)) { value in
                AxisValueLabel()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYScale(domain: 0...12)
    }
    
    private func formattedTime(_ time: String) -> String {
        SettingsManager.formatHour(time, timezone: timezone)
    }
    
    private func uvColor(for uv: Double) -> Color {
        UVIndexHelper.color(for: uv)
    }
    
    private func uvGradient(for uv: Double) -> LinearGradient {
        LinearGradient(
            colors: [uvColor(for: uv), uvColor(for: uv).opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func uvLevel(for uv: Double) -> String {
        UVIndexHelper.level(for: uv)
    }
}

struct DailyForecastCard: View {
    let daily: DailyWeather
    @State private var showExtendedForecast = false
    
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
                        windSpeed: daily.windSpeed10mMax[index] ?? 0
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

struct DailyWeatherRow: View {
    let date: String
    let weatherCode: Int
    let high: Double
    let low: Double
    let precipProbability: Int
    let uvIndex: Double
    let windSpeed: Double
    @Environment(SettingsManager.self) var settings
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                // Day name
                Text(formattedDate)
                    .frame(width: 60, alignment: .leading)
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
                    
                    Text(settings.formatTemperature(high))
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }
            }
            .padding(.horizontal, 20)
            
            // Additional info row with modern capsule design
            HStack(spacing: 10) {
                Spacer()
                    .frame(width: 60)
                
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
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WeatherAccessibility.dailyForecastLabel(day: date, high: high, low: low, code: weatherCode) + ". " + WeatherAccessibility.precipitationProbabilityLabel(precipProbability))
    }
    
    private var formattedDate: String {
        SettingsManager.formatDayName(date)
    }
    
    private var uvColor: Color {
        UVIndexHelper.color(for: uvIndex)
    }
}

struct WeatherDetailsCard: View {
    let current: CurrentWeather
    @Environment(SettingsManager.self) private var settings
    
    /// Meters per mile conversion factor
    private static let metersPerMile = 1609.34
    
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
            
            HStack(spacing: 8) {
                // Share button
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue.gradient)
                        .frame(width: 44, height: 44)
                        .background(.secondary.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
                
                // Share weather card button
                if let onShareCardTapped {
                    Button(action: {
                        HapticFeedback.impact()
                        onShareCardTapped()
                    }) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue.gradient)
                            .frame(width: 44, height: 44)
                            .background(.secondary.opacity(0.15), in: Circle())
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
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue.gradient)
                        .frame(width: 44, height: 44)
                        .background(.secondary.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Advanced Features

/// Interactive temperature chart with selection support
struct TemperatureChart: View {
    let hourly: HourlyWeather
    let timezone: String
    @Binding var selectedHour: Int?
    @Environment(SettingsManager.self) var settings
    
    private var chartData: [(hour: String, temp: Double)] {
        Array(zip(hourly.time.prefix(24), hourly.temperature2m.prefix(24)))
            .map { (hour: $0.0, temp: $0.1) }
    }
    
    var body: some View {
        Chart {
            ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                // Area fill
                AreaMark(
                    x: .value("Hour", index),
                    y: .value("Temperature", data.temp)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            temperatureColor(data.temp).opacity(0.3),
                            temperatureColor(data.temp).opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Line
                LineMark(
                    x: .value("Hour", index),
                    y: .value("Temperature", data.temp)
                )
                .foregroundStyle(temperatureColor(data.temp))
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Point marker for selected hour
                if selectedHour == index {
                    PointMark(
                        x: .value("Hour", index),
                        y: .value("Temperature", data.temp)
                    )
                    .foregroundStyle(temperatureColor(data.temp))
                    .symbolSize(100)
                }
            }
            
            // Rule mark for selected temperature
            if let selected = selectedHour,
               selected < chartData.count {
                RuleMark(
                    y: .value("Selected Temp", chartData[selected].temp)
                )
                .foregroundStyle(.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(settings.formatTemperature(chartData[selected].temp))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 3)) { value in
                if let index = value.as(Int.self),
                   index < chartData.count {
                    AxisValueLabel {
                        Text(formatChartTime(chartData[index].hour))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let temp = value.as(Double.self) {
                        Text(settings.formatTemperature(temp))
                            .font(.caption2)
                    }
                }
            }
        }
    }
    
    private func temperatureColor(_ temp: Double) -> Color {
        switch temp {
        case ..<32: return .blue
        case 32..<50: return .cyan
        case 50..<70: return .green
        case 70..<85: return .orange
        default: return .red
        }
    }
    
    private func formatChartTime(_ isoString: String) -> String {
        SettingsManager.formatHour(isoString, timezone: timezone)
    }
}

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

struct Recommendation: Hashable {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Air Quality")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                if let aqi = aqi {
                    Text(aqiCategory(for: aqi).name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(aqiCategory(for: aqi).color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(aqiCategory(for: aqi).color.opacity(0.2), in: Capsule())
                } else {
                    Text("Unavailable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.2), in: Capsule())
                }
            }
            
            if let aqi = aqi, let data = airQualityData?.current {
                HStack(spacing: 20) {
                    // AQI gauge
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: min(CGFloat(aqi) / 200.0, 1.0))
                            .stroke(
                                aqiCategory(for: aqi).color.gradient,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text("\(aqi)")
                                .font(.title.weight(.bold))
                                .foregroundStyle(aqiCategory(for: aqi).color)
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
                
                Text(aqiCategory(for: aqi).description)
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
                                .foregroundStyle(aqiCategory(for: aqi).color)
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



