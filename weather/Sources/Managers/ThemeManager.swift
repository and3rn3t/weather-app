//
//  ThemeManager.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI

// MARK: - Theme Manager

@Observable
class ThemeManager {
    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }
    
    var useAdaptiveTheme: Bool {
        didSet {
            UserDefaults.standard.set(useAdaptiveTheme, forKey: "useAdaptiveTheme")
        }
    }
    
    init() {
        if let themeName = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeName) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .classic
        }
        
        self.useAdaptiveTheme = UserDefaults.standard.bool(forKey: "useAdaptiveTheme")
    }
    
    // Get theme adapted to weather conditions
    func adaptiveTheme(for weatherCode: Int, isDay: Bool) -> AppTheme {
        guard useAdaptiveTheme else { return currentTheme }
        
        let condition = WeatherCondition(code: weatherCode)
        
        switch condition {
        case .clearSky:
            return isDay ? .sunset : .midnight
        case .partlyCloudy, .cloudy:
            return .storm
        case .foggy:
            return .fog
        case .drizzle, .rain:
            return .ocean
        case .snow:
            return .arctic
        case .thunderstorm:
            return .storm
        case .unknown:
            return currentTheme
        }
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case ocean = "Ocean"
    case sunset = "Sunset"
    case forest = "Forest"
    case midnight = "Midnight"
    case arctic = "Arctic"
    case storm = "Storm"
    case fog = "Fog"
    
    var id: String { rawValue }
    
    // Primary gradient colors
    var gradientColors: [Color] {
        switch self {
        case .classic:
            return [.blue, .purple]
        case .ocean:
            return [Color(red: 0.0, green: 0.3, blue: 0.5), 
                    Color(red: 0.0, green: 0.5, blue: 0.7),
                    Color(red: 0.2, green: 0.6, blue: 0.8)]
        case .sunset:
            return [Color(red: 1.0, green: 0.4, blue: 0.3),
                    Color(red: 1.0, green: 0.6, blue: 0.2),
                    Color(red: 0.9, green: 0.3, blue: 0.5)]
        case .forest:
            return [Color(red: 0.1, green: 0.3, blue: 0.2),
                    Color(red: 0.2, green: 0.5, blue: 0.3),
                    Color(red: 0.3, green: 0.6, blue: 0.4)]
        case .midnight:
            return [Color(red: 0.05, green: 0.05, blue: 0.2),
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.15, green: 0.1, blue: 0.35)]
        case .arctic:
            return [Color(red: 0.7, green: 0.85, blue: 0.95),
                    Color(red: 0.8, green: 0.9, blue: 1.0),
                    Color(red: 0.6, green: 0.75, blue: 0.9)]
        case .storm:
            return [Color(red: 0.2, green: 0.2, blue: 0.3),
                    Color(red: 0.3, green: 0.3, blue: 0.4),
                    Color(red: 0.25, green: 0.25, blue: 0.35)]
        case .fog:
            return [Color(red: 0.6, green: 0.65, blue: 0.7),
                    Color(red: 0.7, green: 0.75, blue: 0.8),
                    Color(red: 0.65, green: 0.7, blue: 0.75)]
        }
    }
    
    // Accent color for UI elements
    var accentColor: Color {
        switch self {
        case .classic: return .blue
        case .ocean: return .cyan
        case .sunset: return .orange
        case .forest: return .green
        case .midnight: return .purple
        case .arctic: return .cyan
        case .storm: return .gray
        case .fog: return .gray
        }
    }
    
    // Text color that contrasts with background
    var textColor: Color {
        switch self {
        case .arctic, .fog:
            return .black
        default:
            return .white
        }
    }
    
    // Secondary text color
    var secondaryTextColor: Color {
        switch self {
        case .arctic, .fog:
            return .black.opacity(0.7)
        default:
            return .white.opacity(0.8)
        }
    }
    
    // Card background style
    var cardMaterial: Material {
        switch self {
        case .arctic, .fog:
            return .regularMaterial
        default:
            return .ultraThinMaterial
        }
    }
    
    // Icon for theme picker
    var icon: String {
        switch self {
        case .classic: return "paintpalette"
        case .ocean: return "water.waves"
        case .sunset: return "sun.horizon.fill"
        case .forest: return "leaf.fill"
        case .midnight: return "moon.stars.fill"
        case .arctic: return "snowflake"
        case .storm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        }
    }
    
    // Preview colors for theme picker
    var previewColors: [Color] {
        Array(gradientColors.prefix(3))
    }
}

// MARK: - Theme Gradient View

struct ThemeGradient: View {
    let theme: AppTheme
    var animated: Bool = true
    
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: theme.gradientColors,
            startPoint: animated && animateGradient ? .topLeading : .top,
            endPoint: animated && animateGradient ? .bottomTrailing : .bottom
        )
        .ignoresSafeArea()
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }
        }
    }
}

// MARK: - Theme Picker View

struct ThemePickerView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Adaptive Theme", isOn: Bindable(themeManager).useAdaptiveTheme)
                } footer: {
                    Text("Automatically adjusts theme based on current weather conditions.")
                }
                
                Section("Themes") {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeRow(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme,
                            action: {
                                withAnimation {
                                    themeManager.currentTheme = theme
                                }
                            }
                        )
                    }
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Theme Row

struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Theme preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: theme.previewColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: theme.icon)
                        .font(.title3)
                        .foregroundStyle(theme.textColor)
                }
                
                // Theme name
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(themeDescription(for: theme))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .classic: return "Default blue to purple gradient"
        case .ocean: return "Deep sea blues and teals"
        case .sunset: return "Warm oranges and reds"
        case .forest: return "Natural greens"
        case .midnight: return "Dark purple night sky"
        case .arctic: return "Cool ice blues"
        case .storm: return "Moody grays"
        case .fog: return "Soft misty tones"
        }
    }
}

#Preview("Theme Picker") {
    ThemePickerView()
        .environment(ThemeManager())
}

#Preview("Theme Gradient") {
    VStack {
        ForEach(AppTheme.allCases) { theme in
            ThemeGradient(theme: theme, animated: false)
                .frame(height: 80)
                .overlay {
                    Text(theme.rawValue)
                        .foregroundStyle(theme.textColor)
                        .font(.headline)
                }
        }
    }
}
