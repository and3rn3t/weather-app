//
//  WeatherParticleEffects.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI

// MARK: - Rain Effect

struct RainEffect: View {
    let intensity: Double // 0.0 to 1.0
    
    @State private var drops: [RainDrop] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(drops) { drop in
                    RainDropView(drop: drop)
                }
            }
            .onAppear {
                let dropCount = Int(intensity * 50) + 10
                drops = (0..<dropCount).map { _ in
                    RainDrop(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: -geometry.size.height...0),
                        speed: CGFloat.random(in: 300...500),
                        length: CGFloat.random(in: 15...30),
                        opacity: Double.random(in: 0.3...0.7)
                    )
                }
                animateRain(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func animateRain(in size: CGSize) {
        for index in drops.indices {
            withAnimation(
                .linear(duration: Double(size.height / drops[index].speed))
                .repeatForever(autoreverses: false)
            ) {
                drops[index].y = size.height + 50
            }
        }
    }
}

struct RainDrop: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let speed: CGFloat
    let length: CGFloat
    let opacity: Double
}

struct RainDropView: View {
    let drop: RainDrop
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .blue.opacity(drop.opacity),
                        .blue.opacity(drop.opacity * 0.5),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1.5, height: drop.length)
            .position(x: drop.x, y: drop.y)
    }
}

// MARK: - Snow Effect

struct SnowEffect: View {
    let intensity: Double // 0.0 to 1.0
    
    @State private var flakes: [Snowflake] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(flakes) { flake in
                    SnowflakeView(flake: flake)
                }
            }
            .onAppear {
                let flakeCount = Int(intensity * 40) + 10
                flakes = (0..<flakeCount).map { _ in
                    Snowflake(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: -geometry.size.height...0),
                        speed: CGFloat.random(in: 100...200),
                        size: CGFloat.random(in: 2...6),
                        opacity: Double.random(in: 0.5...1.0),
                        wobble: CGFloat.random(in: -20...20)
                    )
                }
                animateSnow(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func animateSnow(in size: CGSize) {
        for index in flakes.indices {
            // Falling animation
            withAnimation(
                .linear(duration: Double(size.height / flakes[index].speed))
                .repeatForever(autoreverses: false)
            ) {
                flakes[index].y = size.height + 20
            }
            
            // Wobble animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...1))
            ) {
                flakes[index].x += flakes[index].wobble
            }
        }
    }
}

struct Snowflake: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let speed: CGFloat
    let size: CGFloat
    let opacity: Double
    let wobble: CGFloat
}

struct SnowflakeView: View {
    let flake: Snowflake
    
    var body: some View {
        Circle()
            .fill(.white.opacity(flake.opacity))
            .frame(width: flake.size, height: flake.size)
            .blur(radius: flake.size / 4)
            .position(x: flake.x, y: flake.y)
    }
}

// MARK: - Cloud Movement Effect

struct CloudsEffect: View {
    let speed: Double // 0.0 to 1.0
    
    @State private var clouds: [Cloud] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(clouds) { cloud in
                    CloudView(cloud: cloud)
                }
            }
            .onAppear {
                let cloudCount = Int(speed * 5) + 3
                clouds = (0..<cloudCount).map { index in
                    Cloud(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height * 0.4),
                        width: CGFloat.random(in: 80...150),
                        height: CGFloat.random(in: 40...70),
                        opacity: Double.random(in: 0.1...0.3),
                        speed: CGFloat.random(in: 30...60)
                    )
                }
                animateClouds(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func animateClouds(in size: CGSize) {
        for index in clouds.indices {
            withAnimation(
                .linear(duration: Double(size.width / clouds[index].speed))
                .repeatForever(autoreverses: false)
            ) {
                clouds[index].x = size.width + clouds[index].width
            }
        }
    }
}

struct Cloud: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let opacity: Double
    let speed: CGFloat
}

struct CloudView: View {
    let cloud: Cloud
    
    var body: some View {
        ZStack {
            // Simple cloud shape made of circles
            Circle()
                .fill(.white.opacity(cloud.opacity))
                .frame(width: cloud.width * 0.6, height: cloud.height * 0.8)
                .offset(x: -cloud.width * 0.2)
            
            Circle()
                .fill(.white.opacity(cloud.opacity))
                .frame(width: cloud.width * 0.5, height: cloud.height * 0.7)
                .offset(x: cloud.width * 0.1)
            
            Circle()
                .fill(.white.opacity(cloud.opacity))
                .frame(width: cloud.width * 0.4, height: cloud.height * 0.6)
                .offset(x: cloud.width * 0.3)
        }
        .position(x: cloud.x, y: cloud.y)
        .blur(radius: 10)
    }
}

// MARK: - Lightning Effect

struct LightningEffect: View {
    @State private var showLightning = false
    @State private var flashCount = 0
    
    var body: some View {
        Rectangle()
            .fill(.white)
            .opacity(showLightning ? 0.6 : 0)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                scheduleLightning()
            }
    }
    
    private func scheduleLightning() {
        // Random interval between 3-10 seconds
        let delay = Double.random(in: 3...10)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            flash()
        }
    }
    
    private func flash() {
        // Quick flash
        withAnimation(.linear(duration: 0.1)) {
            showLightning = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.1)) {
                showLightning = false
            }
            
            // Random chance for double flash
            if Bool.random() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.linear(duration: 0.05)) {
                        showLightning = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.linear(duration: 0.05)) {
                            showLightning = false
                        }
                        scheduleLightning()
                    }
                }
            } else {
                scheduleLightning()
            }
        }
    }
}

// MARK: - Fog Effect

struct FogEffect: View {
    let intensity: Double // 0.0 to 1.0
    
    @State private var layers: [FogLayer] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(layers) { layer in
                    FogLayerView(layer: layer, size: geometry.size)
                }
            }
            .onAppear {
                layers = (0..<3).map { index in
                    FogLayer(
                        offset: CGFloat(index) * geometry.size.width / 3,
                        speed: CGFloat.random(in: 20...40),
                        opacity: intensity * Double.random(in: 0.2...0.4)
                    )
                }
                animateFog(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func animateFog(in size: CGSize) {
        for index in layers.indices {
            withAnimation(
                .linear(duration: Double(size.width / layers[index].speed))
                .repeatForever(autoreverses: false)
            ) {
                layers[index].offset = size.width
            }
        }
    }
}

struct FogLayer: Identifiable {
    let id = UUID()
    var offset: CGFloat
    let speed: CGFloat
    let opacity: Double
}

struct FogLayerView: View {
    let layer: FogLayer
    let size: CGSize
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .gray.opacity(layer.opacity),
                        .gray.opacity(layer.opacity * 0.5),
                        .clear,
                        .gray.opacity(layer.opacity * 0.5),
                        .gray.opacity(layer.opacity)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size.width * 2, height: size.height)
            .offset(x: layer.offset - size.width)
            .blur(radius: 30)
    }
}

// MARK: - Weather Particle Container

struct WeatherParticleContainer: View {
    let weatherCode: Int
    let isDay: Bool
    
    var body: some View {
        ZStack {
            switch WeatherCondition(code: weatherCode) {
            case .rain:
                RainEffect(intensity: 0.8)
            case .drizzle:
                RainEffect(intensity: 0.4)
            case .snow:
                SnowEffect(intensity: 0.7)
            case .thunderstorm:
                RainEffect(intensity: 1.0)
                LightningEffect()
            case .foggy:
                FogEffect(intensity: 0.7)
            case .cloudy, .partlyCloudy:
                CloudsEffect(speed: 0.5)
            default:
                EmptyView()
            }
        }
        .ignoresSafeArea()
    }
}
