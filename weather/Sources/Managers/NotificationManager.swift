//
//  NotificationManager.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import CoreLocation
import Foundation
import OSLog
import UserNotifications

// MARK: - Notification center abstraction (lets tests avoid the real center)

protocol NotificationCenterProtocol: AnyObject {
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
    func removeAllDeliveredNotifications()
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
}

extension UNUserNotificationCenter: NotificationCenterProtocol {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}

/// The notification-related settings, captured as a value so the manager doesn't depend on SettingsManager.
struct NotificationPreferences: Equatable {
    var severeAlertsEnabled: Bool
    var rainAlertsEnabled: Bool
    var dailyForecastEnabled: Bool
    var dailyForecastTime: Date

    init(severeAlertsEnabled: Bool, rainAlertsEnabled: Bool, dailyForecastEnabled: Bool, dailyForecastTime: Date) {
        self.severeAlertsEnabled = severeAlertsEnabled
        self.rainAlertsEnabled = rainAlertsEnabled
        self.dailyForecastEnabled = dailyForecastEnabled
        self.dailyForecastTime = dailyForecastTime
    }

    init(settings: SettingsManager) {
        self.init(
            severeAlertsEnabled: settings.severeWeatherAlertsEnabled,
            rainAlertsEnabled: settings.rainAlertsEnabled,
            dailyForecastEnabled: settings.dailyForecastEnabled,
            dailyForecastTime: settings.notificationTime
        )
    }
}

@Observable
class NotificationManager: NSObject {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var hasPermission: Bool = false

    private let notificationCenter: any NotificationCenterProtocol
    private let defaults: UserDefaults

    /// Most recent successful fetch, so a settings change can reschedule without a new request.
    private var latestWeather: WeatherData?
    private var latestLocationName: String?

    /// How far ahead to check for rain (seconds)
    private static let rainLookAheadInterval: TimeInterval = 2 * 60 * 60
    /// Minimum precipitation probability to trigger rain alert (%)
    private static let rainProbabilityThreshold = 50
    private static let notifiedAlertsKey = "notifiedAlertExpiries"
    private static let lastRainOnsetKey = "lastNotifiedRainOnset"
    private static let dailyForecastIdentifier = "daily-forecast"

    init(notificationCenter: any NotificationCenterProtocol = UNUserNotificationCenter.current(),
         defaults: UserDefaults = .standard) {
        self.notificationCenter = notificationCenter
        self.defaults = defaults
        super.init()
        // Note: checkAuthorizationStatus() deferred to first use for faster app startup
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            hasPermission = granted
            checkAuthorizationStatus()
            return granted
        } catch {
            Logger.notifications.error("Authorization request failed: \(error.localizedDescription)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        Task {
            let status = await notificationCenter.authorizationStatus()
            authorizationStatus = status
            hasPermission = status == .authorized
        }
    }

    // MARK: - Entry point after a successful fetch

    /// Called after every successful weather fetch (foreground and background). Sends alert and
    /// rain notifications for what is new, and rebuilds the daily forecast with fresh content.
    func handleWeatherUpdate(
        weather: WeatherData,
        alerts: [WeatherAlert],
        locationName: String?,
        preferences: NotificationPreferences,
        now: Date = Date()
    ) async {
        latestWeather = weather
        latestLocationName = locationName

        guard await notificationCenter.authorizationStatus() == .authorized else { return }

        if preferences.severeAlertsEnabled {
            await notifyNewSevereAlerts(alerts, locationName: locationName, now: now)
        }
        if preferences.rainAlertsEnabled {
            await checkForRainAndNotify(weather: weather, locationName: locationName, now: now)
        }
        await applyDailyForecast(preferences: preferences, now: now)
    }

    /// Called when the user changes the daily forecast toggle or time.
    func preferencesChanged(_ preferences: NotificationPreferences, now: Date = Date()) async {
        await applyDailyForecast(preferences: preferences, now: now)
    }

    private func applyDailyForecast(preferences: NotificationPreferences, now: Date) async {
        guard preferences.dailyForecastEnabled else {
            cancelDailyForecast()
            return
        }
        guard let weather = latestWeather else { return }
        await scheduleDailyForecast(at: preferences.dailyForecastTime, weather: weather, locationName: latestLocationName, now: now)
    }

    // MARK: - Daily Forecast Notification

    /// Schedules a one-shot notification for the next occurrence of `time`. It is not repeating:
    /// a repeating trigger would deliver the same stale text every day, so it is rebuilt with
    /// fresh content after each refresh instead.
    func scheduleDailyForecast(at time: Date, weather: WeatherData, locationName: String?, now: Date = Date()) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.dailyForecastIdentifier])

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        guard let fireDate = calendar.nextDate(after: now, matching: timeComponents, matchingPolicy: .nextTime) else { return }

        // Tomorrow's morning notification should describe tomorrow, not today.
        let dayIndex = calendar.isDate(fireDate, inSameDayAs: now) ? 0 : 1
        let highs = weather.daily.temperature2mMax
        let lows = weather.daily.temperature2mMin
        let high = Int(highs.indices.contains(dayIndex) ? highs[dayIndex] : (highs.first ?? 0))
        let low = Int(lows.indices.contains(dayIndex) ? lows[dayIndex] : (lows.first ?? 0))
        let dayWord = dayIndex == 0 ? "Today" : "Tomorrow"

        let content = UNMutableNotificationContent()
        content.title = "Daily Weather Forecast"
        let condition = WeatherCondition(code: weather.current.weatherCode)
        content.body = "\(dayWord) in \(locationName ?? "your location"): \(condition.description). High \(high)°, Low \(low)°"
        content.sound = .default
        content.categoryIdentifier = "WEATHER_FORECAST"

        let fireComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        let request = UNNotificationRequest(identifier: Self.dailyForecastIdentifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            Logger.notifications.error("Failed to schedule daily forecast: \(error.localizedDescription)")
        }
    }

    func cancelDailyForecast() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.dailyForecastIdentifier])
    }

    // MARK: - Weather Alert Notifications

    /// Notifies once per active severe/extreme alert. Notified alerts are remembered (until they
    /// expire) so relaunches and repeat fetches don't notify again.
    func notifyNewSevereAlerts(_ alerts: [WeatherAlert], locationName: String?, now: Date = Date()) async {
        var notified = loadNotifiedAlerts().filter { $0.value > now } // forget expired
        for alert in alerts where alert.expires > now && alert.effective <= now && alert.priority >= 4 {
            guard notified[alert.id] == nil else { continue }
            await notifySevereWeather(alert: alert, locationName: locationName)
            notified[alert.id] = alert.expires
        }
        defaults.set(notified.mapValues { $0.timeIntervalSince1970 }, forKey: Self.notifiedAlertsKey)
    }

    private func loadNotifiedAlerts() -> [String: Date] {
        let stored = defaults.dictionary(forKey: Self.notifiedAlertsKey) as? [String: TimeInterval] ?? [:]
        return stored.mapValues { Date(timeIntervalSince1970: $0) }
    }

    func notifySevereWeather(alert: WeatherAlert, locationName: String?) async {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ \(alert.event)"
        content.body = alert.headline
        content.sound = .defaultCritical
        content.interruptionLevel = .critical
        content.categoryIdentifier = "WEATHER_ALERT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        // Stable identifier: re-adding the same alert replaces it instead of duplicating.
        let request = UNNotificationRequest(identifier: "alert-\(alert.id)", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            Logger.notifications.error("Failed to send severe weather alert: \(error.localizedDescription)")
        }
    }

    // MARK: - Rain Alert Notification

    /// Notifies when rain is expected within two hours, once per rain event (keyed by the hour it starts).
    func checkForRainAndNotify(weather: WeatherData, locationName: String?, now: Date = Date()) async {
        guard let onset = rainOnset(in: weather, now: now) else { return }

        let onsetStamp = onset.timeIntervalSince1970
        if defaults.object(forKey: Self.lastRainOnsetKey) as? TimeInterval == onsetStamp { return }

        let content = UNMutableNotificationContent()
        content.title = "☔️ Rain Expected"
        content.body = "Rain is expected in \(locationName ?? "your location") within the next 2 hours. Don't forget your umbrella!"
        content.sound = .default
        content.categoryIdentifier = "RAIN_ALERT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "rain-\(Int(onsetStamp))", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            defaults.set(onsetStamp, forKey: Self.lastRainOnsetKey)
        } catch {
            Logger.notifications.error("Failed to send rain alert: \(error.localizedDescription)")
        }
    }

    /// The first hour in the look-ahead window with a high chance of rain.
    private func rainOnset(in weather: WeatherData, now: Date) -> Date? {
        // Open-Meteo hourly times have no UTC offset ("2026-02-14T12:00"): they are in the forecast's own timezone.
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: weather.timezone) ?? .current
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let lookAheadEnd = now.addingTimeInterval(Self.rainLookAheadInterval)
        for (index, timeString) in weather.hourly.time.enumerated() {
            guard let time = parser.date(from: timeString), time > now, time <= lookAheadEnd else { continue }
            if (weather.hourly.precipitationProbability?[safe: index] ?? 0) > Self.rainProbabilityThreshold {
                return time
            }
        }
        return nil
    }

    // MARK: - Background Refresh Alert

    func notifySignificantWeatherChange(oldWeather: WeatherData, newWeather: WeatherData, locationName: String?) async {
        let oldCondition = WeatherCondition(code: oldWeather.current.weatherCode)
        let newCondition = WeatherCondition(code: newWeather.current.weatherCode)

        // Check if weather changed significantly
        guard oldCondition != newCondition else { return }

        let content = UNMutableNotificationContent()
        content.title = "Weather Update"
        let location = locationName ?? "your location"
        content.body = "Weather in \(location) changed from \(oldCondition.description) to \(newCondition.description)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "weather-change-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            Logger.notifications.error("Failed to send weather change notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    func clearDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
