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
import Combine
import UIKit

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
    
    struct UserUsagePattern {
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
    private var weatherService: WeatherService = WeatherService.shared
    
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
        
        logger.info("Background task registered: \(Config.backgroundTaskIdentifier)")
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
        
        logger.debug("Recorded app usage at hour \(hour), day \(dayOfWeek)")
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
        
        logger.info("Analyzed \(self.usagePatterns.count) usage patterns, found \(optimalWindows.count) optimal windows")
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
                ))
            }
        }
        
        return windows.sorted { $0.confidence > $1.confidence }
    }
    
    private func predictOptimalMinute(for hour: Int) -> Int {
        // Analyze historical patterns for this hour to predict best minute
        // For now, use 15 minutes before the hour to ensure fresh data
        return max(0, 45) // Refresh 15 minutes before expected usage
    }
    
    private func updatePredictionDescription(_ windows: [OptimalRefreshWindow]) {
        if windows.isEmpty {
            userPatternPrediction = "Learning your usage patterns..."
        } else {
            let topWindow = windows.first!
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            let confidence = Int(topWindow.confidence * 100)
            let timeStr = formatter.string(from: topWindow.estimatedUsage)
            
            userPatternPrediction = "You typically use the app around (timeStr) ((confidence)% confidence)"
        }
    }
    
    // MARK: - Background Refresh Scheduling
    
    func scheduleNextOptimalRefresh() {
        guard isBackgroundRefreshEnabled else {
            logger.debug("Background refresh disabled - not scheduling")
            return
        }
        
        let optimalTime = calculateNextOptimalRefreshTime()
        scheduleBackgroundRefresh(at: optimalTime)
    }
    
    private func calculateNextOptimalRefreshTime() -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // Analyze user patterns to find next likely usage
        let hourlyScores = Dictionary(grouping: usagePatterns) { $0.hour }
            .mapValues { patterns in
                patterns.map { $0.timeScore }.reduce(0, +)
            }
        
        // Get optimal windows
        let windows = findOptimalRefreshWindows(from: hourlyScores)
        
        // Find next window that's in the future
        for window in windows {
            var nextOccurrence = calendar.date(
                bySettingHour: window.hour, 
                minute: 45, // 15 minutes before expected usage
                second: 0, 
                of: now
            ) ?? now
            
            // If this time has passed today, schedule for tomorrow
            if nextOccurrence <= now {
                nextOccurrence = calendar.date(byAdding: .day, value: 1, to: nextOccurrence) ?? now
            }
            
            // Ensure minimum interval
            if let lastRefresh = lastBackgroundRefresh,
               nextOccurrence.timeIntervalSince(lastRefresh) >= Config.minRefreshInterval {
                return nextOccurrence
            } else if lastBackgroundRefresh == nil {
                return nextOccurrence
            }
        }
        
        // Fallback: schedule in 2 hours
        return calendar.date(byAdding: .hour, value: 2, to: now) ?? now
    }
    
    private func scheduleBackgroundRefresh(at date: Date) {
        // Cancel existing background tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Config.backgroundTaskIdentifier)
        
        // Create new task request
        let request = BGAppRefreshTaskRequest(identifier: Config.backgroundTaskIdentifier)
        request.earliestBeginDate = date
        
        do {
            try BGTaskScheduler.shared.submit(request)
            nextScheduledRefresh = date
            
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            timeFormatter.dateStyle = .short
            
            logger.info("Scheduled background refresh for \(timeFormatter.string(from: date))")
        } catch {
            logger.error("Failed to schedule background refresh: \(error)")
            nextScheduledRefresh = nil
        }
    }
    
    // MARK: - Background Task Handling
    
    private func handleBackgroundRefresh(_ task: BGAppRefreshTask) {
        logger.info("Background refresh task started")
        
        // Set expiration handler
        task.expirationHandler = {
            self.logger.warning("Background refresh task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform refresh
        Task {
            await performBackgroundWeatherRefresh(task)
        }
    }
    
    private func performBackgroundWeatherRefresh(_ task: BGAppRefreshTask) async {
        do {
            // Get last known location
            guard let locationMeta = SharedDataManager.lastKnownLocation() else {
                logger.warning("No known location for background refresh")
                task.setTaskCompleted(success: false)
                return
            }
            
            // Perform weather fetch
            await weatherService.fetchWeatherData(
                latitude: locationMeta.latitude, 
                longitude: locationMeta.longitude, 
                locationName: locationMeta.name,
                forceRefresh: true
            )
            
            // Update last refresh time
            lastBackgroundRefresh = Date()
            userDefaults.set(lastBackgroundRefresh, forKey: "lastBackgroundRefresh")
            
            // Schedule next refresh
            scheduleNextOptimalRefresh()
            
            logger.info("Background refresh completed successfully")
            task.setTaskCompleted(success: true)
            
        } catch {
            logger.error("Background refresh failed: \(error)")
            task.setTaskCompleted(success: false)
        }
    }
    
    // MARK: - Settings Management
    
    func enableBackgroundRefresh() {
        isBackgroundRefreshEnabled = true
        userDefaults.set(true, forKey: "backgroundRefreshEnabled")
        scheduleNextOptimalRefresh()
        logger.info("Background refresh enabled")
    }
    
    func disableBackgroundRefresh() {
        isBackgroundRefreshEnabled = false
        userDefaults.set(false, forKey: "backgroundRefreshEnabled")
        
        // Cancel scheduled tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Config.backgroundTaskIdentifier)
        nextScheduledRefresh = nil
        
        logger.info("Background refresh disabled")
    }
    
    func requestBackgroundRefreshPermission() {
        // This should be called when user enables background refresh
        // iOS will show the background refresh permission dialog
        logger.info("Requesting background refresh permission")
    }
    
    // MARK: - Data Persistence
    
    private func saveUserPatterns() {
        do {
            let data = try JSONEncoder().encode(usagePatterns)
            userDefaults.set(data, forKey: "userUsagePatterns")
        } catch {
            logger.error("Failed to save usage patterns: \(error)")
        }
    }
    
    private func loadUserPatterns() {
        // Load background refresh setting
        isBackgroundRefreshEnabled = userDefaults.bool(forKey: "backgroundRefreshEnabled")
        lastBackgroundRefresh = userDefaults.object(forKey: "lastBackgroundRefresh") as? Date
        
        // Load usage patterns
        guard let data = userDefaults.data(forKey: "userUsagePatterns") else {
            usagePatterns = []
            return
        }
        
        do {
            let patterns = try JSONDecoder().decode([UserUsagePattern].self, from: data)
            
            // Filter out old patterns (older than sample period)
            let cutoffDate = Date().addingTimeInterval(-Double(Config.userPatternSampleDays) * 24 * 60 * 60)
            self.usagePatterns = patterns.filter { $0.lastUsed > cutoffDate }
            
            logger.debug("Loaded \(self.usagePatterns.count) usage patterns")
        } catch {
            logger.error("Failed to load usage patterns: \(error)")
            self.usagePatterns = []
        }
    }
    
    // MARK: - Statistics
    
    func getBackgroundRefreshStatistics() -> BackgroundRefreshStats {
        let totalPatterns = usagePatterns.count
        let uniqueHours = Set(usagePatterns.map { $0.hour }).count
        let avgFrequency = usagePatterns.map { $0.frequency }.reduce(0, +) / max(1, totalPatterns)
        
        return BackgroundRefreshStats(
            isEnabled: isBackgroundRefreshEnabled,
            lastRefresh: lastBackgroundRefresh,
            nextScheduled: nextScheduledRefresh,
            totalUsagePatterns: totalPatterns,
            uniqueUsageHours: uniqueHours,
            averageFrequency: avgFrequency,
            predictionConfidence: findOptimalRefreshWindows(
                from: Dictionary(grouping: usagePatterns) { $0.hour }
                    .mapValues { $0.map { $0.timeScore }.reduce(0, +) }
            ).first?.confidence ?? 0.0
        )
    }
    
    struct BackgroundRefreshStats {
        let isEnabled: Bool
        let lastRefresh: Date?
        let nextScheduled: Date?
        let totalUsagePatterns: Int
        let uniqueUsageHours: Int
        let averageFrequency: Int
        let predictionConfidence: Double
    }
}

// MARK: - UserUsagePattern Codable Conformance

extension BackgroundRefreshManager.UserUsagePattern: Codable {
    enum CodingKeys: String, CodingKey {
        case hour, dayOfWeek, frequency, lastUsed
    }
}