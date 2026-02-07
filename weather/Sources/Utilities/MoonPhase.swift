//
//  MoonPhase.swift
//  weather
//
//  Created by GitHub Copilot on 2/6/26.
//

import Foundation

/// Represents the current phase of the moon
struct MoonPhase {
    let name: String
    let illumination: Double // 0.0 to 1.0
    let emoji: String
    
    /// Calculate current moon phase based on current date
    static func current() -> MoonPhase {
        let date = Date()
        return calculate(for: date)
    }
    
    /// Calculate moon phase for a specific date
    static func calculate(for date: Date) -> MoonPhase {
        // Known new moon: January 1, 2000 at 18:14 UTC
        let knownNewMoon = Date(timeIntervalSince1970: 946744440) // Jan 1, 2000, 18:14 UTC
        let lunarCycle = 29.53059 // Days in a lunar cycle
        
        let daysSinceNewMoon = date.timeIntervalSince(knownNewMoon) / 86400
        let phase = daysSinceNewMoon.truncatingRemainder(dividingBy: lunarCycle)
        
        let illumination: Double
        let name: String
        let emoji: String
        
        switch phase {
        case 0..<1.84566:
            name = "New Moon"
            emoji = "🌑"
            illumination = phase / 14.765
            
        case 1.84566..<5.53699:
            name = "Waxing Crescent"
            emoji = "🌒"
            illumination = 0.25 + ((phase - 1.84566) / 14.765 * 0.25)
            
        case 5.53699..<9.22831:
            name = "First Quarter"
            emoji = "🌓"
            illumination = 0.50
            
        case 9.22831..<12.91963:
            name = "Waxing Gibbous"
            emoji = "🌔"
            illumination = 0.50 + ((phase - 9.22831) / 14.765 * 0.50)
            
        case 12.91963..<16.61096:
            name = "Full Moon"
            emoji = "🌕"
            illumination = 1.0
            
        case 16.61096..<20.30228:
            name = "Waning Gibbous"
            emoji = "🌖"
            illumination = 1.0 - ((phase - 16.61096) / 14.765 * 0.50)
            
        case 20.30228..<23.99361:
            name = "Last Quarter"
            emoji = "🌗"
            illumination = 0.50
            
        case 23.99361..<29.53059:
            name = "Waning Crescent"
            emoji = "🌘"
            illumination = 0.50 - ((phase - 23.99361) / 14.765 * 0.50)
            
        default:
            name = "Unknown"
            emoji = "🌑"
            illumination = 0.0
        }
        
        return MoonPhase(name: name, illumination: max(0, min(1, illumination)), emoji: emoji)
    }
}
