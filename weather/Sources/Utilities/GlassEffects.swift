//
//  GlassEffects.swift
//  weather
//
//  Created by Matt on 2/5/26.
//
//  Updated for iOS 26 Liquid Glass HIG
//

import SwiftUI

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

// MARK: - Legacy Button Styles (For Custom Needs)

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
