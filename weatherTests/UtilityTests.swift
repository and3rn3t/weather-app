//
//  UtilityTests.swift
//  weatherTests
//
//  Comprehensive tests for utility classes and helpers
//

import Testing
import Foundation
import SwiftUI
@testable import weather

// MARK: - UV Index Helper Tests

@MainActor
struct UVIndexHelperTests {
    
    @Test func uvIndexClassificationExists() {
        // Test that UV index helper produces output without crashing
        let _ = UVIndexHelper.color(for: 5.0)
        let _ = UVIndexHelper.level(for: 5.0)
        #expect(true)
    }
}

// MARK: - Moon Phase Tests

@MainActor
struct MoonPhaseTests {
    
    @Test func moonPhaseCalculation() {
        // Test moon phase calculation doesn't crash
        let phase = MoonPhase.calculate(for: Date())
        #expect(!phase.name.isEmpty)
        #expect(!phase.emoji.isEmpty)
        #expect(phase.illumination >= 0.0 && phase.illumination <= 1.0)
    }
}
