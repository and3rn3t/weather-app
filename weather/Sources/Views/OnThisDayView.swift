//
//  OnThisDayView.swift
//  weather
//
//  Created by Matt on 2/7/26.
//

import SwiftUI

// MARK: - Historical Weather Models

struct HistoricalWeatherData: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let daily: HistoricalDailyWeather
}

struct HistoricalDailyWeather: Codable, Sendable {
    let time: [String]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let weatherCode: [Int]
    let precipitationSum: [Double?]
    let windSpeed10mMax: [Double?]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case weatherCode = "weather_code"
        case precipitationSum = "precipitation_sum"
        case windSpeed10mMax = "wind_speed_10m_max"
    }
}

// MARK: - Year Comparison Data

struct YearComparison: Identifiable {
    let id = UUID()
    let year: Int
    let high: Double
    let low: Double
    let condition: WeatherCondition
    let precipitation: Double?
    let windSpeed: Double?
    
    var averageTemp: Double {
        (high + low) / 2
    }
}

// MARK: - On This Day Card

struct OnThisDayCard: View {
    let currentWeather: CurrentWeather
    let latitude: Double
    let longitude: Double
    @Environment(SettingsManager.self) private var settings
    
    @State private var historicalData: [YearComparison] = []
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var isExpanded = false
    
    private let currentYear = Calendar.current.component(.year, from: Date())
    
    /// Number of past years to fetch
    private let yearsToFetch = 5
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                if isExpanded && !hasLoaded {
                    fetchHistoricalData()
                }
                HapticFeedback.impact()
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title3)
                        .foregroundStyle(.orange.gradient)
                    
                    Text("On This Day")
                        .font(.headline.weight(.semibold))
                    
                    Spacer()
                    
                    if !historicalData.isEmpty, let funFact = topFunFact {
                        Text(funFact)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("On This Day. Tap to \(isExpanded ? "collapse" : "expand") historical weather")
            
            if isExpanded {
                if isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Loading historical weather…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else if let error = errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.icloud")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else if !historicalData.isEmpty {
                    expandedContent
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }
            }
        }
        .padding(20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
        .task {
            // Prefetch data on appear so the fun fact shows in collapsed header
            if !hasLoaded {
                fetchHistoricalData()
            }
        }
    }
    
    // MARK: - Expanded Content
    
    @ViewBuilder
    private var expandedContent: some View {
        VStack(spacing: 14) {
            // Today vs average comparison
            if let avgHigh = averageHistoricalHigh, let avgLow = averageHistoricalLow {
                todayVsAverageRow(avgHigh: avgHigh, avgLow: avgLow)
            }
            
            Divider()
            
            // Year-by-year breakdown
            ForEach(historicalData.sorted(by: { $0.year > $1.year })) { year in
                yearRow(year)
                
                if year.year != historicalData.sorted(by: { $0.year > $1.year }).last?.year {
                    Divider().opacity(0.5)
                }
            }
            
            // Fun facts section
            if let facts = funFacts, !facts.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fun Facts")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    ForEach(facts, id: \.self) { fact in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(fact)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func todayVsAverageRow(avgHigh: Double, avgLow: Double) -> some View {
        let todayHigh = currentWeather.temperature2m
        let highDiff = todayHigh - avgHigh
        let diffSign = highDiff >= 0 ? "+" : ""
        let diffColor: Color = highDiff > 5 ? .red : (highDiff < -5 ? .blue : .green)
        
        return VStack(spacing: 8) {
            HStack {
                Text("Today vs. \(yearsToFetch)-Year Avg")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(diffSign)\(settings.formatTemperature(abs(highDiff)))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(diffColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(diffColor.opacity(0.15), in: Capsule())
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Today")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(settings.formatTemperature(todayHigh))
                        .font(.title3.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: highDiff >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.title3)
                    .foregroundStyle(diffColor)
                
                VStack(spacing: 4) {
                    Text("Avg High")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(settings.formatTemperature(avgHigh))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today is \(settings.formatTemperature(abs(highDiff))) \(highDiff >= 0 ? "warmer" : "cooler") than the \(yearsToFetch)-year average high of \(settings.formatTemperature(avgHigh))")
    }
    
    private func yearRow(_ comparison: YearComparison) -> some View {
        HStack(spacing: 12) {
            Text("\(String(comparison.year))")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(width: 44, alignment: .leading)
            
            Image(systemName: comparison.condition.symbolName)
                .font(.callout)
                .symbolRenderingMode(.multicolor)
                .frame(width: 24)
            
            // Temperature bar
            temperatureBar(high: comparison.high, low: comparison.low)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("H: \(settings.formatTemperature(comparison.high))")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
                Text("L: \(settings.formatTemperature(comparison.low))")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.cyan)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(comparison.year): \(comparison.condition.description), high \(settings.formatTemperature(comparison.high)), low \(settings.formatTemperature(comparison.low))")
    }
    
    private func temperatureBar(high: Double, low: Double) -> some View {
        GeometryReader { geo in
            let allTemps = historicalData.flatMap { [$0.high, $0.low] } + [currentWeather.temperature2m]
            let minTemp = (allTemps.min() ?? 0) - 5
            let maxTemp = (allTemps.max() ?? 100) + 5
            let range = maxTemp - minTemp
            
            let lowFraction = (low - minTemp) / range
            let highFraction = (high - minTemp) / range
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 6)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: max(CGFloat(highFraction - lowFraction) * geo.size.width, 8),
                        height: 6
                    )
                    .offset(x: CGFloat(lowFraction) * geo.size.width)
            }
            .frame(height: geo.size.height)
        }
        .frame(height: 20)
    }
    
    // MARK: - Fun Facts
    
    private var topFunFact: String? {
        guard !historicalData.isEmpty else { return nil }
        
        let todayTemp = currentWeather.temperature2m
        guard let avgHigh = averageHistoricalHigh else { return nil }
        let diff = todayTemp - avgHigh
        
        if diff > 10 {
            return "🔥 Much warmer than usual!"
        } else if diff > 5 {
            return "☀️ Warmer than average"
        } else if diff < -10 {
            return "🥶 Much colder than usual!"
        } else if diff < -5 {
            return "❄️ Cooler than average"
        } else {
            return "📊 Right around average"
        }
    }
    
    private var funFacts: [String]? {
        guard !historicalData.isEmpty else { return nil }
        
        var facts: [String] = []
        
        // Hottest year
        if let hottest = historicalData.max(by: { $0.high < $1.high }) {
            facts.append("Hottest on this day: \(settings.formatTemperature(hottest.high)) in \(hottest.year)")
        }
        
        // Coldest year
        if let coldest = historicalData.min(by: { $0.low < $1.low }) {
            facts.append("Coldest on this day: \(settings.formatTemperature(coldest.low)) in \(coldest.year)")
        }
        
        // Rain count
        let rainyYears = historicalData.filter { comparison in
            let code = comparison.condition
            return code == .rain || code == .drizzle || code == .thunderstorm
        }
        if !rainyYears.isEmpty {
            facts.append("It rained on this day \(rainyYears.count) out of \(historicalData.count) years")
        }
        
        // Snow count
        let snowyYears = historicalData.filter { $0.condition == .snow }
        if !snowyYears.isEmpty {
            facts.append("It snowed on this day \(snowyYears.count) out of \(historicalData.count) years")
        }
        
        // Temperature range across all years
        if let highest = historicalData.max(by: { $0.high < $1.high })?.high,
           let lowest = historicalData.min(by: { $0.low < $1.low })?.low {
            let range = highest - lowest
            facts.append("Temperature range across \(historicalData.count) years: \(settings.formatTemperature(range))")
        }
        
        return facts.isEmpty ? nil : facts
    }
    
    private var averageHistoricalHigh: Double? {
        guard !historicalData.isEmpty else { return nil }
        return historicalData.map(\.high).reduce(0, +) / Double(historicalData.count)
    }
    
    private var averageHistoricalLow: Double? {
        guard !historicalData.isEmpty else { return nil }
        return historicalData.map(\.low).reduce(0, +) / Double(historicalData.count)
    }
    
    // MARK: - Data Fetching
    
    private func fetchHistoricalData() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let data = try await HistoricalWeatherService.fetchOnThisDay(
                    latitude: latitude,
                    longitude: longitude,
                    yearsBack: yearsToFetch
                )
                await MainActor.run {
                    self.historicalData = data
                    self.isLoading = false
                    self.hasLoaded = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Historical data unavailable"
                    self.isLoading = false
                    self.hasLoaded = true
                }
            }
        }
    }
}

// MARK: - Historical Weather Service

enum HistoricalWeatherService {
    private static let archiveURL = "https://archive-api.open-meteo.com/v1/archive"
    
    /// Shared URL session (reuses WeatherService pattern)
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 20_000_000)
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }()
    
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    /// Cached date formatter for building date strings
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Fetch weather data for today's date across multiple past years
    static func fetchOnThisDay(
        latitude: Double,
        longitude: Double,
        yearsBack: Int
    ) async throws -> [YearComparison] {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        let currentDay = calendar.component(.day, from: today)
        let currentYear = calendar.component(.year, from: today)
        
        // Fetch each year sequentially (simple & concurrency-safe)
        var results: [YearComparison] = []
        
        for yearOffset in 1...yearsBack {
            let targetYear = currentYear - yearOffset
            
            if let comparison = try? await fetchSingleDay(
                latitude: latitude,
                longitude: longitude,
                year: targetYear,
                month: currentMonth,
                day: currentDay
            ) {
                results.append(comparison)
            }
        }
        
        return results.sorted(by: { $0.year > $1.year })
    }
    
    /// Fetch a single day's historical weather
    private static func fetchSingleDay(
        latitude: Double,
        longitude: Double,
        year: Int,
        month: Int,
        day: Int
    ) async throws -> YearComparison? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        let calendar = Calendar.current
        guard let targetDate = calendar.date(from: components) else {
            return nil
        }
        
        let dateString = dateFormatter.string(from: targetDate)
        
        var urlComponents = URLComponents(string: archiveURL)
        urlComponents?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "start_date", value: dateString),
            URLQueryItem(name: "end_date", value: dateString),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code,precipitation_sum,wind_speed_10m_max"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        guard let url = urlComponents?.url else { return nil }
        
        let (data, response) = try await Self.session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let historical = try Self.decoder.decode(HistoricalWeatherData.self, from: data)
        
        guard let high = historical.daily.temperature2mMax.first,
              let low = historical.daily.temperature2mMin.first,
              let code = historical.daily.weatherCode.first else {
            return nil
        }
        
        return YearComparison(
            year: year,
            high: high,
            low: low,
            condition: WeatherCondition(code: code),
            precipitation: historical.daily.precipitationSum.first ?? nil,
            windSpeed: historical.daily.windSpeed10mMax.first ?? nil
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.6), .cyan.opacity(0.4)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        ScrollView {
            OnThisDayCard(
                currentWeather: CurrentWeather(
                    time: "2026-02-07T12:00",
                    temperature2m: 45,
                    apparentTemperature: 40,
                    weatherCode: 0,
                    windSpeed10m: 15.5,
                    windDirection10m: 225,
                    windGusts10m: 28.3,
                    relativeHumidity2m: 65,
                    dewPoint2m: 38,
                    pressure: 1013,
                    cloudCover: 20,
                    visibility: 16000,
                    uvIndex: 3.0,
                    isDay: 1,
                    precipitation: 0.0
                ),
                latitude: 40.7128,
                longitude: -74.0060
            )
            .environment(SettingsManager())
            .padding(20)
        }
    }
}
