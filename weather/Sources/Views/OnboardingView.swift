//
//  OnboardingView.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI
import CoreLocation

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(LocationManager.self) private var locationManager
    @Binding var isPresented: Bool
    
    @State private var currentPage = 0
    @State private var isRequestingLocation = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sun.max.fill",
            iconColor: .orange,
            title: "Welcome to Weather",
            subtitle: "Your personal weather companion",
            description: "Get accurate forecasts, beautiful visualizations, and smart weather insights right at your fingertips."
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .blue,
            title: "Detailed Forecasts",
            subtitle: "Plan ahead with confidence",
            description: "View hourly and daily forecasts with interactive charts for temperature, precipitation, wind, and humidity."
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            iconColor: .purple,
            title: "Stay Informed",
            subtitle: "Never be caught off guard",
            description: "Live Activities on your Lock Screen, Siri Shortcuts, and widgets keep you updated without opening the app."
        ),
        OnboardingPage(
            icon: "location.fill",
            iconColor: .green,
            title: "Enable Location",
            subtitle: "For local weather updates",
            description: "Allow location access to get weather for your current location. You can also search for any city worldwide."
        )
    ]
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .padding()
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(
                            page: page,
                            isLocationPage: index == pages.count - 1,
                            isRequestingLocation: $isRequestingLocation,
                            onRequestLocation: requestLocation,
                            onComplete: completeOnboarding
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicators and navigation
                VStack(spacing: 24) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                                .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Navigation button
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage += 1
                            }
                        } label: {
                            HStack {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func requestLocation() {
        isRequestingLocation = true
        locationManager.requestLocation()
        
        // Wait a moment for the permission dialog, then complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isRequestingLocation = false
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.spring(response: 0.5)) {
            isPresented = false
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLocationPage: Bool
    @Binding var isRequestingLocation: Bool
    let onRequestLocation: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.2))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(page.iconColor.opacity(0.3))
                    .frame(width: 110, height: 110)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(page.iconColor)
                    .symbolEffect(.pulse.byLayer)
            }
            
            // Text content
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // Location page specific buttons
            if isLocationPage {
                VStack(spacing: 16) {
                    // Enable location button
                    Button {
                        onRequestLocation()
                    } label: {
                        HStack {
                            if isRequestingLocation {
                                ProgressView()
                                    .tint(.blue)
                            } else {
                                Image(systemName: "location.fill")
                                Text("Enable Location")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isRequestingLocation)
                    
                    // Skip button
                    Button {
                        onComplete()
                    } label: {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            
            Spacer()
        }
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.5),
                Color(red: 0.3, green: 0.2, blue: 0.6),
                Color(red: 0.2, green: 0.1, blue: 0.4)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
        .overlay {
            // Floating particles effect (reduced count for startup performance)
            GeometryReader { geometry in
                ForEach(0..<8, id: \.self) { index in
                    FloatingParticle(index: index, bounds: geometry.size)
                }
            }
        }
    }
}

// MARK: - Floating Particle

struct FloatingParticle: View {
    let index: Int
    let bounds: CGSize
    
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Circle()
            .fill(.white.opacity(opacity))
            .frame(width: CGFloat.random(in: 2...6))
            .position(position)
            .onAppear {
                position = CGPoint(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: CGFloat.random(in: 0...bounds.height)
                )
                
                animateParticle()
            }
    }
    
    private func animateParticle() {
        let duration = Double.random(in: 8...15)
        
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            position = CGPoint(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height)
            )
            opacity = Double.random(in: 0.1...0.5)
        }
    }
}

// MARK: - Onboarding Checker

struct OnboardingChecker {
    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    static func reset() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environment(LocationManager())
}
