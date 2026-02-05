//
//  WeatherCards.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI
import Charts

// MARK: - Current Weather Card

struct CurrentWeatherCard: View {
    let current: CurrentWeather
    @EnvironmentObject var settings: SimpleSettingsManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Main temperature
            VStack(spacing: 8) {
                Image(systemName: WeatherCondition(code: current.weatherCode).icon)
                    .font(.system(size: 80))
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.variableColor.iterative)
                
                VStack(spacing: 4) {
                    Text(settings.formatTemperature(current.temperature))
                        .font(.system(size: 72, weight: .thin))
                    
                    // Debug indicator - remove this later
                    Text(settings.useCelsius ? "Using Celsius" : "Using Fahrenheit")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(WeatherCondition(code: current.weatherCode).description)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            // Feels like
            if settings.showFeelsLike {
                Text("Feels like \(settings.formatTemperature(current.apparentTemperature))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            // Quick stats
            HStack(spacing: 30) {
                quickStat(icon: "wind", value: settings.formatWindSpeed(current.windSpeed), label: "Wind")
                quickStat(icon: "humidity", value: "\(current.humidity)%", label: "Humidity")
                quickStat(icon: "eye", value: String(format: "%.1f mi", current.visibility / 1609.34), label: "Visibility")
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .glassEffect(.prominent.tint(.blue.opacity(0.2)))
    }
    
    private func quickStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue.gradient)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Hourly Forecast Card with Chart

struct HourlyForecastCard: View {
    let hourly: HourlyWeather
    let timezone: String
    @EnvironmentObject var settings: SimpleSettingsManager
    
    @State private var selectedHour: Int?
    
    private var next24Hours: [(time: String, temp: Double, precipitation: Int, index: Int)] {
        let count = min(24, hourly.time.count)
        return (0..<count).map { index in
            (
                time: hourly.time[index],
                temp: hourly.temperature[index],
                precipitation: hourly.precipitationProbability[index],
                index: index
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Hourly Forecast", systemImage: "clock")
                .font(.headline)
            
            // Temperature Chart
            Chart {
                ForEach(Array(next24Hours.enumerated()), id: \.offset) { _, hour in
                    LineMark(
                        x: .value("Hour", formattedHour(hour.time)),
                        y: .value("Temperature", hour.temp)
                    )
                    .foregroundStyle(.orange.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Hour", formattedHour(hour.time)),
                        y: .value("Temperature", hour.temp)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.orange.opacity(0.3), .orange.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    if let selected = selectedHour, selected == hour.index {
                        RuleMark(x: .value("Hour", formattedHour(hour.time)))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { value in
                    if let stringValue = value.as(String.self) {
                        AxisValueLabel {
                            Text(stringValue)
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let temp = value.as(Double.self) {
                            Text("\(Int(temp))°")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if let hour = findHour(at: location, proxy: proxy, geometry: geometry) {
                                        selectedHour = hour
                                    }
                                }
                                .onEnded { _ in
                                    selectedHour = nil
                                }
                        )
                }
            }
            
            // Selected hour details
            if let selected = selectedHour, selected < next24Hours.count {
                let hour = next24Hours[selected]
                HStack {
                    Text(formattedFullTime(hour.time))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(settings.formatTemperature(hour.temp))
                        .font(.headline)
                    
                    Text("💧 \(hour.precipitation)%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            
            // Precipitation probability chart
            Text("Precipitation Probability")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Chart {
                ForEach(Array(next24Hours.enumerated()), id: \.offset) { _, hour in
                    BarMark(
                        x: .value("Hour", formattedHour(hour.time)),
                        y: .value("Probability", hour.precipitation)
                    )
                    .foregroundStyle(.blue.gradient)
                }
            }
            .frame(height: 100)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let prob = value.as(Int.self) {
                            Text("\(prob)%")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular)
    }
    
    private func findHour(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> Int? {
        let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        let plotWidth = geometry[proxy.plotAreaFrame].width
        let relativePosition = xPosition / plotWidth
        
        let index = Int(relativePosition * Double(next24Hours.count))
        return index >= 0 && index < next24Hours.count ? next24Hours[index].index : nil
    }
    
    private func formattedHour(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: timeString) else {
            return timeString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "ha"
        displayFormatter.timeZone = TimeZone(identifier: timezone)
        
        return displayFormatter.string(from: date)
    }
    
    private func formattedFullTime(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: timeString) else {
            return timeString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        displayFormatter.dateStyle = .none
        displayFormatter.timeZone = TimeZone(identifier: timezone)
        
        return displayFormatter.string(from: date)
    }
}

// MARK: - Daily Forecast Card

struct DailyForecastCard: View {
    let daily: DailyWeather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("14-Day Forecast", systemImage: "calendar")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(Array(daily.time.enumerated()), id: \.offset) { index, day in
                    DailyForecastRow(
                        date: day,
                        weatherCode: daily.weatherCode[index],
                        high: daily.temperatureMax[index],
                        low: daily.temperatureMin[index],
                        precipitation: daily.precipitationProbability[index]
                    )
                }
            }
        }
        .padding(20)
        .glassEffect(.regular)
    }
}

struct DailyForecastRow: View {
    let date: String
    let weatherCode: Int
    let high: Double
    let low: Double
    let precipitation: Int
    @EnvironmentObject var settings: SimpleSettingsManager
    
    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        guard let date = formatter.date(from: date) else {
            return date
        }
        
        let displayFormatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            displayFormatter.dateFormat = "EEEE"
            return displayFormatter.string(from: date)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Text(formattedDate)
                .font(.subheadline)
                .frame(width: 90, alignment: .leading)
            
            Image(systemName: WeatherCondition(code: weatherCode).icon)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .frame(width: 30)
            
            if precipitation > 20 {
                Text("💧 \(precipitation)%")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .frame(width: 50)
            } else {
                Spacer()
                    .frame(width: 50)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(settings.formatTemperature(low))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Temperature range bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.gray.opacity(0.2))
                            .frame(width: geometry.size.width, height: 4)
                        
                        Capsule()
                            .fill(.orange.gradient)
                            .frame(width: geometry.size.width * 0.7, height: 4)
                    }
                }
                .frame(width: 50, height: 4)
                
                Text(settings.formatTemperature(high))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sun & Moon Card

struct SunMoonCard: View {
    let daily: DailyWeather
    let isDay: Bool
    let timezone: String
    
    private var sunrise: String {
        guard let first = daily.sunrise.first else { return "N/A" }
        return formatTime(first)
    }
    
    private var sunset: String {
        guard let first = daily.sunset.first else { return "N/A" }
        return formatTime(first)
    }
    
    private func formatTime(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: timeString) else {
            return timeString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"
        displayFormatter.timeZone = TimeZone(identifier: timezone)
        
        return displayFormatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 40) {
            VStack(spacing: 12) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 40))
                    .symbolRenderingMode(.multicolor)
                
                Text("Sunrise")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(sunrise)
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 80)
            
            VStack(spacing: 12) {
                Image(systemName: "sunset.fill")
                    .font(.system(size: 40))
                    .symbolRenderingMode(.multicolor)
                
                Text("Sunset")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(sunset)
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .glassEffect(.regular)
    }
}

// MARK: - Weather Details Card

struct WeatherDetailsCard: View {
    let current: CurrentWeather
    @EnvironmentObject var settings: SimpleSettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Details", systemImage: "list.bullet")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                detailItem(icon: "thermometer", label: "Feels Like", value: settings.formatTemperature(current.apparentTemperature))
                detailItem(icon: "humidity", label: "Humidity", value: "\(current.humidity)%")
                detailItem(icon: "wind", label: "Wind Speed", value: settings.formatWindSpeed(current.windSpeed))
                detailItem(icon: "gauge", label: "Pressure", value: String(format: "%.1f mb", current.pressure))
                detailItem(icon: "eye", label: "Visibility", value: String(format: "%.1f mi", current.visibility / 1609.34))
                detailItem(icon: "sun.max", label: "UV Index", value: String(format: "%.0f", current.uvIndex))
                detailItem(icon: "cloud", label: "Cloud Cover", value: "\(current.cloudCover)%")
                detailItem(icon: "drop", label: "Precipitation", value: settings.formatPrecipitation(current.precipitation))
            }
        }
        .padding(20)
        .glassEffect(.regular)
    }
    
    private func detailItem(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue.gradient)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Location Header

struct LocationHeader: View {
    let locationName: String?
    let onSearchTapped: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.subheadline)
                        .foregroundStyle(.blue.gradient)
                    
                    Text(locationName ?? "Unknown Location")
                        .font(.title2.bold())
                }
                
                Text("Updated \(formattedUpdateTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: onSearchTapped) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue.gradient)
                    .frame(width: 44, height: 44)
                    .background(.secondary.opacity(0.2), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(.regular)
    }
    
    private var formattedUpdateTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
