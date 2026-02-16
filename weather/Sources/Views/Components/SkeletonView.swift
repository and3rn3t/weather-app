//
//  SkeletonView.swift
//  weather
//
//  Skeleton loading states for progressive weather data loading
//

import SwiftUI
import CoreLocation

// MARK: - Skeleton Loading Views

struct ShimmerSkeletonView: View {
    @State private var isAnimating = false
    
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        .secondary.opacity(0.3),
                        .secondary.opacity(0.15),
                        .secondary.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .offset(x: isAnimating ? 200 : -200)
                        .animation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                )
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Weather-Specific Skeleton Views

struct CurrentWeatherSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    ShimmerSkeletonView(width: 120, height: 24) // Location name
                    ShimmerSkeletonView(width: 200, height: 16) // Weather description
                }
                
                Spacer()
                
                ShimmerSkeletonView(width: 60, height: 60, cornerRadius: 30) // Weather icon
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ShimmerSkeletonView(width: 150, height: 48) // Temperature
                HStack(spacing: 20) {
                    ShimmerSkeletonView(width: 80, height: 16) // High
                    ShimmerSkeletonView(width: 80, height: 16) // Low
                }
            }
            
            // Additional weather info
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: 4) {
                        ShimmerSkeletonView(width: 40, height: 16) // Label
                        ShimmerSkeletonView(width: 60, height: 20) // Value
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct HourlyForecastSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ShimmerSkeletonView(width: 120, height: 20) // "Hourly Forecast"
                Spacer()
                ShimmerSkeletonView(width: 60, height: 24, cornerRadius: 12) // Toggle button
            }
            .padding(.horizontal, 20)
            
            // Chart area
            ShimmerSkeletonView(width: nil, height: 200, cornerRadius: 12)
                .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Hourly items
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(0..<8, id: \.self) { _ in
                        VStack(spacing: 8) {
                            ShimmerSkeletonView(width: 35, height: 12) // Time
                            ShimmerSkeletonView(width: 30, height: 30, cornerRadius: 15) // Icon
                            ShimmerSkeletonView(width: 40, height: 16) // Temperature
                        }
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 16)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct DailyForecastSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ShimmerSkeletonView(width: 140, height: 20) // "14-Day Forecast"
                Spacer()
                ShimmerSkeletonView(width: 80, height: 16) // "Show All" button
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    HStack(alignment: .center, spacing: 12) {
                        ShimmerSkeletonView(width: 80, height: 16) // Day name
                        ShimmerSkeletonView(width: 36, height: 24, cornerRadius: 12) // Weather icon
                        ShimmerSkeletonView(width: 55, height: 14) // Precipitation
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            ShimmerSkeletonView(width: 48, height: 16) // Low temp
                            ShimmerSkeletonView(width: 48, height: 16) // High temp
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if index < 4 {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 16)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct WeatherDetailSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Location header skeleton
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerSkeletonView(width: 150, height: 24) // Location name
                        ShimmerSkeletonView(width: 100, height: 14) // Last update
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        ShimmerSkeletonView(width: 40, height: 40, cornerRadius: 20) // Search button
                        ShimmerSkeletonView(width: 40, height: 40, cornerRadius: 20) // Share button
                    }
                }
                .padding(.horizontal, 20)
                
                // Current weather skeleton
                CurrentWeatherSkeletonView()
                
                // Weather recommendations skeleton
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ShimmerSkeletonView(width: 140, height: 20) // "Recommendations"
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                VStack(alignment: .leading, spacing: 8) {
                                    ShimmerSkeletonView(width: 30, height: 30, cornerRadius: 15) // Icon
                                    ShimmerSkeletonView(width: 100, height: 16) // Title
                                    ShimmerSkeletonView(width: 120, height: 12) // Description
                                }
                                .padding(16)
                                .frame(width: 140)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
                
                // Sun & Moon skeleton
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        ShimmerSkeletonView(width: 100, height: 20) // "Sun & Moon"
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    HStack(spacing: 20) {
                        VStack(spacing: 8) {
                            ShimmerSkeletonView(width: 30, height: 30, cornerRadius: 15) // Sun icon
                            ShimmerSkeletonView(width: 60, height: 14) // Sunrise time
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            ShimmerSkeletonView(width: 30, height: 30, cornerRadius: 15) // Moon icon
                            ShimmerSkeletonView(width: 60, height: 14) // Sunset time
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
                
                // Section label skeleton
                HStack {
                    ShimmerSkeletonView(width: 80, height: 20) // "Forecast"
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // Hourly forecast skeleton
                HourlyForecastSkeletonView()
                
                // Daily forecast skeleton
                DailyForecastSkeletonView()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Progressive Loading Container

struct ProgressiveWeatherView: View {
    let weatherService: WeatherService
    @Environment(SettingsManager.self) private var settings
    @State private var showingAllDetails = false
    
    var body: some View {
        ZStack {
            if let weatherData = weatherService.weatherData {
                // Real weather view with progressive disclosure
                WeatherDetailView(
                    weatherData: weatherData,
                    locationName: weatherService.currentLocationName,
                    onRefresh: { await weatherService.retry() },
                    onSearchTapped: { /* Handle search */ },
                    onShareCardTapped: { /* Handle share */ },
                    airQualityData: weatherService.airQualityData,
                    weatherAlerts: weatherService.weatherAlerts,
                    settings: settings
                )
                .opacity(showingAllDetails ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: showingAllDetails)
                .onAppear {
                    // Progressive disclosure: show all details after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingAllDetails = true
                    }
                }
            } else if weatherService.isLoading {
                // Skeleton loading state
                WeatherDetailSkeleton()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Error or empty state
                if let errorMessage = weatherService.errorMessage {
                    ErrorView(
                        message: errorMessage,
                        error: weatherService.lastError,
                        retryAction: { Task { await weatherService.retry() } }
                    )
                } else {
                    WelcomeView(
                        requestLocationAction: { /* Handle location request */ },
                        authorizationStatus: .notDetermined
                    )
                }
            }
        }
    }
}

// MARK: - Animated Loading States

struct PulsingDot: View {
    @State private var isPulsing = false
    let delay: Double
    
    init(delay: Double = 0) {
        self.delay = delay
    }
    
    var body: some View {
        Circle()
            .fill(.secondary)
            .frame(width: 8, height: 8)
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: isPulsing
            )
            .onAppear {
                isPulsing.toggle()
            }
    }
}

struct AnimatedLoadingIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            PulsingDot(delay: 0.0)
            PulsingDot(delay: 0.2)
            PulsingDot(delay: 0.4)
        }
    }
}

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            AnimatedLoadingIndicator()
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CurrentWeatherSkeletonView()
        HourlyForecastSkeletonView()
    }
    .padding()
}