//
//  WeatherWidget.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Widget Timeline Entry

struct WeatherEntry: TimelineEntry {
    let date: Date
    let weatherData: WeatherData?
    let locationName: String?
    let configuration: WeatherWidgetIntent
}

// MARK: - Widget Intent

struct WeatherWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Weather Location"
    static let description = IntentDescription("Choose a location for weather updates")
    
    @Parameter(title: "Location")
    var location: LocationEntity?
}

struct LocationEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Location")
    static let defaultQuery = LocationQuery()
    
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct LocationQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [LocationEntity] {
        // Return saved locations from SwiftData
        return []
    }
    
    func suggestedEntities() async throws -> [LocationEntity] {
        // Return user's favorite locations
        return []
    }
}

// MARK: - Widget Timeline Provider

struct WeatherTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(
            date: Date(),
            weatherData: nil,
            locationName: "San Francisco",
            configuration: WeatherWidgetIntent()
        )
    }
    
    func snapshot(for configuration: WeatherWidgetIntent, in context: Context) async -> WeatherEntry {
        WeatherEntry(
            date: Date(),
            weatherData: nil,
            locationName: configuration.location?.name ?? "Loading...",
            configuration: configuration
        )
    }
    
    func timeline(for configuration: WeatherWidgetIntent, in context: Context) async -> Timeline<WeatherEntry> {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        
        // Fetch weather data
        var weatherData: WeatherData?
        if let location = configuration.location {
            let service = WeatherService()
            await service.fetchWeather(latitude: location.latitude, longitude: location.longitude)
            weatherData = service.weatherData
        }
        
        let entry = WeatherEntry(
            date: currentDate,
            weatherData: weatherData,
            locationName: configuration.location?.name,
            configuration: configuration
        )
        
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

// MARK: - Widget Views

struct SmallWeatherWidgetView: View {
    let entry: WeatherEntry
    
    var body: some View {
        if let weather = entry.weatherData {
            VStack(spacing: 8) {
                Text(entry.locationName ?? "Weather")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Image(systemName: WeatherCondition(code: weather.current.weatherCode).symbolName)
                    .font(.system(size: 32))
                    .symbolRenderingMode(.multicolor)
                
                Text("\(Int(weather.current.temperature2m))°")
                    .font(.system(size: 36, weight: .semibold))
                
                Text(WeatherCondition(code: weather.current.weatherCode).description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .containerBackground(for: .widget) {
                backgroundGradient(for: weather.current.weatherCode)
            }
        } else {
            VStack {
                Image(systemName: "cloud.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.hierarchical)
                
                Text("No Data")
                    .font(.caption)
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
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.locationName ?? "Weather")
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: WeatherCondition(code: weather.current.weatherCode).symbolName)
                            .font(.system(size: 48))
                            .symbolRenderingMode(.multicolor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(weather.current.temperature2m))°")
                                .font(.system(size: 48, weight: .semibold))
                            
                            Text(WeatherCondition(code: weather.current.weatherCode).description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "wind")
                            .font(.caption)
                        Text("\(Int(weather.current.windSpeed10m)) mph")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "humidity")
                            .font(.caption)
                        Text("\(weather.current.relativeHumidity2m)%")
                            .font(.caption)
                    }
                    
                    if let high = weather.daily.temperature2mMax.first,
                       let low = weather.daily.temperature2mMin.first {
                        HStack(spacing: 6) {
                            Image(systemName: "thermometer")
                                .font(.caption)
                            Text("H:\(Int(high))° L:\(Int(low))°")
                                .font(.caption)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .containerBackground(for: .widget) {
                backgroundGradient(for: weather.current.weatherCode)
            }
        } else {
            HStack {
                Image(systemName: "cloud.fill")
                    .font(.largeTitle)
                Text("Loading...")
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
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.locationName ?? "Weather")
                            .font(.title2.bold())
                        
                        Text("Updated \(entry.date, style: .time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: WeatherCondition(code: weather.current.weatherCode).symbolName)
                        .font(.system(size: 48))
                        .symbolRenderingMode(.multicolor)
                }
                
                // Current temperature
                HStack(alignment: .top) {
                    Text("\(Int(weather.current.temperature2m))°")
                        .font(.system(size: 56, weight: .semibold))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        if let high = weather.daily.temperature2mMax.first,
                           let low = weather.daily.temperature2mMin.first {
                            Text("H:\(Int(high))° L:\(Int(low))°")
                                .font(.subheadline)
                        }
                        
                        Text(WeatherCondition(code: weather.current.weatherCode).description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                // Hourly forecast
                HStack(spacing: 12) {
                    ForEach(0..<min(5, weather.hourly.time.count), id: \.self) { index in
                        VStack(spacing: 6) {
                            Text(formattedHour(weather.hourly.time[index]))
                                .font(.caption2)
                            
                            Image(systemName: WeatherCondition(code: weather.hourly.weatherCode[index]).symbolName)
                                .font(.body)
                                .symbolRenderingMode(.multicolor)
                            
                            Text("\(Int(weather.hourly.temperature2m[index]))°")
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Spacer()
            }
            .padding()
            .containerBackground(for: .widget) {
                backgroundGradient(for: weather.current.weatherCode)
            }
        } else {
            VStack {
                Image(systemName: "cloud.fill")
                    .font(.largeTitle)
                Text("Loading...")
                    .font(.headline)
            }
            .containerBackground(.ultraThinMaterial, for: .widget)
        }
    }
    
    private func formattedHour(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
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

// MARK: - Widget Configuration

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WeatherWidgetIntent.self, provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("See current weather conditions at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WeatherWidgetView: View {
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

// MARK: - Lock Screen Widget

struct LockScreenWeatherWidget: Widget {
    let kind: String = "LockScreenWeatherWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WeatherWidgetIntent.self, provider: WeatherTimelineProvider()) { entry in
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
                Gauge(value: weather.current.temperature2m, in: 0...100) {
                    Image(systemName: WeatherCondition(code: weather.current.weatherCode).symbolName)
                } currentValueLabel: {
                    Text("\(Int(weather.current.temperature2m))°")
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
                    Image(systemName: WeatherCondition(code: weather.current.weatherCode).symbolName)
                        .font(.title2)
                    
                    Text("\(Int(weather.current.temperature2m))°")
                        .font(.title2.bold())
                }
                
                Text(entry.locationName ?? "Weather")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(WeatherCondition(code: weather.current.weatherCode).description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Loading...")
                    .font(.caption)
            }
        }
    }
    
    private var inlineView: some View {
        if let weather = entry.weatherData {
            Text("\(Int(weather.current.temperature2m))° \(WeatherCondition(code: weather.current.weatherCode).description)")
        } else {
            Text("Loading weather...")
        }
    }
}

// MARK: - Widget Bundle
// Note: To use this widget, create a Widget Extension target in Xcode
// and move this code there. The @main attribute conflicts with the app's entry point.

// @main - Uncomment when moved to Widget Extension target
struct WeatherWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
        LockScreenWeatherWidget()
    }
}
