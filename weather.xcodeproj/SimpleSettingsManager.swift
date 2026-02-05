//
//  SimpleSettingsManager.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import Foundation
import SwiftUI

// MARK: - Settings Manager (Simplified & Working)

@Observable
final class SimpleSettingsManager {
    // Unit Preferences
    var useCelsius: Bool {
        didSet { UserDefaults.standard.set(useCelsius, forKey: "useCelsius") }
    }
    
    var showAnimatedBackgrounds: Bool {
        didSet { UserDefaults.standard.set(showAnimatedBackgrounds, forKey: "showAnimatedBackgrounds") }
    }
    
    var showWeatherParticles: Bool {
        didSet { UserDefaults.standard.set(showWeatherParticles, forKey: "showWeatherParticles") }
    }
    
    var showFeelsLike: Bool {
        didSet { UserDefaults.standard.set(showFeelsLike, forKey: "showFeelsLike") }
    }
    
    init() {
        self.useCelsius = UserDefaults.standard.object(forKey: "useCelsius") as? Bool ?? false
        self.showAnimatedBackgrounds = UserDefaults.standard.object(forKey: "showAnimatedBackgrounds") as? Bool ?? true
        self.showWeatherParticles = UserDefaults.standard.object(forKey: "showWeatherParticles") as? Bool ?? true
        self.showFeelsLike = UserDefaults.standard.object(forKey: "showFeelsLike") as? Bool ?? true
    }
    
    // MARK: - Formatting Helpers
    
    func formatTemperature(_ fahrenheit: Double) -> String {
        if useCelsius {
            let celsius = (fahrenheit - 32) * 5 / 9
            return "\(Int(celsius))°C"
        } else {
            return "\(Int(fahrenheit))°F"
        }
    }
    
    func formatWindSpeed(_ mph: Double) -> String {
        return "\(Int(mph)) mph"
    }
    
    func formatPrecipitation(_ inches: Double) -> String {
        return String(format: "%.2f in", inches)
    }
}
