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
    
    /// Medium impact haptic generator — created on demand (less commonly used)
    private static var _medium: UIImpactFeedbackGenerator?
    private static var mediumGenerator: UIImpactFeedbackGenerator {
        if let existing = _medium { return existing }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        _medium = generator
        return generator
    }
    
    /// Heavy impact haptic generator — created on demand (less commonly used)
    private static var _heavy: UIImpactFeedbackGenerator?
    private static var heavyGenerator: UIImpactFeedbackGenerator {
        if let existing = _heavy { return existing }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        _heavy = generator
        return generator
    }
    
    /// Notification feedback generator — created on demand (less commonly used)
    private static var _notification: UINotificationFeedbackGenerator?
    private static var notificationGenerator: UINotificationFeedbackGenerator {
        if let existing = _notification { return existing }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        _notification = generator
        return generator
    }
    
    /// Trigger a light haptic impact (default)
    static func impact() {
        light.impactOccurred()
    }
    
    /// Trigger a medium haptic impact
    static func mediumImpact() {
        mediumGenerator.impactOccurred()
    }
    
    /// Trigger a heavy haptic impact
    static func heavyImpact() {
        heavyGenerator.impactOccurred()
    }
    
    /// Trigger a success notification haptic
    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Trigger an error notification haptic
    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Trigger a warning notification haptic
    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
}
