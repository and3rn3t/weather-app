//
//  PollenModels.swift
//  weather
//
//  Created by AI Assistant on 2/14/26.
//

import Foundation
import SwiftUI

// MARK: - Pollen Data Models

/// Pollen forecast data from Open-Meteo Air Quality API
struct PollenData: Codable, Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let hourly: HourlyPollen?
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude, timezone, hourly
    }
}

struct HourlyPollen: Codable, Sendable, Equatable {
    let time: [String]
    let grassPollen: [Double]?
    let birchPollen: [Double]?
    let olivePollen: [Double]?
    let ragweedPollen: [Double]?
    
    enum CodingKeys: String, CodingKey {
        case time
        case grassPollen = "grass_pollen"
        case birchPollen = "birch_pollen"
        case olivePollen = "olive_pollen"
        case ragweedPollen = "ragweed_pollen"
    }
    
    /// Get the maximum pollen concentration for a given range
    func maxPollenInRange(start: Int, count: Int) -> (type: PollenType, value: Double)? {
        var maxValue: Double = 0
        var maxType: PollenType = .grass
        
        let range = start..<min(start + count, time.count)
        
        if let grass = grassPollen {
            let maxGrass = grass[range].max() ?? 0
            if maxGrass > maxValue {
                maxValue = maxGrass
                maxType = .grass
            }
        }
        
        if let birch = birchPollen {
            let maxBirch = birch[range].max() ?? 0
            if maxBirch > maxValue {
                maxValue = maxBirch
                maxType = .birch
            }
        }
        
        if let olive = olivePollen {
            let maxOlive = olive[range].max() ?? 0
            if maxOlive > maxValue {
                maxValue = maxOlive
                maxType = .olive
            }
        }
        
        if let ragweed = ragweedPollen {
            let maxRagweed = ragweed[range].max() ?? 0
            if maxRagweed > maxValue {
                maxValue = maxRagweed
                maxType = .ragweed
            }
        }
        
        return maxValue > 0 ? (maxType, maxValue) : nil
    }
}

// MARK: - Pollen Type

enum PollenType: String, CaseIterable {
    case grass = "Grass"
    case birch = "Birch"
    case olive = "Olive"
    case ragweed = "Ragweed"
    
    var icon: String {
        switch self {
        case .grass: return "leaf.fill"
        case .birch: return "tree.fill"
        case .olive: return "tree"
        case .ragweed: return "allergens"
        }
    }
    
    var color: Color {
        switch self {
        case .grass: return .green
        case .birch: return .brown
        case .olive: return .green.mix(with: .brown, by: 0.5)
        case .ragweed: return .yellow
        }
    }
}

// MARK: - Pollen Level

enum PollenLevel {
    case none
    case low
    case moderate
    case high
    case veryHigh
    
    init(concentration: Double) {
        switch concentration {
        case 0: self = .none
        case 0..<10: self = .low
        case 10..<50: self = .moderate
        case 50..<100: self = .high
        default: self = .veryHigh
        }
    }
    
    var name: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
    
    var advice: String {
        switch self {
        case .none:
            return "No pollen detected. Great day for outdoor activities."
        case .low:
            return "Low pollen levels. Most people won't be affected."
        case .moderate:
            return "Moderate pollen. Sensitive individuals may experience symptoms."
        case .high:
            return "High pollen levels. Take precautions if you have allergies."
        case .veryHigh:
            return "Very high pollen. Stay indoors if possible and take medication."
        }
    }
}
