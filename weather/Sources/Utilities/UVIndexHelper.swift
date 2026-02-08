//
//  UVIndexHelper.swift
//  weather
//
//  Shared UV index color and level helpers to avoid duplication.
//

import SwiftUI

// MARK: - UV Index Helper

/// Centralized UV index color and level information
enum UVIndexHelper {
    /// Returns the display color for a given UV index value
    static func color(for uvIndex: Double) -> Color {
        switch uvIndex {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
    }
    
    /// Returns the human-readable level string for a given UV index value
    static func level(for uvIndex: Double) -> String {
        switch uvIndex {
        case 0..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
        }
    }
}
