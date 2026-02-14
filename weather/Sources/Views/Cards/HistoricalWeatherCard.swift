//
//  HistoricalWeatherCard.swift
//  weather
//
//  Created by AI Assistant on 2/14/26.
//

import SwiftUI
import Charts

// MARK: - Historical Weather Comparison Card

/// Shows comparison between current weather and same date last year
struct HistoricalWeatherCard: View {
    let currentWeather: CurrentWeather
    let currentDaily: DailyWeather
    let latitude: Double
    let longitude: Double
    
    @State private var historicalData: HistoricalWeatherData?
    @State private var isLoading = false
    @State private var error: String?
    @Environment(SettingsManager.self) var settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Time Last Year")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let comparison = weatherComparison {
                VStack(spacing: 16) {
                    // Temperature Comparison
                    comparisonRow(
                        title: "Temperature",
                        currentValue: settings.formatTemperature(comparison.currentTemp),
                        historicalValue: settings.formatTemperature(comparison.historicalTemp),
                        difference: comparison.comparisonText,
                        icon: "thermometer.medium",
                        color: comparison.isCooler ? .blue : .orange
                    )
                    
                    Divider()
                    
                    // Weather Condition Comparison
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: comparison.currentCondition.symbolName)
                                    .font(.title2)
                                    .symbolRenderingMode(.multicolor)
                                Text(comparison.currentCondition.description)
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Last Year")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text(comparison.historicalCondition.description)
                                    .font(.subheadline.weight(.medium))
                                Image(systemName: comparison.historicalCondition.symbolName)
                                    .font(.title2)
                                    .symbolRenderingMode(.multicolor)
                            }
                        }
                    }
                    
                    // Temperature Trend Chart
                    if let historical = historicalData?.daily,
                       historical.time.count >= 7 {
                        temperatureTrendChart(historical: historical)
                    }
                }
            } else if let error = error {
                HistoryErrorView(message: error) {
                    await loadHistoricalData()
                }
            } else {
                Text("Loading historical weather data...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
        .task {
            await loadHistoricalData()
        }
    }
    
    // MARK: - Comparison Row
    
    private func comparisonRow(
        title: String,
        currentValue: String,
        historicalValue: String,
        difference: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(difference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Now: \(currentValue)")
                    .font(.subheadline.weight(.medium))
                Text("Then: \(historicalValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Temperature Trend Chart
    
    private func temperatureTrendChart(historical: HistoricalDailyWeather) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Comparison")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Chart {
                // Today's temperature
                PointMark(
                    x: .value("Day", 0),
                    y: .value("Temp", currentWeather.temperature2m)
                )
                .foregroundStyle(.orange)
                .symbolSize(80)
                .annotation(position: .top) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                
                // Historical temperatures (last 7 days of data)
                ForEach(historical.time.suffix(7).indices, id: \.self) { index in
                    let actualIndex = historical.time.count - 7 + index
                    if actualIndex >= 0 && actualIndex < historical.temperature2mMax.count {
                        let avgTemp = (historical.temperature2mMax[actualIndex] + historical.temperature2mMin[actualIndex]) / 2
                        PointMark(
                            x: .value("Day", index + 1),
                            y: .value("Temp", avgTemp)
                        )
                        .foregroundStyle(.blue.opacity(0.6))
                    }
                }
            }
            .frame(height: 100)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
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
    }
    
    // MARK: - Computed Properties
    
    private var weatherComparison: WeatherComparison? {
        guard let historical = historicalData?.daily,
              !historical.time.isEmpty,
              !historical.temperature2mMax.isEmpty,
              !historical.temperature2mMin.isEmpty else {
            return nil
        }
        
        // Use the first day from historical data (should be exactly one year ago)
        let historicalTemp = (historical.temperature2mMax[0] + historical.temperature2mMin[0]) / 2
        let historicalCondition = WeatherCondition(code: historical.weatherCode[0])
        let currentCondition = WeatherCondition(code: currentDaily.weatherCode[0])
        
        return WeatherComparison(
            date: Date(),
            currentTemp: currentWeather.temperature2m,
            historicalTemp: historicalTemp,
            difference: currentWeather.temperature2m - historicalTemp,
            currentCondition: currentCondition,
            historicalCondition: historicalCondition,
            currentPrecipitation: 0,
            historicalPrecipitation: historical.precipitationSum[0] ?? 0
        )
    }
    
    // MARK: - Data Loading
    
    private func loadHistoricalData() async {
        isLoading = true
        error = nil
        
        do {
            // Get the date one year ago (same day)
            let calendar = Calendar.current
            guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) else {
                error = "Unable to calculate historical date"
                isLoading = false
                return
            }
            
            // Fetch 7 days of historical data centered around this date
            guard let startDate = calendar.date(byAdding: .day, value: -3, to: oneYearAgo),
                  let endDate = calendar.date(byAdding: .day, value: 3, to: oneYearAgo) else {
                error = "Unable to calculate date range"
                isLoading = false
                return
            }
            
            let data = try await WeatherService.fetchHistoricalWeather(
                latitude: latitude,
                longitude: longitude,
                startDate: startDate,
                endDate: endDate
            )
            
            await MainActor.run {
                self.historicalData = data
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Unable to load historical data"
                self.isLoading = false
            }
        }
    }
}

// MARK: - History Error View

private struct HistoryErrorView: View {
    let message: String
    let retry: () async -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await retry()
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.blue)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
}
