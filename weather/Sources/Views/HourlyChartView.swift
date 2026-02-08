//
//  HourlyChartView.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI
import Charts

// MARK: - Hourly Chart View

struct HourlyChartView: View {
    let weatherData: WeatherData
    @Environment(SettingsManager.self) private var settings
    
    @State private var selectedChart: ChartType = .temperature
    @State private var selectedDataPoint: HourlyDataPoint?
    @State private var cachedDataPoints: [HourlyDataPoint] = []
    @State private var cachedMinTemp: Double = 0
    @State private var cachedMaxTemp: Double = 100
    @State private var cachedMaxPrecipitation: Int = 0
    @State private var cachedMaxWind: Double = 0
    
    // Static date formatter to avoid creating new ones repeatedly
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Chart type selector
                    chartTypePicker
                    
                    // Main chart
                    chartContent
                        .frame(height: 250)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Data summary
                    dataSummaryCard
                    
                    // Hourly breakdown list
                    hourlyBreakdownList
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Hourly Forecast")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Pre-compute data points and stats once
                if cachedDataPoints.isEmpty {
                    cachedDataPoints = computeHourlyDataPoints()
                    cachedMinTemp = cachedDataPoints.map(\.temperature).min() ?? 0
                    cachedMaxTemp = cachedDataPoints.map(\.temperature).max() ?? 100
                    cachedMaxPrecipitation = cachedDataPoints.map(\.precipitationProbability).max() ?? 0
                    cachedMaxWind = cachedDataPoints.map(\.windSpeed).max() ?? 0
                }
            }
        }
    }
    
    // MARK: - Chart Type Picker
    
    private var chartTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartType.allCases) { type in
                    ChartTypeButton(
                        type: type,
                        isSelected: selectedChart == type,
                        action: { selectedChart = type }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Chart Content
    
    @ViewBuilder
    private var chartContent: some View {
        switch selectedChart {
        case .temperature:
            temperatureChart
        case .precipitation:
            precipitationChart
        case .wind:
            windChart
        case .humidity:
            humidityChart
        }
    }
    
    // MARK: - Temperature Chart
    
    private var temperatureChart: some View {
        Chart(hourlyDataPoints) { point in
            // Area gradient
            AreaMark(
                x: .value("Time", point.date),
                yStart: .value("Min", minTemp - 5),
                yEnd: .value("Temp", point.temperature)
            )
            .foregroundStyle(temperatureGradient)
            .interpolationMethod(.catmullRom)
            
            // Line
            LineMark(
                x: .value("Time", point.date),
                y: .value("Temp", point.temperature)
            )
            .foregroundStyle(.white)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
            
            // Points - only show on selection
            if selectedDataPoint?.id == point.id {
                PointMark(
                    x: .value("Time", point.date),
                    y: .value("Temp", point.temperature)
                )
                .foregroundStyle(.white)
                .symbolSize(80)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.hour())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let temp = value.as(Double.self) {
                        Text("\(Int(temp))°")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: (minTemp - 5)...(maxTemp + 5))
        .chartOverlay { proxy in
            chartOverlay(proxy: proxy)
        }
    }
    
    // MARK: - Precipitation Chart
    
    private var precipitationChart: some View {
        Chart(hourlyDataPoints) { point in
            BarMark(
                x: .value("Time", point.date),
                y: .value("Chance", point.precipitationProbability)
            )
            .foregroundStyle(precipitationColor(for: point.precipitationProbability))
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.hour())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisValueLabel {
                    if let prob = value.as(Int.self) {
                        Text("\(prob)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: 0...100)
    }
    
    // MARK: - Wind Chart
    
    private var windChart: some View {
        Chart(hourlyDataPoints) { point in
            // Wind speed line
            LineMark(
                x: .value("Time", point.date),
                y: .value("Speed", point.windSpeed)
            )
            .foregroundStyle(.cyan)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
            
            // Wind gusts (if available)
            if let gusts = point.windGusts {
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Gusts", gusts)
                )
                .foregroundStyle(.orange.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .interpolationMethod(.catmullRom)
            }
            
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.hour())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let speed = value.as(Double.self) {
                        Text("\(Int(speed))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            "Wind Speed": Color.cyan,
            "Gusts": Color.orange
        ])
    }
    
    // MARK: - Humidity Chart
    
    private var humidityChart: some View {
        Chart(hourlyDataPoints) { point in
            AreaMark(
                x: .value("Time", point.date),
                yStart: .value("Min", 0),
                yEnd: .value("Humidity", point.humidity)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue.opacity(0.1), .blue.opacity(0.5)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .interpolationMethod(.catmullRom)
            
            LineMark(
                x: .value("Time", point.date),
                y: .value("Humidity", point.humidity)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.hour())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisValueLabel {
                    if let hum = value.as(Int.self) {
                        Text("\(hum)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: 0...100)
    }
    
    // MARK: - Chart Overlay for Selection
    
    private func chartOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let location = value.location
                            if let date: Date = proxy.value(atX: location.x) {
                                selectedDataPoint = hourlyDataPoints.min { a, b in
                                    abs(a.date.timeIntervalSince(date)) < abs(b.date.timeIntervalSince(date))
                                }
                            }
                        }
                        .onEnded { _ in
                            selectedDataPoint = nil
                        }
                )
        }
    }
    
    // MARK: - Data Summary Card
    
    private var dataSummaryCard: some View {
        HStack(spacing: 20) {
            SummaryItem(
                icon: "thermometer.high",
                title: "High",
                value: "\(Int(maxTemp))°",
                color: .orange
            )
            
            SummaryItem(
                icon: "thermometer.low",
                title: "Low",
                value: "\(Int(minTemp))°",
                color: .blue
            )
            
            SummaryItem(
                icon: "drop.fill",
                title: "Rain",
                value: "\(maxPrecipitation)%",
                color: .cyan
            )
            
            SummaryItem(
                icon: "wind",
                title: "Wind",
                value: "\(Int(maxWind)) mph",
                color: .teal
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Hourly Breakdown List
    
    private var hourlyBreakdownList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hour by Hour")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(hourlyDataPoints.prefix(24)) { point in
                    HourlyRow(point: point)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Computed Properties
    
    private var hourlyDataPoints: [HourlyDataPoint] {
        cachedDataPoints.isEmpty ? computeHourlyDataPoints() : cachedDataPoints
    }
    
    private func computeHourlyDataPoints() -> [HourlyDataPoint] {
        let now = Date()
        var points: [HourlyDataPoint] = []
        
        // Limit to 48 hours max to prevent performance issues
        let maxHours = min(weatherData.hourly.time.count, 48)
        
        for index in 0..<maxHours {
            let timeString = weatherData.hourly.time[index]
            
            // Try parsing with ISO8601 format first, then fallback
            let date: Date?
            if let d = Self.isoFormatter.date(from: timeString + ":00+00:00") {
                date = d
            } else if let d = Self.isoFormatter.date(from: timeString) {
                date = d
            } else {
                date = DateFormatter.hourlyFormatter.date(from: timeString)
            }
            
            guard let parsedDate = date, parsedDate >= now else { continue }
            
            let point = HourlyDataPoint(
                id: index,
                date: parsedDate,
                temperature: weatherData.hourly.temperature2m[safe: index] ?? 0,
                precipitationProbability: (weatherData.hourly.precipitationProbability?[safe: index]) ?? 0,
                windSpeed: (weatherData.hourly.windSpeed10m?[safe: index]) ?? 0,
                windGusts: weatherData.hourly.windGusts10m?[safe: index],
                humidity: (weatherData.hourly.relativeHumidity2m?[safe: index]) ?? 0,
                weatherCode: weatherData.hourly.weatherCode[safe: index] ?? 0
            )
            points.append(point)
        }
        
        return points
    }
    
    private var minTemp: Double {
        cachedMinTemp
    }
    
    private var maxTemp: Double {
        cachedMaxTemp
    }
    
    private var maxPrecipitation: Int {
        cachedMaxPrecipitation
    }
    
    private var maxWind: Double {
        cachedMaxWind
    }
    
    private var temperatureGradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.1), .orange.opacity(0.3)],
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    private func precipitationColor(for probability: Int) -> Color {
        switch probability {
        case 0..<20: return .green.opacity(0.6)
        case 20..<40: return .yellow.opacity(0.7)
        case 40..<60: return .orange.opacity(0.8)
        case 60..<80: return .blue.opacity(0.8)
        default: return .blue
        }
    }
}

// MARK: - Supporting Types

enum ChartType: String, CaseIterable, Identifiable {
    case temperature = "Temperature"
    case precipitation = "Precipitation"
    case wind = "Wind"
    case humidity = "Humidity"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .temperature: return "thermometer.medium"
        case .precipitation: return "cloud.rain"
        case .wind: return "wind"
        case .humidity: return "humidity"
        }
    }
}

struct HourlyDataPoint: Identifiable, Equatable {
    let id: Int
    let date: Date
    let temperature: Double
    let precipitationProbability: Int
    let windSpeed: Double
    let windGusts: Double?
    let humidity: Int
    let weatherCode: Int
}

// MARK: - Chart Type Button

struct ChartTypeButton: View {
    let type: ChartType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                Text(type.rawValue)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color.blue : Color.clear,
                in: Capsule()
            )
            .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

// MARK: - Summary Item

struct SummaryItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Hourly Row

struct HourlyRow: View {
    let point: HourlyDataPoint
    
    private var condition: WeatherCondition {
        WeatherCondition(code: point.weatherCode)
    }
    
    var body: some View {
        HStack {
            // Time
            Text(point.date, format: .dateTime.hour())
                .font(.subheadline)
                .frame(width: 50, alignment: .leading)
            
            // Weather icon
            Image(systemName: condition.symbolName)
                .font(.title3)
                .foregroundStyle(condition.iconColor)
                .frame(width: 30)
            
            // Temperature
            Text("\(Int(point.temperature))°")
                .font(.headline)
                .frame(width: 45, alignment: .trailing)
            
            Spacer()
            
            // Precipitation
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("\(point.precipitationProbability)%")
                    .font(.caption)
            }
            .frame(width: 50)
            
            // Wind
            HStack(spacing: 4) {
                Image(systemName: "wind")
                    .font(.caption)
                    .foregroundStyle(.teal)
                Text("\(Int(point.windSpeed))")
                    .font(.caption)
            }
            .frame(width: 40)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Date Formatter Extension

private extension DateFormatter {
    static let hourlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }()
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    HourlyChartView(weatherData: WeatherData.preview)
        .environment(SettingsManager())
}

// MARK: - Preview Helper

#if DEBUG
private extension WeatherData {
    static var preview: WeatherData {
        // Create sample data for preview
        let json = """
        {
            "latitude": 37.77,
            "longitude": -122.42,
            "timezone": "America/Los_Angeles",
            "current": {
                "time": "2026-02-05T12:00",
                "temperature_2m": 65.0,
                "relative_humidity_2m": 55,
                "apparent_temperature": 63.0,
                "weather_code": 1,
                "wind_speed_10m": 12.0,
                "wind_direction_10m": 225,
                "is_day": 1
            },
            "hourly": {
                "time": ["2026-02-05T12:00", "2026-02-05T13:00", "2026-02-05T14:00"],
                "temperature_2m": [65.0, 67.0, 68.0],
                "weather_code": [1, 2, 2],
                "precipitation_probability": [10, 20, 15],
                "wind_speed_10m": [12.0, 14.0, 11.0],
                "relative_humidity_2m": [55, 52, 50]
            },
            "daily": {
                "time": ["2026-02-05"],
                "weather_code": [1],
                "temperature_2m_max": [70.0],
                "temperature_2m_min": [55.0],
                "sunrise": ["2026-02-05T07:00"],
                "sunset": ["2026-02-05T17:30"],
                "precipitation_probability_max": [20],
                "wind_speed_10m_max": [15.0],
                "wind_gusts_10m_max": [25.0],
                "uv_index_max": [5.0]
            }
        }
        """
        return try! JSONDecoder().decode(WeatherData.self, from: json.data(using: .utf8)!)
    }
}
#endif
