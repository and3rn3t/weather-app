//
//  WindCompassView.swift
//  weather
//
//  Created by Matt on 2/7/26.
//

import SwiftUI

// MARK: - Wind Compass Card

struct WindCompassCard: View {
    let current: CurrentWeather
    @Environment(SettingsManager.self) private var settings
    @State private var isVisible = false
    @State private var needleAnimated = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Wind Compass")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Text(windBeaufortDescription)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(windStrengthColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(windStrengthColor.opacity(0.2), in: Capsule())
            }
            
            ZStack {
                // Compass rose
                WindCompassRose(
                    windDirection: current.windDirection10m,
                    windSpeed: settings.convertedWindSpeed(current.windSpeed10m),
                    windGusts: settings.convertedWindSpeed(current.windGusts10m),
                    windUnit: settings.windSpeedUnit.symbol,
                    isVisible: isVisible,
                    needleAnimated: needleAnimated
                )
                .frame(width: 220, height: 220)
            }
            .padding(.vertical, 8)
            
            // Wind stats row
            HStack(spacing: 0) {
                WindStatItem(
                    title: "Speed",
                    value: settings.formatWindSpeed(current.windSpeed10m),
                    icon: "wind",
                    color: .cyan
                )
                
                Divider()
                    .frame(height: 50)
                    .padding(.horizontal, 8)
                
                WindStatItem(
                    title: "Gusts",
                    value: settings.formatWindSpeed(current.windGusts10m),
                    icon: "tornado",
                    color: .orange
                )
                
                Divider()
                    .frame(height: 50)
                    .padding(.horizontal, 8)
                
                WindStatItem(
                    title: "Direction",
                    value: "\(compassDirection)  \(Int(current.windDirection10m))°",
                    icon: "safari",
                    color: .blue
                )
            }
        }
        .padding(20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                isVisible = true
            }
            withAnimation(.spring(response: 1.2, dampingFraction: 0.6).delay(0.5)) {
                needleAnimated = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Wind compass. Wind from \(compassDirection) at \(settings.formatWindSpeed(current.windSpeed10m)), gusting to \(settings.formatWindSpeed(current.windGusts10m))")
    }
    
    // MARK: - Computed Properties
    
    private var compassDirection: String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((current.windDirection10m + 11.25) / 22.5) % 16
        return directions[index]
    }
    
    private var windBeaufortDescription: String {
        // Beaufort scale (based on mph from API)
        let speed = current.windSpeed10m
        switch speed {
        case ..<1: return "Calm"
        case 1..<4: return "Light Air"
        case 4..<8: return "Light Breeze"
        case 8..<13: return "Gentle Breeze"
        case 13..<19: return "Moderate"
        case 19..<25: return "Fresh Breeze"
        case 25..<32: return "Strong Breeze"
        case 32..<39: return "Near Gale"
        case 39..<47: return "Gale"
        case 47..<55: return "Strong Gale"
        case 55..<64: return "Storm"
        case 64..<73: return "Violent Storm"
        default: return "Hurricane"
        }
    }
    
    private var windStrengthColor: Color {
        let speed = current.windSpeed10m
        switch speed {
        case ..<8: return .green
        case 8..<19: return .cyan
        case 19..<32: return .yellow
        case 32..<47: return .orange
        default: return .red
        }
    }
}

// MARK: - Compass Rose Drawing

struct WindCompassRose: View {
    let windDirection: Double
    let windSpeed: Double
    let windGusts: Double
    let windUnit: String
    let isVisible: Bool
    let needleAnimated: Bool
    
    private let cardinalDirections = ["N", "E", "S", "W"]
    private let ordinalDirections = ["NE", "SE", "SW", "NW"]
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 10
            
            ZStack {
                // Outer ring with gust zone
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 18)
                
                // Speed arc (shows current speed as proportion of gusts)
                if windGusts > 0 {
                    Circle()
                        .trim(from: 0, to: isVisible ? min(windSpeed / max(windGusts * 1.2, 1), 1.0) : 0)
                        .stroke(
                            AngularGradient(
                                colors: [.cyan, .blue, .cyan],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                
                // Inner circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: radius * 1.1, height: radius * 1.1)
                
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    .frame(width: radius * 1.1, height: radius * 1.1)
                
                // Tick marks
                ForEach(0..<36, id: \.self) { index in
                    let angle = Double(index) * 10
                    let isMajor = index % 9 == 0
                    let isMinor = index % 3 == 0
                    
                    if isMajor || isMinor {
                        TickMark(
                            angle: angle,
                            radius: radius * 0.55,
                            length: isMajor ? 10 : 5,
                            thickness: isMajor ? 2 : 1,
                            color: isMajor ? .primary.opacity(0.6) : .secondary.opacity(0.3)
                        )
                    }
                }
                
                // Cardinal direction labels
                ForEach(0..<4, id: \.self) { index in
                    let angle = Double(index) * 90
                    let label = cardinalDirections[index]
                    
                    DirectionLabel(
                        text: label,
                        angle: angle,
                        radius: radius * 0.78,
                        isCardinal: true,
                        isNorth: label == "N"
                    )
                }
                
                // Ordinal direction labels
                ForEach(0..<4, id: \.self) { index in
                    let angle = Double(index) * 90 + 45
                    let label = ordinalDirections[index]
                    
                    DirectionLabel(
                        text: label,
                        angle: angle,
                        radius: radius * 0.78,
                        isCardinal: false,
                        isNorth: false
                    )
                }
                
                // Wind direction needle
                WindNeedle(
                    angle: needleAnimated ? windDirection : 0,
                    radius: radius * 0.45
                )
                
                // Center dot
                Circle()
                    .fill(.primary.opacity(0.8))
                    .frame(width: 8, height: 8)
                
                // Center speed display
                VStack(spacing: 2) {
                    Text("\(Int(windSpeed))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text(windUnit)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .offset(y: 2)
            }
            .position(center)
        }
    }
}

// MARK: - Compass Subviews

struct TickMark: View {
    let angle: Double
    let radius: CGFloat
    let length: CGFloat
    let thickness: CGFloat
    let color: Color
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: thickness, height: length)
            .offset(y: -radius)
            .rotationEffect(.degrees(angle))
    }
}

struct DirectionLabel: View {
    let text: String
    let angle: Double
    let radius: CGFloat
    let isCardinal: Bool
    let isNorth: Bool
    
    var body: some View {
        Text(text)
            .font(isCardinal ? .caption.weight(.bold) : .system(size: 9, weight: .medium))
            .foregroundStyle(isNorth ? .red : (isCardinal ? .primary.opacity(0.8) : .secondary))
            .offset(y: -radius)
            .rotationEffect(.degrees(angle))
            // Counter-rotate so text stays upright
            .rotationEffect(.degrees(-angle), anchor: .center)
            .transformEffect(.identity) // Force re-render for correct positioning
            // Re-apply the position
            .position(x: 0, y: 0)
            .offset(
                x: radius * sin(angle * .pi / 180),
                y: -radius * cos(angle * .pi / 180)
            )
    }
}

struct WindNeedle: View {
    let angle: Double
    let radius: CGFloat
    
    var body: some View {
        ZStack {
            // Arrow body pointing in wind direction
            // Wind direction indicates where wind comes FROM,
            // so the arrow points in the direction wind blows TO (opposite)
            
            // Tail (points toward wind source)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.cyan.opacity(0.6), .cyan.opacity(0.2)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 4, height: radius * 0.7)
                .offset(y: radius * 0.35)
            
            // Head (points where wind blows to)
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 16, height: 20)
                .offset(y: -radius * 0.35)
            
            // Shaft
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: radius * 0.7)
                .offset(y: -radius * 0.02)
        }
        .rotationEffect(.degrees(angle))
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Wind Stat Item

struct WindStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color.gradient)
            
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.6), .cyan.opacity(0.4)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        ScrollView {
            WindCompassCard(
                current: CurrentWeather(
                    time: "2026-02-07T12:00",
                    temperature2m: 45,
                    apparentTemperature: 40,
                    weatherCode: 0,
                    windSpeed10m: 15.5,
                    windDirection10m: 225,
                    windGusts10m: 28.3,
                    relativeHumidity2m: 65,
                    dewPoint2m: 38,
                    pressure: 1013,
                    cloudCover: 20,
                    visibility: 16000,
                    uvIndex: 3.0,
                    isDay: 1,
                    precipitation: 0.0
                )
            )
            .environment(SettingsManager())
            .padding(20)
        }
    }
}
