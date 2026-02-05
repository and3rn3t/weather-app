//
//  WeatherDetailView.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import SwiftUI
import Charts

struct WeatherDetailView: View {
    let weatherData: WeatherData
    let locationName: String?
    let onRefresh: () async -> Void
    let onSearchTapped: () -> Void
    
    @Namespace private var glassNamespace
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location Header with search button
                LocationHeader(
                    locationName: locationName,
                    onSearchTapped: onSearchTapped
                )
                
                // Current Weather - Prominent card
                CurrentWeatherCard(current: weatherData.current)
                
                // Use GlassEffectContainer for grouped cards
                GlassEffectContainer(spacing: 30.0) {
                    VStack(spacing: 20) {
                        // Sun & Moon Info
                        SunMoonCard(
                            daily: weatherData.daily,
                            isDay: weatherData.current.isDay == 1,
                            timezone: weatherData.timezone
                        )
                        
                        // Hourly Forecast
                        HourlyForecastCard(hourly: weatherData.hourly, timezone: weatherData.timezone)
                        
                        // Daily Forecast
                        DailyForecastCard(daily: weatherData.daily)
                        
                        // Additional Details
                        WeatherDetailsCard(current: weatherData.current)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await onRefresh()
        }
        .background(weatherBackground)
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
    
    var body: some View {
        VStack(spacing: 20) {
            let condition = WeatherCondition(code: current.weatherCode)
            
            // Large weather icon with scaling effect
            Image(systemName: condition.symbolName)
                .font(.system(size: 100))
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.bounce, value: current.temperature2m)
            
            // Temperature display
            Text("\(Int(current.temperature2m))°")
                .font(.system(size: 80, weight: .thin, design: .rounded))
                .contentTransition(.numericText())
            
            // Condition description
            Text(condition.description)
                .font(.title2.weight(.medium))
            
            // Feels like temperature
            Text("Feels like \(Int(current.apparentTemperature))°")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
    }
}

struct SunMoonCard: View {
    let daily: DailyWeather
    let isDay: Bool
    let timezone: String
    
    var body: some View {
        VStack(spacing: 20) {
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
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 32) {
                // Sunrise
                VStack(spacing: 10) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(.orange.gradient)
                    
                    Text("Sunrise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    if let sunrise = daily.sunrise.first {
                        Text(formatTime(sunrise, timezone: timezone))
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    } else {
                        Text("--:--")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 70)
                
                // Sunset
                VStack(spacing: 10) {
                    Image(systemName: "sunset.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(.orange.gradient)
                    
                    Text("Sunset")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    if let sunset = daily.sunset.first {
                        Text(formatTime(sunset, timezone: timezone))
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    } else {
                        Text("--:--")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Day length
            if let sunrise = daily.sunrise.first,
               let sunset = daily.sunset.first,
               let dayLength = calculateDayLength(sunrise: sunrise, sunset: sunset) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Daylight: \(dayLength)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
    
    private var timezoneAbbreviation: String {
        guard let timeZone = TimeZone(identifier: timezone) else {
            return timezone
        }
        return timeZone.abbreviation() ?? timezone
    }
    
    private func formatTime(_ isoString: String, timezone: String) -> String {
        // OpenMeteo returns sunrise/sunset in simple format: "2026-02-04T07:10"
        // This is in the location's local time (already adjusted)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        // Important: Set the timezone to match the location
        if let timeZone = TimeZone(identifier: timezone) {
            dateFormatter.timeZone = timeZone
        }
        
        guard let date = dateFormatter.date(from: isoString) else {
            return "N/A"
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.timeZone = dateFormatter.timeZone // Use same timezone
        
        return timeFormatter.string(from: date)
    }
    
    private func calculateDayLength(sunrise: String, sunset: String) -> String? {
        let formatter = ISO8601DateFormatter()
        guard let sunriseDate = formatter.date(from: sunrise),
              let sunsetDate = formatter.date(from: sunset) else { return nil }
        
        let interval = sunsetDate.timeIntervalSince(sunriseDate)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return "\(hours)h \(minutes)m"
    }
}

struct HourlyForecastCard: View {
    let hourly: HourlyWeather
    let timezone: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hourly Forecast")
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(Array(hourly.time.prefix(24).enumerated()), id: \.offset) { index, time in
                        HourlyWeatherItem(
                            time: time,
                            temperature: hourly.temperature2m[index],
                            weatherCode: hourly.weatherCode[index],
                            timezone: timezone
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

struct HourlyWeatherItem: View {
    let time: String
    let temperature: Double
    let weatherCode: Int
    let timezone: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(formattedTime)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            Image(systemName: WeatherCondition(code: weatherCode).symbolName)
                .font(.title2)
                .symbolRenderingMode(.multicolor)
                .frame(height: 32)
            
            Text("\(Int(temperature))°")
                .font(.body.weight(.semibold))
                .monospacedDigit()
        }
        .frame(width: 60)
    }
    
    private var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: time) else { return "" }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "ha"
        
        // Set the timezone to the location's timezone
        if let timeZone = TimeZone(identifier: timezone) {
            timeFormatter.timeZone = timeZone
        }
        
        return timeFormatter.string(from: date)
    }
}

struct DailyForecastCard: View {
    let daily: DailyWeather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7-Day Forecast")
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(Array(daily.time.enumerated()), id: \.offset) { index, time in
                    DailyWeatherRow(
                        date: time,
                        weatherCode: daily.weatherCode[index],
                        high: daily.temperature2mMax[index],
                        low: daily.temperature2mMin[index],
                        precipProbability: daily.precipitationProbabilityMax[index],
                        uvIndex: daily.uvIndexMax[index],
                        windSpeed: daily.windSpeed10mMax[index]
                    )
                    
                    if index < daily.time.count - 1 {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
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
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                Text(formattedDate)
                    .frame(width: 60, alignment: .leading)
                    .font(.body.weight(.medium))
                
                Image(systemName: WeatherCondition(code: weatherCode).symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.title3)
                    .frame(width: 36)
                
                if precipProbability > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "drop.fill")
                            .font(.caption)
                        Text("\(precipProbability)%")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.blue)
                    .frame(width: 50)
                } else {
                    Spacer()
                        .frame(width: 50)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Text("\(Int(low))°")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    
                    Text("\(Int(high))°")
                        .frame(width: 42, alignment: .trailing)
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 20)
            
            // Additional info row with modern capsule design
            HStack(spacing: 12) {
                Spacer()
                    .frame(width: 60)
                
                HStack(spacing: 5) {
                    Image(systemName: "wind")
                        .font(.caption2)
                    Text("\(Int(windSpeed)) mph")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(.secondary)
                
                HStack(spacing: 5) {
                    Image(systemName: "sun.max.fill")
                        .font(.caption2)
                    Text("UV \(Int(uvIndex))")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(uvColor.opacity(0.2), in: Capsule())
                .foregroundStyle(uvColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 6)
    }
    
    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: date) else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date)
    }
    
    private var uvColor: Color {
        switch uvIndex {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
    }
}

struct WeatherDetailsCard: View {
    let current: CurrentWeather
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Current Conditions")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            // First Row: Wind & Humidity
            HStack(spacing: 16) {
                WeatherDetailItem(
                    title: "Wind Speed",
                    value: "\(Int(current.windSpeed10m))",
                    unit: "mph",
                    subtitle: windDirection,
                    icon: "wind",
                    color: .cyan
                )
                
                Divider()
                    .frame(height: 60)
                
                WeatherDetailItem(
                    title: "Humidity",
                    value: "\(current.relativeHumidity2m)",
                    unit: "%",
                    icon: "humidity.fill",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 60)
                
                WeatherDetailItem(
                    title: "Gusts",
                    value: "\(Int(current.windGusts10m))",
                    unit: "mph",
                    icon: "tornado",
                    color: .cyan
                )
            }
            .padding(.horizontal, 12)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Second Row: UV Index, Visibility, Pressure
            HStack(spacing: 16) {
                WeatherDetailItem(
                    title: "UV Index",
                    value: String(format: "%.1f", current.uvIndex),
                    subtitle: uvCategory,
                    icon: "sun.max.fill",
                    color: uvColor
                )
                
                Divider()
                    .frame(height: 60)
                
                WeatherDetailItem(
                    title: "Visibility",
                    value: String(format: "%.1f", current.visibility / 1609.34),
                    unit: "mi",
                    icon: "eye.fill",
                    color: .purple
                )
                
                Divider()
                    .frame(height: 60)
                
                WeatherDetailItem(
                    title: "Pressure",
                    value: String(format: "%.0f", current.pressure),
                    unit: "hPa",
                    icon: "gauge.with.needle.fill",
                    color: .orange
                )
            }
            .padding(.horizontal, 12)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Third Row: Cloud Cover, Dew Point, Precipitation
            HStack(spacing: 16) {
                WeatherDetailItem(
                    title: "Cloud Cover",
                    value: "\(current.cloudCover)",
                    unit: "%",
                    icon: "cloud.fill",
                    color: .gray
                )
                
                Divider()
                    .frame(height: 60)
                
                WeatherDetailItem(
                    title: "Dew Point",
                    value: "\(Int(current.dewPoint2m))",
                    unit: "°",
                    icon: "drop.fill",
                    color: .teal
                )
                
                Divider()
                    .frame(height: 60)
                
                WeatherDetailItem(
                    title: "Precip",
                    value: String(format: "%.2f", current.precipitation),
                    unit: "in",
                    icon: "cloud.rain.fill",
                    color: .blue
                )
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
    
    private var windDirection: String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((current.windDirection10m + 22.5) / 45.0) % 8
        return directions[index]
    }
    
    private var uvCategory: String {
        switch current.uvIndex {
        case 0..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
        }
    }
    
    private var uvColor: Color {
        switch current.uvIndex {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
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
    let onSearchTapped: () -> Void
    
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
            
            // Search button
            Button(action: onSearchTapped) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue.gradient)
                    .frame(width: 44, height: 44)
                    .background(.secondary.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}


