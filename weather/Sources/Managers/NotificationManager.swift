//
//  NotificationManager.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import Foundation
import UserNotifications
import CoreLocation

@Observable
class NotificationManager: NSObject {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var hasPermission: Bool = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                hasPermission = granted
            }
            checkAuthorizationStatus()
            return granted
        } catch {
            // Log error silently - user will see system permission dialog
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                authorizationStatus = settings.authorizationStatus
                hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Daily Forecast Notification
    
    func scheduleDailyForecast(at time: Date, weather: WeatherData, locationName: String?) async {
        // Remove existing daily forecast notifications
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily-forecast"])
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Weather Forecast"
        
        let condition = WeatherCondition(code: weather.current.weatherCode)
        let high = Int(weather.daily.temperature2mMax.first ?? 0)
        let low = Int(weather.daily.temperature2mMin.first ?? 0)
        
        let location = locationName ?? "your location"
        content.body = "Today in \(location): \(condition.description). High \(high)°, Low \(low)°"
        content.sound = .default
        content.categoryIdentifier = "WEATHER_FORECAST"
        
        // Create date components from the selected time
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-forecast",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            // Notification scheduling failed - will retry on next update
        }
    }
    
    func cancelDailyForecast() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily-forecast"])
    }
    
    // MARK: - Weather Alert Notifications
    
    func notifySevereWeather(alert: WeatherAlert, locationName: String?) async {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ \(alert.event)"
        content.body = alert.headline
        content.sound = .defaultCritical
        content.interruptionLevel = .critical
        content.categoryIdentifier = "WEATHER_ALERT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "alert-\(alert.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            // Alert notification failed - will retry on next weather update
        }
    }
    
    // MARK: - Rain Alert Notification
    
    func checkForRainAndNotify(weather: WeatherData, locationName: String?) async {
        // Check if rain is expected in the next 2 hours
        let now = Date()
        let twoHoursLater = now.addingTimeInterval(2 * 60 * 60)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var willRain = false
        for (index, timeString) in weather.hourly.time.enumerated() {
            guard let time = formatter.date(from: timeString) else { continue }
            
            if time > now && time <= twoHoursLater {
                let precipProb = weather.hourly.precipitationProbability?[index] ?? 0
                if precipProb > 50 {
                    willRain = true
                    break
                }
            }
        }
        
        if willRain {
            let content = UNMutableNotificationContent()
            content.title = "☔️ Rain Expected"
            
            let location = locationName ?? "your location"
            content.body = "Rain is expected in \(location) within the next 2 hours. Don't forget your umbrella!"
            content.sound = .default
            content.categoryIdentifier = "RAIN_ALERT"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "rain-alert-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await notificationCenter.add(request)
            } catch {
                // Rain alert notification failed
            }
        }
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
            // Weather change notification failed
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
