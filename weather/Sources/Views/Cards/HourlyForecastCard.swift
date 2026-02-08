//
//  HourlyForecastCard.swift
//  weather
//
//  Extracted from WeatherDetailView.swift for modularity.
//

import SwiftUI
import Charts

// MARK: - Hourly Forecast Card

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

// MARK: - Hourly Weather Item

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
                .contentTransition(.numericText())
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

// MARK: - Hourly UV Item

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
                .contentTransition(.numericText())
            
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

// MARK: - UV Index Chart

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

// MARK: - Temperature Chart

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
