//
//  HapticFeedback.swift
//  weather
//
//  Shared haptic feedback generator to avoid duplicate declarations.
//

import UIKit

// MARK: - Haptic Feedback

/// Centralized haptic feedback generator — avoids allocating a new one per view
enum HapticFeedback {
    /// Light impact haptic generator, pre-warmed for immediate response
    static let light: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()
    
    /// Trigger a light haptic impact
    static func impact() {
        light.impactOccurred()
    }
}
