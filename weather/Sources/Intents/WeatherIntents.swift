//
//  WeatherIntents.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import AppIntents
import CoreLocation
import MapKit
import SwiftUI

// MARK: - Get Current Weather Intent

struct GetWeatherIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Current Weather"
    static var description = IntentDescription("Get the current weather conditions for your location or a specified city.")
    
    @Parameter(title: "Location", description: "The city to get weather for. Uses your current location if not specified.")
    var locationName: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get weather for \(\.$locationName)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Get coordinates for location
        let (latitude, longitude, resolvedName) = try await resolveLocation()
        
        // Create WeatherService on MainActor and fetch weather
        let weatherService = await MainActor.run { WeatherService() }
        await weatherService.fetchWeather(
            latitude: latitude,
            longitude: longitude,
            locationName: resolvedName
        )
        
        // Access weatherData on MainActor
        let weatherData = await MainActor.run { weatherService.weatherData }
        
        guard let weatherData else {
            throw WeatherIntentError.fetchFailed
        }
        
        let conditionCode = weatherData.current.weatherCode
        let temp = Int(weatherData.current.temperature2m)
        let feelsLike = Int(weatherData.current.apparentTemperature)
        let high = Int(weatherData.daily.temperature2mMax.first ?? 0)
        let low = Int(weatherData.daily.temperature2mMin.first ?? 0)
        
        let conditionDescription = weatherConditionDescription(for: conditionCode)
        
        let dialog = """
        It's currently \(temp)°F and \(conditionDescription.lowercased()) in \(resolvedName ?? "your location"). \
        It feels like \(feelsLike)°F with a high of \(high)°F and low of \(low)°F today.
        """
        
        return await MainActor.run {
            .result(
                dialog: IntentDialog(stringLiteral: dialog),
                view: WeatherSnippetView(
                    temperature: temp,
                    condition: WeatherConditionSnippet(code: conditionCode),
                    locationName: resolvedName ?? "Current Location",
                    high: high,
                    low: low
                )
            )
        }
    }
    
    private func weatherConditionDescription(for code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2: return "Partly Cloudy"
        case 3: return "Cloudy"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65, 80, 81, 82: return "Rainy"
        case 71, 73, 75, 77, 85, 86: return "Snowy"
        case 95, 96, 99: return "Stormy"
        default: return "Unknown"
        }
    }
    
    private func resolveLocation() async throws -> (Double, Double, String?) {
        if let name = locationName, !name.isEmpty {
            // Geocode the provided location name using MapKit
            guard let request = MKGeocodingRequest(addressString: name) else {
                throw WeatherIntentError.locationNotFound
            }
            
            let mapItems = try await request.mapItems
            
            guard let mapItem = mapItems.first else {
                throw WeatherIntentError.locationNotFound
            }
            
            let location = mapItem.location
            // Use address.city for the city name
            let resolvedName = mapItem.name ?? mapItem.address?.city ?? name
            return (location.coordinate.latitude, location.coordinate.longitude, resolvedName)
        } else {
            // Use current location
            let locationProvider = await MainActor.run { IntentLocationProvider() }
            let location = try await locationProvider.getCurrentLocation()
            return (location.coordinate.latitude, location.coordinate.longitude, nil)
        }
    }
}

// MARK: - Will It Rain Intent

struct WillItRainIntent: AppIntent {
    static var title: LocalizedStringResource = "Will It Rain Today"
    static var description = IntentDescription("Check if rain is expected today at your location.")
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let locationProvider = await MainActor.run { IntentLocationProvider() }
        
        // Get current location
        let location = try await locationProvider.getCurrentLocation()
        
        // Create WeatherService on MainActor and fetch weather
        let weatherService = await MainActor.run { WeatherService() }
        await weatherService.fetchWeather(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            locationName: nil
        )
        
        // Access weatherData on MainActor
        let weatherData = await MainActor.run { weatherService.weatherData }
        
        guard let weatherData else {
            throw WeatherIntentError.fetchFailed
        }
        
        // Check precipitation probability for today
        let todayPrecipProb = weatherData.daily.precipitationProbabilityMax.first ?? 0
        
        let dialog: String
        if todayPrecipProb >= 70 {
            dialog = "Yes, there's a \(todayPrecipProb)% chance of rain today. You should bring an umbrella! ☔️"
        } else if todayPrecipProb >= 40 {
            dialog = "Maybe. There's a \(todayPrecipProb)% chance of rain today. You might want to keep an umbrella handy."
        } else if todayPrecipProb > 0 {
            dialog = "Probably not. There's only a \(todayPrecipProb)% chance of rain today."
        } else {
            dialog = "No rain is expected today. Enjoy the dry weather! ☀️"
        }
        
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

// MARK: - Get Temperature Intent

struct GetTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Current Temperature"
    static var description = IntentDescription("Get just the current temperature.")
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let locationProvider = await MainActor.run { IntentLocationProvider() }
        
        let location = try await locationProvider.getCurrentLocation()
        
        // Create WeatherService on MainActor and fetch weather
        let weatherService = await MainActor.run { WeatherService() }
        await weatherService.fetchWeather(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            locationName: nil
        )
        
        // Access weatherData on MainActor
        let weatherData = await MainActor.run { weatherService.weatherData }
        
        guard let weatherData else {
            throw WeatherIntentError.fetchFailed
        }
        
        let temp = Int(weatherData.current.temperature2m)
        let feelsLike = Int(weatherData.current.apparentTemperature)
        
        let dialog = "It's currently \(temp)°F, and it feels like \(feelsLike)°F."
        
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

// MARK: - App Shortcuts Provider

struct WeatherAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetWeatherIntent(),
            phrases: [
                "What's the weather in \(.applicationName)",
                "Get weather from \(.applicationName)",
                "Current weather \(.applicationName)",
                "How's the weather \(.applicationName)",
                "\(.applicationName) weather"
            ],
            shortTitle: "Current Weather",
            systemImageName: "cloud.sun.fill"
        )
        
        AppShortcut(
            intent: WillItRainIntent(),
            phrases: [
                "Will it rain today \(.applicationName)",
                "Is it going to rain \(.applicationName)",
                "Do I need an umbrella \(.applicationName)",
                "Rain forecast \(.applicationName)"
            ],
            shortTitle: "Rain Forecast",
            systemImageName: "cloud.rain.fill"
        )
        
        AppShortcut(
            intent: GetTemperatureIntent(),
            phrases: [
                "What's the temperature \(.applicationName)",
                "How hot is it \(.applicationName)",
                "How cold is it \(.applicationName)",
                "Current temperature \(.applicationName)"
            ],
            shortTitle: "Temperature",
            systemImageName: "thermometer.medium"
        )
    }
}

// MARK: - Supporting Types

enum WeatherIntentError: Error, CustomLocalizedStringResourceConvertible {
    case fetchFailed
    case locationNotFound
    case locationAccessDenied
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .fetchFailed:
            return "Unable to fetch weather data. Please try again."
        case .locationNotFound:
            return "Could not find that location. Please try a different city name."
        case .locationAccessDenied:
            return "Location access is required. Please enable location in Settings."
        }
    }
}

// Helper to get current location for intents
class IntentLocationProvider: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    
    func getCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            continuation?.resume(returning: location)
            continuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: WeatherIntentError.locationAccessDenied)
        continuation = nil
    }
}
