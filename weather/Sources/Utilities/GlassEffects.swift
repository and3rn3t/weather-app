//
//  GlassEffects.swift
//  weather
//
//  Created by Matt on 2/5/26.
//
//  Updated for iOS 26 Liquid Glass HIG
//

import SwiftUI

// MARK: - iOS 26 Floating Tab Bar

/// Floating tab bar in iOS 26 style
struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, label: String)]
    
    @Namespace private var tabNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                TabBarButton(
                    icon: tab.icon,
                    label: tab.label,
                    isSelected: selectedTab == index,
                    namespace: tabNamespace
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .glassEffect(Glass.regular, in: .capsule)
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)
                
                Text(label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Prominent Glass Section Header

struct GlassSectionHeader: View {
    let title: String
    let icon: String?
    
    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Glass List Row

struct GlassListRow<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(Glass.regular, in: .rect(cornerRadius: 12))
    }
}

// MARK: - Legacy Compatibility - GlassStyle Configuration

/// Legacy GlassStyle for backward compatibility with custom effects
struct GlassStyle {
    var cornerRadius: CGFloat
    var tint: Color?
    var isInteractive: Bool
    
    static let regular = GlassStyle(
        cornerRadius: 20,
        tint: nil,
        isInteractive: false
    )
    
    static let prominent = GlassStyle(
        cornerRadius: 20,
        tint: nil,
        isInteractive: false
    )
    
    static let thick = GlassStyle(
        cornerRadius: 20,
        tint: nil,
        isInteractive: false
    )
    
    func tint(_ color: Color) -> GlassStyle {
        var style = self
        style.tint = color
        return style
    }
    
    func interactive() -> GlassStyle {
        var style = self
        style.isInteractive = true
        return style
    }
    
    func cornerRadius(_ radius: CGFloat) -> GlassStyle {
        var style = self
        style.cornerRadius = radius
        return style
    }
}

// MARK: - View Extension for iOS 26 Liquid Glass

extension View {
    /// Legacy glass effect using custom GlassStyle (maps to native iOS 26)
    @ViewBuilder
    func glassEffect(_ style: GlassStyle) -> some View {
        if let tint = style.tint {
            self
                .background(tint)
                .glassEffect(Glass.regular, in: .rect(cornerRadius: style.cornerRadius))
        } else {
            self
                .glassEffect(Glass.regular, in: .rect(cornerRadius: style.cornerRadius))
        }
    }
    
    /// Legacy glass effect with shape (maps to native iOS 26)
    @ViewBuilder
    func glassEffect<S: Shape>(_ style: GlassStyle, in shape: S) -> some View {
        if let tint = style.tint {
            self
                .background(tint)
                .glassEffect(Glass.regular, in: shape)
        } else {
            self
                .glassEffect(Glass.regular, in: shape)
        }
    }
    
    /// Helper for matched geometry in glass transitions
    func glassEffectID(_ id: String, in namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }
}

// MARK: - Glass Effect Container (Native iOS 26)

/// Glass effect container using native iOS 26 Liquid Glass
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(spacing)
            .glassEffect(Glass.regular, in: .rect(cornerRadius: 24))
    }
}

/// Alternative naming for clarity
typealias LiquidGlassContainer = GlassEffectContainer

// MARK: - Legacy Button Styles (For Custom Needs)

/// Custom glass button style with additional animation
struct CustomGlassButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .glassEffect(Glass.regular, in: .rect(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Custom prominent glass button style with blue tint
struct CustomGlassProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.3))
            }
            .glassEffect(Glass.regular, in: .rect(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CustomGlassButtonStyle {
    static var customGlass: CustomGlassButtonStyle { CustomGlassButtonStyle() }
}

extension ButtonStyle where Self == CustomGlassProminentButtonStyle {
    static var customGlassProminent: CustomGlassProminentButtonStyle { CustomGlassProminentButtonStyle() }
}

// MARK: - Previews

#Preview("Glass Components") {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weather")
                    .font(.headline)
                Text("72°F - Sunny")
                    .font(.largeTitle.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassEffect(Glass.regular, in: .rect(cornerRadius: 20))
            
            HStack(spacing: 16) {
                Button("Glass") {}
                    .buttonStyle(.glass)
                
                Button("Prominent") {}
                    .buttonStyle(.glassProminent)
            }
        }
        .padding()
    }
}

#Preview("Floating Tab Bar") {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            FloatingTabBar(
                selectedTab: .constant(0),
                tabs: [
                    (icon: "house.fill", label: "Home"),
                    (icon: "map", label: "Map"),
                    (icon: "heart.fill", label: "Favorites"),
                    (icon: "gear", label: "Settings")
                ]
            )
        }
    }
}
