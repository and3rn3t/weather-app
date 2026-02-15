//
//  BackgroundRefreshManager.swift
//  weather
//
//  Smart background refresh scheduling based on user patterns and optimal refresh times
//

import Foundation
import BackgroundTasks
import CoreLocation
import OSLog

/**
 * Manages smart background refresh scheduling based on user usage patterns and optimal timing
 */
@MainActor
class BackgroundRefreshManager: ObservableObject {
    static let shared = BackgroundRefreshManager()
    
    // MARK: - Configuration
    
    private enum Config {
        static let backgroundTaskIdentifier = "com.andernet.weather.background-refresh"
        static let minRefreshInterval: TimeInterval = 30 * 60 // 30 minutes minimum
        static let maxRefreshInterval: TimeInterval = 4 * 60 * 60 // 4 hours maximum
        static let userPatternSampleDays = 7 // Analyze last 7 days of usage
        static let predictionAccuracyThreshold = 0.6 // 60% confidence for predictions
    }
    
    // MARK: - User Pattern Tracking
    
    private struct UserUsagePattern {
        let hour: Int
        let dayOfWeek: Int
        let frequency: Int
        let lastUsed: Date
        
        var timeScore: Double {
            // Recent usage gets higher score
            let daysOld = Date().timeIntervalSince(lastUsed) / (24 * 60 * 60)
            let recencyScore = max(0, 1 - (daysOld / 7)) // Decay over 7 days
            return Double(frequency) * recencyScore
        }
    }
    
    private struct OptimalRefreshWindow {
        let hour: Int
        let confidence: Double
        let estimatedUsage: Date
        
        var shouldScheduleRefresh: Bool {
            confidence >= Config.predictionAccuracyThreshold
        }
    }
    
    // MARK: - Properties
    
    @Published var isBackgroundRefreshEnabled = false
    @Published var lastBackgroundRefresh: Date?
    @Published var nextScheduledRefresh: Date?
    @Published var userPatternPrediction: String = "Learning usage patterns..."
    
    private var usagePatterns: [UserUsagePattern] = []
    private var weatherService: WeatherService = WeatherService()
    
    private let logger = Logger(subsystem: "WeatherApp.Background", category: "RefreshManager")
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    
    private init() {
        loadUserPatterns()
        setupBackgroundTaskHandling()
        analyzeUserPatterns()
    }
    
    // MARK: - Setup and Registration
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Config.backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task as! BGAppRefreshTask)
        }
        
        logger.info("Background task registered: \\(Config.backgroundTaskIdentifier)")
    }
    
    private func setupBackgroundTaskHandling() {
        // Monitor app lifecycle for pattern learning
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recordAppUsage()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleNextOptimalRefresh()
        }
    }
    
    // MARK: - User Pattern Learning
    
    private func recordAppUsage() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let dayOfWeek = calendar.component(.weekday, from: now)
        
        // Find existing pattern for this time slot
        if let existingIndex = usagePatterns.firstIndex(where: { 
            $0.hour == hour && $0.dayOfWeek == dayOfWeek 
        }) {
            // Update existing pattern
            usagePatterns[existingIndex] = UserUsagePattern(
                hour: hour,
                dayOfWeek: dayOfWeek,
                frequency: usagePatterns[existingIndex].frequency + 1,
                lastUsed: now
            )
        } else {
            // Create new pattern
            usagePatterns.append(UserUsagePattern(
                hour: hour,
                dayOfWeek: dayOfWeek,
                frequency: 1,
                lastUsed: now
            ))
        }
        
        saveUserPatterns()
        analyzeUserPatterns()
        
        logger.debug("Recorded app usage at hour \\(hour), day \\(dayOfWeek)")
    }
    
    private func analyzeUserPatterns() {
        guard !usagePatterns.isEmpty else {
            userPatternPrediction = "Collecting usage data..."
            return
        }
        
        // Group patterns by hour and calculate scores
        var hourlyScores: [Int: Double] = [:]
        
        for pattern in usagePatterns {
            hourlyScores[pattern.hour, default: 0] += pattern.timeScore
        }
        
        // Find optimal refresh windows
        let optimalWindows = findOptimalRefreshWindows(from: hourlyScores)
        
        // Update prediction text
        updatePredictionDescription(optimalWindows)
        
        logger.info("Analyzed \\(usagePatterns.count) usage patterns, found \\(optimalWindows.count) optimal windows")
    }
    
    private func findOptimalRefreshWindows(from hourlyScores: [Int: Double]) -> [OptimalRefreshWindow] {
        let maxScore = hourlyScores.values.max() ?? 1.0
        var windows: [OptimalRefreshWindow] = []
        
        // Find hours with high usage likelihood
        for hour in 0..<24 {
            let score = hourlyScores[hour, default: 0] / maxScore
            
            if score >= Config.predictionAccuracyThreshold {
                // Estimate when user might use app within this hour
                let estimatedMinute = predictOptimalMinute(for: hour)
                let estimatedUsage = Calendar.current.date(bySettingHour: hour, minute: estimatedMinute, second: 0, of: Date()) ?? Date()
                
                windows.append(OptimalRefreshWindow(
                    hour: hour,
                    confidence: score,
                    estimatedUsage: estimatedUsage
                ))\n            }\n        }\n        \n        return windows.sorted { $0.confidence > $1.confidence }\n    }\n    \n    private func predictOptimalMinute(for hour: Int) -> Int {\n        // Analyze historical patterns for this hour to predict best minute\n        // For now, use 15 minutes before the hour to ensure fresh data\n        return max(0, 45) // Refresh 15 minutes before expected usage\n    }\n    \n    private func updatePredictionDescription(_ windows: [OptimalRefreshWindow]) {\n        if windows.isEmpty {\n            userPatternPrediction = \"Learning your usage patterns...\"\n        } else {\n            let topWindow = windows.first!\n            let formatter = DateFormatter()\n            formatter.timeStyle = .short\n            \n            let confidence = Int(topWindow.confidence * 100)\n            let timeStr = formatter.string(from: topWindow.estimatedUsage)\n            \n            userPatternPrediction = \"You typically use the app around \\(timeStr) (\\(confidence)% confidence)\"\n        }\n    }\n    \n    // MARK: - Background Refresh Scheduling\n    \n    func scheduleNextOptimalRefresh() {\n        guard isBackgroundRefreshEnabled else {\n            logger.debug(\"Background refresh disabled - not scheduling\")\n            return\n        }\n        \n        let optimalTime = calculateNextOptimalRefreshTime()\n        scheduleBackgroundRefresh(at: optimalTime)\n    }\n    \n    private func calculateNextOptimalRefreshTime() -> Date {\n        let now = Date()\n        let calendar = Calendar.current\n        \n        // Analyze user patterns to find next likely usage\n        let hourlyScores = Dictionary(grouping: usagePatterns) { $0.hour }\n            .mapValues { patterns in\n                patterns.map { $0.timeScore }.reduce(0, +)\n            }\n        \n        // Get optimal windows\n        let windows = findOptimalRefreshWindows(from: hourlyScores)\n        \n        // Find next window that's in the future\n        for window in windows {\n            var nextOccurrence = calendar.date(\n                bySettingHour: window.hour, \n                minute: 45, // 15 minutes before expected usage\n                second: 0, \n                of: now\n            ) ?? now\n            \n            // If this time has passed today, schedule for tomorrow\n            if nextOccurrence <= now {\n                nextOccurrence = calendar.date(byAdding: .day, value: 1, to: nextOccurrence) ?? now\n            }\n            \n            // Ensure minimum interval\n            if let lastRefresh = lastBackgroundRefresh,\n               nextOccurrence.timeIntervalSince(lastRefresh) >= Config.minRefreshInterval {\n                return nextOccurrence\n            } else if lastBackgroundRefresh == nil {\n                return nextOccurrence\n            }\n        }\n        \n        // Fallback: schedule in 2 hours\n        return calendar.date(byAdding: .hour, value: 2, to: now) ?? now\n    }\n    \n    private func scheduleBackgroundRefresh(at date: Date) {\n        // Cancel existing background tasks\n        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Config.backgroundTaskIdentifier)\n        \n        // Create new task request\n        let request = BGAppRefreshTaskRequest(identifier: Config.backgroundTaskIdentifier)\n        request.earliestBeginDate = date\n        \n        do {\n            try BGTaskScheduler.shared.submit(request)\n            nextScheduledRefresh = date\n            \n            let timeFormatter = DateFormatter()\n            timeFormatter.timeStyle = .short\n            timeFormatter.dateStyle = .short\n            \n            logger.info(\"Scheduled background refresh for \\(timeFormatter.string(from: date))\")\n        } catch {\n            logger.error(\"Failed to schedule background refresh: \\(error)\")\n            nextScheduledRefresh = nil\n        }\n    }\n    \n    // MARK: - Background Task Handling\n    \n    private func handleBackgroundRefresh(_ task: BGAppRefreshTask) {\n        logger.info(\"Background refresh task started\")\n        \n        // Set expiration handler\n        task.expirationHandler = {\n            self.logger.warning(\"Background refresh task expired\")\n            task.setTaskCompleted(success: false)\n        }\n        \n        // Perform refresh\n        Task {\n            await performBackgroundWeatherRefresh(task)\n        }\n    }\n    \n    private func performBackgroundWeatherRefresh(_ task: BGAppRefreshTask) async {\n        do {\n            // Get last known location\n            guard let locationMeta = SharedDataManager.lastKnownLocation() else {\n                logger.warning(\"No known location for background refresh\")\n                task.setTaskCompleted(success: false)\n                return\n            }\n            \n            // Perform weather fetch\n            await weatherService.fetchWeather(\n                latitude: locationMeta.latitude, \n                longitude: locationMeta.longitude, \n                locationName: locationMeta.name,\n                forceRefresh: true\n            )\n            \n            // Update last refresh time\n            lastBackgroundRefresh = Date()\n            userDefaults.set(lastBackgroundRefresh, forKey: \"lastBackgroundRefresh\")\n            \n            // Schedule next refresh\n            scheduleNextOptimalRefresh()\n            \n            logger.info(\"Background refresh completed successfully\")\n            task.setTaskCompleted(success: true)\n            \n        } catch {\n            logger.error(\"Background refresh failed: \\(error)\")\n            task.setTaskCompleted(success: false)\n        }\n    }\n    \n    // MARK: - Settings Management\n    \n    func enableBackgroundRefresh() {\n        isBackgroundRefreshEnabled = true\n        userDefaults.set(true, forKey: \"backgroundRefreshEnabled\")\n        scheduleNextOptimalRefresh()\n        logger.info(\"Background refresh enabled\")\n    }\n    \n    func disableBackgroundRefresh() {\n        isBackgroundRefreshEnabled = false\n        userDefaults.set(false, forKey: \"backgroundRefreshEnabled\")\n        \n        // Cancel scheduled tasks\n        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Config.backgroundTaskIdentifier)\n        nextScheduledRefresh = nil\n        \n        logger.info(\"Background refresh disabled\")\n    }\n    \n    func requestBackgroundRefreshPermission() {\n        // This should be called when user enables background refresh\n        // iOS will show the background refresh permission dialog\n        logger.info(\"Requesting background refresh permission\")\n    }\n    \n    // MARK: - Data Persistence\n    \n    private func saveUserPatterns() {\n        do {\n            let data = try JSONEncoder().encode(usagePatterns)\n            userDefaults.set(data, forKey: \"userUsagePatterns\")\n        } catch {\n            logger.error(\"Failed to save usage patterns: \\(error)\")\n        }\n    }\n    \n    private func loadUserPatterns() {\n        // Load background refresh setting\n        isBackgroundRefreshEnabled = userDefaults.bool(forKey: \"backgroundRefreshEnabled\")\n        lastBackgroundRefresh = userDefaults.object(forKey: \"lastBackgroundRefresh\") as? Date\n        \n        // Load usage patterns\n        guard let data = userDefaults.data(forKey: \"userUsagePatterns\") else {\n            usagePatterns = []\n            return\n        }\n        \n        do {\n            let patterns = try JSONDecoder().decode([UserUsagePattern].self, from: data)\n            \n            // Filter out old patterns (older than sample period)\n            let cutoffDate = Date().addingTimeInterval(-Double(Config.userPatternSampleDays) * 24 * 60 * 60)\n            usagePatterns = patterns.filter { $0.lastUsed > cutoffDate }\n            \n            logger.debug(\"Loaded \\(usagePatterns.count) usage patterns\")\n        } catch {\n            logger.error(\"Failed to load usage patterns: \\(error)\")\n            usagePatterns = []\n        }\n    }\n    \n    // MARK: - Statistics\n    \n    func getBackgroundRefreshStatistics() -> BackgroundRefreshStats {\n        let totalPatterns = usagePatterns.count\n        let uniqueHours = Set(usagePatterns.map { $0.hour }).count\n        let avgFrequency = usagePatterns.map { $0.frequency }.reduce(0, +) / max(1, totalPatterns)\n        \n        return BackgroundRefreshStats(\n            isEnabled: isBackgroundRefreshEnabled,\n            lastRefresh: lastBackgroundRefresh,\n            nextScheduled: nextScheduledRefresh,\n            totalUsagePatterns: totalPatterns,\n            uniqueUsageHours: uniqueHours,\n            averageFrequency: avgFrequency,\n            predictionConfidence: findOptimalRefreshWindows(\n                from: Dictionary(grouping: usagePatterns) { $0.hour }\n                    .mapValues { $0.map { $0.timeScore }.reduce(0, +) }\n            ).first?.confidence ?? 0.0\n        )\n    }\n    \n    struct BackgroundRefreshStats {\n        let isEnabled: Bool\n        let lastRefresh: Date?\n        let nextScheduled: Date?\n        let totalUsagePatterns: Int\n        let uniqueUsageHours: Int\n        let averageFrequency: Int\n        let predictionConfidence: Double\n    }\n}\n\n// MARK: - UserUsagePattern Codable Conformance\n\nextension BackgroundRefreshManager.UserUsagePattern: Codable {\n    enum CodingKeys: String, CodingKey {\n        case hour, dayOfWeek, frequency, lastUsed\n    }\n}