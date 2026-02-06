//
//  Andernet_Weather_Widget.swift
//  Andernet Weather Widget
//
//  Created by Matt on 2/5/26.
//

import WidgetKit
import SwiftUI

// MARK: - Weather Condition

enum WeatherCondition {
    case clearSky
    case partlyCloudy
    case cloudy
    case foggy
    case drizzle
    case rain
    case snow
    case thunderstorm
    case unknown
    
    init(code: Int) {
        switch code {
        case 0:
            self = .clearSky
        case 1, 2:
            self = .partlyCloudy
        case 3:
            self = .cloudy
        case 45, 48:
            self = .foggy
        case 51, 53, 55:
            self = .drizzle
        case 61, 63, 65, 80, 81, 82:
            self = .rain
        case 71, 73, 75, 77, 85, 86:
            self = .snow
        case 95, 96, 99:
            self = .thunderstorm
        default:
            self = .unknown
        }
    }
    
    var description: String {
        switch self {
        case .clearSky: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .foggy: return "Foggy"
        case .drizzle: return "Drizzle"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .thunderstorm: return "Thunderstorm"
        case .unknown: return "Unknown"
        }
    }
    
    var symbolName: String {
        switch self {
        case .clearSky: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Shared Data Access

enum AppGroup {
    static let identifier = "group.dev.andernet.weather"
    
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

struct SharedWeatherData: Codable {
    let temperature: Double
    let apparentTemperature: Double
    let weatherCode: Int
    let isDay: Int
    let humidity: Int
    let windSpeed: Double
    let highTemp: Double
    let lowTemp: Double
    let locationName: String
    let lastUpdated: Date
    let hourlyForecast: [SharedHourlyData]
}

struct SharedHourlyData: Codable {
    let time: String
    let temperature: Double
    let weatherCode: Int
}

func loadWeatherData() -> SharedWeatherData? {
    guard let sharedDefaults = AppGroup.sharedDefaults,
          let data = sharedDefaults.data(forKey: "sharedWeatherData") else {
        return nil
    }
    
    return try? JSONDecoder().decode(SharedWeatherData.self, from: data)
}

// MARK: - Timeline Entry

struct WeatherEntry: TimelineEntry {
    let date: Date
    let weatherData: SharedWeatherData?
}

// MARK: - Timeline Provider

struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), weatherData: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        let entry = WeatherEntry(date: Date(), weatherData: loadWeatherData())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        
        let entry = WeatherEntry(date: currentDate, weatherData: loadWeatherData())
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }
}

// MARK: - Widget Views

struct SmallWeatherWidgetView: View {
    let entry: WeatherEntry
    
    var body: some View {
        if let weather = entry.weatherData {
            VStack(spacing: 6) {
                Text(weather.locationName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Image(systemName: WeatherCondition(code: weather.weatherCode).symbolName)
                    .font(.system(size: 36))
                    .symbolRenderingMode(.multicolor)
                
                Text("\(Int(weather.temperature))°")
                    .font(.system(size: 40, weight: .semibold))
                
                Text(WeatherCondition(code: weather.weatherCode).description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .containerBackground(for: .widget) {
                backgroundGradient(for: weather.weatherCode)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "cloud.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Open App")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .containerBackground(.ultraThinMaterial, for: .widget)
        }
    }
    
    private func backgroundGradient(for code: Int) -> some View {
        let condition = WeatherCondition(code: code)
        let colors: [Color] = {
            switch condition {
            case .clearSky:
                return [.blue, .cyan]
            case .partlyCloudy:
                return [.blue.opacity(0.7), .gray.opacity(0.5)]
            case .cloudy:
                return [.gray, .gray.opacity(0.6)]
            case .rain, .drizzle:
                return [.blue.opacity(0.8), .gray]
            case .snow:
                return [.cyan.opacity(0.3), .white.opacity(0.5)]
            case .thunderstorm:
                return [.indigo, .gray]
            default:
                return [.blue, .cyan]
            }
        }()
        
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct MediumWeatherWidgetView: View {
    let entry: WeatherEntry
    
    var body: some View {
        if let weather = entry.weatherData {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(weather.locationName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: WeatherCondition(code: weather.weatherCode).symbolName)
                            .font(.system(size: 44))
                            .symbolRenderingMode(.multicolor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(weather.temperature))°")
                                .font(.system(size: 44, weight: .semibold))
                            
                            Text(WeatherCondition(code: weather.weatherCode).description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "wind")
                            .font(.caption2)
                        Text("\(Int(weather.windSpeed)) mph")
                            .font(.caption2)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "humidity")
                            .font(.caption2)
                        Text("\(weather.humidity)%")
                            .font(.caption2)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "thermometer")
                            .font(.caption2)
                        Text("H:\(Int(weather.highTemp))° L:\(Int(weather.lowTemp))°")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .containerBackground(for: .widget) {
                backgroundGradient(for: weather.weatherCode)
            }
        } else {
            HStack {
                Image(systemName: "cloud.fill")
                    .font(.largeTitle)
                Text("Open App to Load")
                    .font(.headline)
            }
            .containerBackground(.ultraThinMaterial, for: .widget)
        }
    }
    
    private func backgroundGradient(for code: Int) -> some View {
        let condition = WeatherCondition(code: code)
        let colors: [Color] = {
            switch condition {
            case .clearSky:
                return [.blue, .cyan]
            case .partlyCloudy:
                return [.blue.opacity(0.7), .gray.opacity(0.5)]
            case .cloudy:
                return [.gray, .gray.opacity(0.6)]
            case .rain, .drizzle:
                return [.blue.opacity(0.8), .gray]
            case .snow:
                return [.cyan.opacity(0.3), .white.opacity(0.5)]
            case .thunderstorm:
                return [.indigo, .gray]
            default:
                return [.blue, .cyan]
            }
        }()
        
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct LargeWeatherWidgetView: View {
    let entry: WeatherEntry
    
    var body: some View {
        if let weather = entry.weatherData {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weather.locationName)
                            .font(.headline)
                        
                        Text("Updated \(weather.lastUpdated, style: .time)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: WeatherCondition(code: weather.weatherCode).symbolName)
                        .font(.system(size: 40))
                        .symbolRenderingMode(.multicolor)
                }
                
                // Current temperature
                HStack(alignment: .center) {
                    Text("\(Int(weather.temperature))°")
                        .font(.system(size: 52, weight: .semibold))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("H:\(Int(weather.highTemp))° L:\(Int(weather.lowTemp))°")
                            .font(.subheadline)
                        
                        Text(WeatherCondition(code: weather.weatherCode).description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                // Hourly forecast
                HStack(spacing: 0) {
                    ForEach(Array(weather.hourlyForecast.prefix(5).enumerated()), id: \.offset) { _, hourData in
                        VStack(spacing: 4) {
                            Text(formattedHour(hourData.time))
                                .font(.caption2)
                            
                            Image(systemName: WeatherCondition(code: hourData.weatherCode).symbolName)
                                .font(.callout)
                                .symbolRenderingMode(.multicolor)
                            
                            Text("\(Int(hourData.temperature))°")
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding()
            .containerBackground(for: .widget) {
                backgroundGradient(for: weather.weatherCode)
            }
        } else {
            VStack {
                Image(systemName: "cloud.fill")
                    .font(.largeTitle)
                Text("Open App to Load")
                    .font(.headline)
            }
            .containerBackground(.ultraThinMaterial, for: .widget)
        }
    }
    
    private func formattedHour(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        guard let date = formatter.date(from: timeString) else {
            return ""
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "ha"
        return displayFormatter.string(from: date)
    }
    
    private func backgroundGradient(for code: Int) -> some View {
        let condition = WeatherCondition(code: code)
        let colors: [Color] = {
            switch condition {
            case .clearSky:
                return [.blue, .cyan]
            case .partlyCloudy:
                return [.blue.opacity(0.7), .gray.opacity(0.5)]
            case .cloudy:
                return [.gray, .gray.opacity(0.6)]
            case .rain, .drizzle:
                return [.blue.opacity(0.8), .gray]
            case .snow:
                return [.cyan.opacity(0.3), .white.opacity(0.5)]
            case .thunderstorm:
                return [.indigo, .gray]
            default:
                return [.blue, .cyan]
            }
        }()
        
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Main Widget View

struct WeatherWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: WeatherEntry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWeatherWidgetView(entry: entry)
        case .systemMedium:
            MediumWeatherWidgetView(entry: entry)
        case .systemLarge:
            LargeWeatherWidgetView(entry: entry)
        default:
            SmallWeatherWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct Andernet_Weather_Widget: Widget {
    let kind: String = "Andernet_Weather_Widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("See current weather conditions at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Lock Screen Widget

struct LockScreenWeatherWidget: Widget {
    let kind: String = "LockScreenWeatherWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            LockScreenWeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("Quick weather glance")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWeatherWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: WeatherEntry
    
    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }
    
    private var circularView: some View {
        ZStack {
            if let weather = entry.weatherData {
                Gauge(value: weather.temperature, in: 0...120) {
                    Image(systemName: WeatherCondition(code: weather.weatherCode).symbolName)
                } currentValueLabel: {
                    Text("\(Int(weather.temperature))°")
                        .font(.caption2.bold())
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                Image(systemName: "cloud.fill")
                    .font(.title2)
            }
        }
    }
    
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let weather = entry.weatherData {
                HStack(spacing: 6) {
                    Image(systemName: WeatherCondition(code: weather.weatherCode).symbolName)
                        .font(.title2)
                    
                    Text("\(Int(weather.temperature))°")
                        .font(.title2.bold())
                }
                
                Text(weather.locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(WeatherCondition(code: weather.weatherCode).description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Open App")
                    .font(.caption)
            }
        }
    }
    
    private var inlineView: some View {
        if let weather = entry.weatherData {
            Text("\(Int(weather.temperature))° \(WeatherCondition(code: weather.weatherCode).description)")
        } else {
            Text("Weather")
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    Andernet_Weather_Widget()
} timeline: {
    WeatherEntry(date: .now, weatherData: nil)
}
