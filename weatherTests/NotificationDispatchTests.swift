//
//  NotificationManagerTests.swift
//  weatherTests
//
//  NotificationManager against a mock notification center (nothing is delivered).
//

import Foundation
import Testing
import UserNotifications
@testable import weather

final class MockNotificationCenter: NotificationCenterProtocol {
    var status: UNAuthorizationStatus = .authorized
    private(set) var added: [UNNotificationRequest] = []
    private(set) var removedIdentifiers: [String] = []

    func add(_ request: UNNotificationRequest) async throws {
        added.removeAll { $0.identifier == request.identifier } // same identifier replaces
        added.append(request)
    }
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers += identifiers
        added.removeAll { identifiers.contains($0.identifier) }
    }
    func removeAllPendingNotificationRequests() { added.removeAll() }
    func removeAllDeliveredNotifications() {}
    func authorizationStatus() async -> UNAuthorizationStatus { status }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }

    func requests(prefix: String) -> [UNNotificationRequest] { added.filter { $0.identifier.hasPrefix(prefix) } }
}

@MainActor
struct NotificationDispatchTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let allOn = NotificationPreferences(
        severeAlertsEnabled: true, rainAlertsEnabled: true, dailyForecastEnabled: true,
        dailyForecastTime: Date(timeIntervalSince1970: 1_800_000_000)
    )

    private func makeDefaults() -> UserDefaults {
        let suite = "NotificationManagerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    /// A forecast whose first rainy hour starts `hoursAhead` hours after `now` (UTC timestamps).
    private func weather(rainInHours hoursAhead: Int?) -> WeatherData {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let times = (1...4).map { formatter.string(from: now.addingTimeInterval(Double($0) * 3600)) }
        let probabilities = (1...4).map { $0 == hoursAhead ? 90 : 0 }
        let json = """
        {"latitude": 1.0, "longitude": 1.0, "timezone": "UTC",
         "current": {"time": "\(times[0])", "temperature_2m": 50.0, "apparent_temperature": 50.0, "weather_code": 0,
            "is_day": 1, "precipitation": 0.0, "wind_speed_10m": 0.0, "wind_direction_10m": 0, "wind_gusts_10m": 0.0,
            "relative_humidity_2m": 0, "dew_point_2m": 0.0, "surface_pressure": 1000.0, "visibility": 10000,
            "uv_index": 0.0, "cloud_cover": 0},
         "hourly": {"time": \(times), "temperature_2m": [50.0, 50.0, 50.0, 50.0], "weather_code": [0, 0, 0, 0],
            "precipitation_probability": \(probabilities)},
         "daily": {"time": ["2026-02-14", "2026-02-15"], "weather_code": [0, 0],
            "temperature_2m_max": [60.0, 70.0], "temperature_2m_min": [40.0, 45.0],
            "sunrise": ["2026-02-14T07:00", "2026-02-15T07:00"], "sunset": ["2026-02-14T17:00", "2026-02-15T17:00"],
            "precipitation_probability_max": [0, 0], "uv_index_max": [0.0, 0.0],
            "wind_speed_10m_max": [0.0, 0.0], "wind_gusts_10m_max": [0.0, 0.0]}}
        """
        return try! OpenMeteoConfig.decoder.decode(WeatherData.self, from: Data(json.utf8))
    }

    private func alert(severity: String, event: String = "Tornado Warning") -> WeatherAlert {
        WeatherAlert(event: event, headline: "\(event) for your area", description: "", severity: severity,
                     urgency: "Immediate", areas: "Here", effective: now.addingTimeInterval(-600),
                     expires: now.addingTimeInterval(3600), senderName: "NWS")
    }

    // #100
    @Test func newSevereAlertNotifiesOnceEvenAfterRelaunch() async {
        let center = MockNotificationCenter()
        let defaults = makeDefaults()
        let first = NotificationManager(notificationCenter: center, defaults: defaults)
        let severe = alert(severity: "Severe")

        await first.handleWeatherUpdate(weather: weather(rainInHours: nil), alerts: [severe], locationName: "X", preferences: allOn, now: now)
        await first.handleWeatherUpdate(weather: weather(rainInHours: nil), alerts: [severe], locationName: "X", preferences: allOn, now: now)
        // a relaunch is a new manager over the same stored defaults
        let relaunched = NotificationManager(notificationCenter: center, defaults: defaults)
        await relaunched.handleWeatherUpdate(weather: weather(rainInHours: nil), alerts: [severe], locationName: "X", preferences: allOn, now: now)

        #expect(center.requests(prefix: "alert-").count == 1)
    }

    @Test func minorAlertsAndDisabledToggleSendNothing() async {
        let center = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: center, defaults: makeDefaults())
        var prefs = allOn

        await manager.handleWeatherUpdate(weather: weather(rainInHours: nil), alerts: [alert(severity: "Minor")], locationName: nil, preferences: prefs, now: now)
        prefs.severeAlertsEnabled = false
        await manager.handleWeatherUpdate(weather: weather(rainInHours: nil), alerts: [alert(severity: "Extreme")], locationName: nil, preferences: prefs, now: now)

        #expect(center.requests(prefix: "alert-").isEmpty)
    }

    @Test func nothingIsSentWithoutPermission() async {
        let center = MockNotificationCenter()
        center.status = .denied
        let manager = NotificationManager(notificationCenter: center, defaults: makeDefaults())

        await manager.handleWeatherUpdate(weather: weather(rainInHours: 1), alerts: [alert(severity: "Extreme")], locationName: nil, preferences: allOn, now: now)

        #expect(center.added.isEmpty)
    }

    // #101
    @Test func rainAlertFiresOncePerRainEvent() async {
        let center = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: center, defaults: makeDefaults())
        let rainy = weather(rainInHours: 1)

        await manager.handleWeatherUpdate(weather: rainy, alerts: [], locationName: "X", preferences: allOn, now: now)
        await manager.handleWeatherUpdate(weather: rainy, alerts: [], locationName: "X", preferences: allOn, now: now.addingTimeInterval(600))

        #expect(center.requests(prefix: "rain-").count == 1)
    }

    @Test func rainAlertIsOffWhenToggleIsOffOrNoRainComing() async {
        let center = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: center, defaults: makeDefaults())
        var prefs = allOn

        await manager.handleWeatherUpdate(weather: weather(rainInHours: nil), alerts: [], locationName: nil, preferences: prefs, now: now)
        prefs.rainAlertsEnabled = false
        await manager.handleWeatherUpdate(weather: weather(rainInHours: 1), alerts: [], locationName: nil, preferences: prefs, now: now)

        #expect(center.requests(prefix: "rain-").isEmpty)
    }

    // #102
    @Test func dailyForecastIsOneShotAtTheChosenTime() async throws {
        let center = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: center, defaults: makeDefaults())

        await manager.handleWeatherUpdate(weather: weather(rainInHours: nil), alerts: [], locationName: "X", preferences: allOn, now: now)

        let request = try #require(center.requests(prefix: "daily-forecast").first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.repeats == false)
        let chosen = Calendar.current.dateComponents([.hour, .minute], from: allOn.dailyForecastTime)
        #expect(trigger.dateComponents.hour == chosen.hour)
        #expect(trigger.dateComponents.minute == chosen.minute)
        let next = try #require(Calendar.current.nextDate(after: now, matching: chosen, matchingPolicy: .nextTime))
        #expect(Calendar.current.date(from: trigger.dateComponents) == Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: next)))
    }

    @Test func disablingDailyForecastCancelsIt() async {
        let center = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: center, defaults: makeDefaults())
        await manager.handleWeatherUpdate(weather: weather(rainInHours: nil), alerts: [], locationName: "X", preferences: allOn, now: now)
        #expect(center.requests(prefix: "daily-forecast").count == 1)

        var off = allOn
        off.dailyForecastEnabled = false
        await manager.preferencesChanged(off, now: now)

        #expect(center.requests(prefix: "daily-forecast").isEmpty)
    }

    @Test func changingTheTimeReschedulesWithoutANewFetch() async throws {
        let center = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: center, defaults: makeDefaults())
        await manager.handleWeatherUpdate(weather: weather(rainInHours: nil), alerts: [], locationName: "X", preferences: allOn, now: now)

        var later = allOn
        later.dailyForecastTime = allOn.dailyForecastTime.addingTimeInterval(2 * 3600)
        await manager.preferencesChanged(later, now: now)

        let request = try #require(center.requests(prefix: "daily-forecast").first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.hour == Calendar.current.component(.hour, from: later.dailyForecastTime))
        #expect(center.requests(prefix: "daily-forecast").count == 1)
    }
}
