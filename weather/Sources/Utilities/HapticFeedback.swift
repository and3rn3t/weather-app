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
    
    /// Medium impact haptic generator
    static let medium: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()
    
    /// Heavy impact haptic generator
    static let heavy: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        return generator
    }()
    
    /// Notification feedback generator for success/error/warning
    static let notification: UINotificationFeedbackGenerator = {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        return generator
    }()
    
    /// Trigger a light haptic impact (default)
    static func impact() {
        light.impactOccurred()
    }
    
    /// Trigger a medium haptic impact
    static func mediumImpact() {
        medium.impactOccurred()
    }
    
    /// Trigger a heavy haptic impact
    static func heavyImpact() {
        heavy.impactOccurred()
    }
    
    /// Trigger a success notification haptic
    static func success() {
        notification.notificationOccurred(.success)
    }
    
    /// Trigger an error notification haptic
    static func error() {
        notification.notificationOccurred(.error)
    }
    
    /// Trigger a warning notification haptic
    static func warning() {
        notification.notificationOccurred(.warning)
    }
}
