//
//  LiveActivityManager.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import Foundation
import ActivityKit
import SwiftUI

// MARK: - Weather Activity Attributes (shared with widget extension)

struct WeatherActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var temperature: Double
        var weatherCode: Int
        var highTemp: Double
        var lowTemp: Double
        var humidity: Int
        var windSpeed: Double
        var lastUpdated: Date
    }
    
    var locationName: String
}

// MARK: - Live Activity Manager

@Observable
class LiveActivityManager {
    private var currentActivity: Activity<WeatherActivityAttributes>?
    var isActivityActive: Bool {
        currentActivity != nil
    }
    
    /// Start a new Live Activity with weather data
    func startActivity(weatherData: WeatherData, locationName: String?) async {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // End any existing activity
        await endActivity()
        
        let attributes = WeatherActivityAttributes(
            locationName: locationName ?? "Current Location"
        )
        
        let contentState = WeatherActivityAttributes.ContentState(
            temperature: weatherData.current.temperature2m,
            weatherCode: weatherData.current.weatherCode,
            highTemp: weatherData.daily.temperature2mMax.first ?? 0,
            lowTemp: weatherData.daily.temperature2mMin.first ?? 0,
            humidity: weatherData.current.relativeHumidity2m,
            windSpeed: weatherData.current.windSpeed10m,
            lastUpdated: Date()
        )
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            print("Started Live Activity: \(currentActivity?.id ?? "unknown")")
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    /// Update the current Live Activity with new weather data
    func updateActivity(weatherData: WeatherData) async {
        guard let activity = currentActivity else {
            print("No active Live Activity to update")
            return
        }
        
        let contentState = WeatherActivityAttributes.ContentState(
            temperature: weatherData.current.temperature2m,
            weatherCode: weatherData.current.weatherCode,
            highTemp: weatherData.daily.temperature2mMax.first ?? 0,
            lowTemp: weatherData.daily.temperature2mMin.first ?? 0,
            humidity: weatherData.current.relativeHumidity2m,
            windSpeed: weatherData.current.windSpeed10m,
            lastUpdated: Date()
        )
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        )
        
        await activity.update(activityContent)
        print("Updated Live Activity")
    }
    
    /// End the current Live Activity
    func endActivity() async {
        guard let activity = currentActivity else { return }
        
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
        print("Ended Live Activity")
    }
    
    /// End all active weather activities (cleanup)
    func endAllActivities() async {
        for activity in Activity<WeatherActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
    
    /// Check if there's an existing activity and restore reference
    func restoreExistingActivity() {
        if let existingActivity = Activity<WeatherActivityAttributes>.activities.first {
            currentActivity = existingActivity
            print("Restored existing Live Activity: \(existingActivity.id)")
        }
    }
}
