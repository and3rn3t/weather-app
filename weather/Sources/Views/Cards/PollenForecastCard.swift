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
    
    @State private var pollenData: PollenData?
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedPollenType: PollenType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pollen & Allergies")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let hourly = pollenData?.hourly,
               let maxPollen = hourly.maxPollenInRange(start: 0, count: 24) {
                
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
            
            if let hourly = pollenData?.hourly {
                Chart {
                    ForEach(0..<min(168, hourly.time.count), id: \.self) { index in
                        if let concentration = getConcentration(for: type, at: index),
                           let date = parseDate(hourly.time[index]) {
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
            
            Text("Pollen forecasts are available for European locations only")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private var isInEurope: Bool {
        // Rough bounding box for Europe
        return latitude >= 35.0 && latitude <= 71.0 &&
               longitude >= -10.0 && longitude <= 40.0
    }
    
    private func getCurrentConcentration(for type: PollenType) -> Double {
        guard let hourly = pollenData?.hourly,
              !hourly.time.isEmpty else {
            return 0
        }
        
        switch type {
        case .grass:
            return hourly.grassPollen?.first ?? 0
        case .birch:
            return hourly.birchPollen?.first ?? 0
        case .olive:
            return hourly.olivePollen?.first ?? 0
        case .ragweed:
            return hourly.ragweedPollen?.first ?? 0
        }
    }
    
    private func getConcentration(for type: PollenType, at index: Int) -> Double? {
        guard let hourly = pollenData?.hourly else { return nil }
        
        switch type {
        case .grass:
            return hourly.grassPollen?[safe: index]
        case .birch:
            return hourly.birchPollen?[safe: index]
        case .olive:
            return hourly.olivePollen?[safe: index]
        case .ragweed:
            return hourly.ragweedPollen?[safe: index]
        }
    }
    
    private func parseDate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: isoString)
    }
    
    // MARK: - Data Loading
    
    private func loadPollenData() async {
        isLoading = true
        error = nil
        
        // Only load for European locations
        guard isInEurope else {
            await MainActor.run {
                self.error = "Pollen data not available for this region"
                self.isLoading = false
            }
            return
        }
        
        do {
            let data = try await TomorrowIOService.fetchPollenForecast(
                latitude: latitude,
                longitude: longitude,
                apiKey: APIConfig.defaultTomorrowIOKey
            )

            guard let unified = UnifiedPollenData.from(tomorrowIO: data) else {
                throw WeatherError.decodingError("Invalid pollen data")
            }
            let hourly = HourlyPollen(
                time: unified.dates,
                grassPollen: unified.grassLevels,
                birchPollen: unified.treeLevels,
                olivePollen: nil,
                ragweedPollen: unified.weedLevels
            )
            let converted = PollenData(
                latitude: latitude,
                longitude: longitude,
                timezone: "auto",
                hourly: hourly
            )
            
            await MainActor.run {
                self.pollenData = converted
                self.isLoading = false
                
                // Auto-select the highest pollen type if available
                if let hourly = converted.hourly,
                   let maxPollen = hourly.maxPollenInRange(start: 0, count: 24) {
                    self.selectedPollenType = maxPollen.type
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
