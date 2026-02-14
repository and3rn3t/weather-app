//
//  PollenForecastCard.swift
//  weather
//
//  Created by AI Assistant on 2/14/26.
//

import SwiftUI
import Charts

// MARK: - Pollen Forecast Card

/// Shows pollen forecast and allergy information
struct PollenForecastCard: View {
    let latitude: Double
    let longitude: Double
    
    @State private var pollenData: UnifiedPollenData?
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedPollenType: PollenType?
    @State private var dataSource: String = ""
    @Environment(SettingsManager.self) private var settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pollen & Allergies")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !dataSource.isEmpty {
                    Text(dataSource)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let maxPollen = pollenData?.maxPollenInRange(start: 0, count: 24) {
                
                VStack(spacing: 16) {
                    // Current pollen level
                    pollenLevelIndicator(type: maxPollen.type, concentration: maxPollen.value)
                    
                    Divider()
                    
                    // Pollen types breakdown
                    pollenTypesGrid
                    
                    // 7-day pollen trend chart
                    if let selectedType = selectedPollenType {
                        pollenTrendChart(for: selectedType)
                    }
                }
            } else if let error = error {
                pollenErrorView(message: error)
            } else if isLoading {
                Text("Loading pollen forecast...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                pollenUnavailableView
            }
        }
        .padding(20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
        .task {
            await loadPollenData()
        }
    }
    
    // MARK: - Pollen Level Indicator
    
    private func pollenLevelIndicator(type: PollenType, concentration: Double) -> some View {
        let level = PollenLevel(concentration: concentration)
        
        return HStack(spacing: 16) {
            // Icon and type
            VStack {
                Image(systemName: type.icon)
                    .font(.largeTitle)
                    .foregroundStyle(type.color)
                    .frame(width: 60, height: 60)
                    .background(type.color.opacity(0.15), in: Circle())
                
                Text(type.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(level.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(level.color)
                    
                    Text("Pollen")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Text(level.advice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.rawValue) pollen is \(level.name). \(level.advice)")
    }
    
    // MARK: - Pollen Types Grid
    
    private var pollenTypesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(PollenType.allCases, id: \.self) { type in
                pollenTypeButton(type)
            }
        }
    }
    
    private func pollenTypeButton(_ type: PollenType) -> some View {
        let concentration = getCurrentConcentration(for: type)
        let level = PollenLevel(concentration: concentration)
        let isSelected = selectedPollenType == type
        
        return Button {
            HapticFeedback.impact()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPollenType = isSelected ? nil : type
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? type.color : .secondary)
                
                Text(type.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                Text(level.name)
                    .font(.caption2)
                    .foregroundStyle(level.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(level.color.opacity(0.2), in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? type.color.opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? type.color : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Pollen Trend Chart
    
    private func pollenTrendChart(for type: PollenType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(type.rawValue) Pollen - Next 7 Days")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            
            if let data = pollenData {
                Chart {
                    ForEach(0..<min(data.dates.count, 168), id: \.self) { index in
                        if let concentration = getConcentration(for: type, at: index),
                           let date = parseDate(data.dates[index]) {
                            LineMark(
                                x: .value("Time", date),
                                y: .value("Concentration", concentration)
                            )
                            .foregroundStyle(type.color.gradient)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Time", date),
                                y: .value("Concentration", concentration)
                            )
                            .foregroundStyle(type.color.opacity(0.2).gradient)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.weekday(.abbreviated))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel {
                            Text("")
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Error and Unavailable Views
    
    private func pollenErrorView(message: String) -> some View {
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
                    await loadPollenData()
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.blue)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    private var pollenUnavailableView: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.largeTitle)
                .foregroundStyle(.green.opacity(0.6))
            
            Text("Pollen data is currently unavailable for this location")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if isInUS {
                Text("Configure Tomorrow.io API key in Settings for US pollen data")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Pollen forecasts are primarily available for Europe and North America")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private var isInUS: Bool {
        // Rough bounding box for continental US
        return latitude >= 24.0 && latitude <= 50.0 &&
               longitude >= -125.0 && longitude <= -66.0
    }
    
    private var isInEurope: Bool {
        // Rough bounding box for Europe
        return latitude >= 35.0 && latitude <= 71.0 &&
               longitude >= -10.0 && longitude <= 40.0
    }
    
    private func getCurrentConcentration(for type: PollenType) -> Double {
        guard let data = pollenData, !data.dates.isEmpty else {
            return 0
        }
        
        switch type {
        case .grass:
            return data.grassLevels.first ?? 0
        case .birch, .olive:
            return data.treeLevels.first ?? 0
        case .ragweed:
            return data.weedLevels.first ?? 0
        }
    }
    
    private func getConcentration(for type: PollenType, at index: Int) -> Double? {
        guard let data = pollenData else { return nil }
        
        switch type {
        case .grass:
            return data.grassLevels[safe: index]
        case .birch, .olive:
            return data.treeLevels[safe: index]
        case .ragweed:
            return data.weedLevels[safe: index]
        }
    }
    
    private func parseDate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        return formatter.date(from: isoString)
    }
    
    // MARK: - Data Loading
    
    private func loadPollenData() async {
        isLoading = true
        error = nil
        
        do {
            // Determine which API to use based on location
            if isInUS {
                // Use Tomorrow.io for US locations
                guard !settings.tomorrowIOAPIKey.isEmpty else {
                    await MainActor.run {
                        self.error = "API key required for US pollen data"
                        self.isLoading = false
                    }
                    return
                }
                
                let tomorrowData = try await TomorrowIOService.fetchPollenForecast(
                    latitude: latitude,
                    longitude: longitude,
                    apiKey: settings.tomorrowIOAPIKey
                )
                
                await MainActor.run {
                    self.pollenData = UnifiedPollenData.from(tomorrowIO: tomorrowData)
                    self.dataSource = "Tomorrow.io"
                    self.isLoading = false
                    
                    // Auto-select the highest pollen type
                    if let maxPollen = self.pollenData?.maxPollenInRange(start: 0, count: 7) {
                        self.selectedPollenType = maxPollen.type
                    }
                }
            } else if isInEurope {
                // Use Open-Meteo for European locations
                let openMeteoData = try await WeatherService.fetchPollenForecast(
                    latitude: latitude,
                    longitude: longitude
                )
                
                await MainActor.run {
                    self.pollenData = UnifiedPollenData.from(openMeteo: openMeteoData)
                    self.dataSource = "Open-Meteo"
                    self.isLoading = false
                    
                    // Auto-select the highest pollen type
                    if let maxPollen = self.pollenData?.maxPollenInRange(start: 0, count: 24) {
                        self.selectedPollenType = maxPollen.type
                    }
                }
            } else {
                // Location not supported
                await MainActor.run {
                    self.error = "Pollen data not available for this region"
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.error = "Pollen data unavailable"
                self.isLoading = false
            }
        }
    }
}

// MARK: - Array Safe Subscript Extension

private extension Array where Element == Double {
    subscript(safe index: Int) -> Double? {
        return indices.contains(index) ? self[index] : nil
    }
}
