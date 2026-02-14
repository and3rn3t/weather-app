//
//  HistoricalWeatherModels.swift
//  weather
//
//  Created by AI Assistant on 2/14/26.
//

import Foundation

// MARK: - Weather Comparison Result

/// Comparison between current and historical weather
struct WeatherComparison: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let currentTemp: Double
    let historicalTemp: Double
    let difference: Double
    let currentCondition: WeatherCondition
    let historicalCondition: WeatherCondition
    let currentPrecipitation: Double
    let historicalPrecipitation: Double
    
    var isCooler: Bool {
        currentTemp < historicalTemp
    }
    
    var isWarmer: Bool {
        currentTemp > historicalTemp
    }
    
    var isSimilar: Bool {
        abs(difference) < 5.0
    }
    
    var comparisonText: String {
        if isSimilar {
            return "Similar to last year"
        } else if isCooler {
            return "\(Int(abs(difference)))° cooler than last year"
        } else {
            return "\(Int(abs(difference)))° warmer than last year"
        }
    }
}
