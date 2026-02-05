//
//  GlassEffects.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI

// MARK: - Glass Effect View Modifier

struct GlassEffect: ViewModifier {
    var style: GlassStyle
    
    func body(content: Content) -> some View {
        content
            .background(style.material, in: RoundedRectangle(cornerRadius: style.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(style.borderOpacity),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: style.borderWidth
                    )
            }
            .shadow(color: style.shadowColor, radius: style.shadowRadius, x: 0, y: style.shadowY)
    }
}

// MARK: - Glass Style Configuration

struct GlassStyle {
    var material: Material
    var cornerRadius: CGFloat
    var borderWidth: CGFloat
    var borderOpacity: Double
    var shadowColor: Color
    var shadowRadius: CGFloat
    var shadowY: CGFloat
    var tint: Color?
    var isInteractive: Bool
    
    static let regular = GlassStyle(
        material: .ultraThinMaterial,
        cornerRadius: 20,
        borderWidth: 1,
        borderOpacity: 0.3,
        shadowColor: .black.opacity(0.1),
        shadowRadius: 10,
        shadowY: 5,
        tint: nil,
        isInteractive: false
    )
    
    static let prominent = GlassStyle(
        material: .thinMaterial,
        cornerRadius: 20,
        borderWidth: 1.5,
        borderOpacity: 0.4,
        shadowColor: .black.opacity(0.15),
        shadowRadius: 15,
        shadowY: 8,
        tint: nil,
        isInteractive: false
    )
    
    static let thick = GlassStyle(
        material: .regularMaterial,
        cornerRadius: 20,
        borderWidth: 2,
        borderOpacity: 0.5,
        shadowColor: .black.opacity(0.2),
        shadowRadius: 20,
        shadowY: 10,
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

// MARK: - View Extension

extension View {
    func glassEffect(_ style: GlassStyle = .regular) -> some View {
        modifier(GlassEffect(style: style))
    }
    
    func glassEffectID(_ id: String, in namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }
}

// MARK: - Glass Effect Container

struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    
    init(spacing: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(spacing)
            .glassEffect(.regular)
    }
}

// MARK: - Glass Button Styles

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct GlassProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thinMaterial)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .blue.opacity(0.4),
                                    .blue.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
}

extension ButtonStyle where Self == GlassProminentButtonStyle {
    static var glassProminent: GlassProminentButtonStyle { GlassProminentButtonStyle() }
}
