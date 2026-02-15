//
//  SkeletonLoader.swift
//  weather
//
//  Progressive loading states with animated skeleton placeholders
//

import SwiftUI

// MARK: - Skeleton Loading Views

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.3),
                                .black,
                                .black.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(x: isAnimating ? 3 : -3, y: 1, anchor: .leading)
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating.toggle()
                }
            }
    }
}

// MARK: - Weather Specific Skeleton Cards

struct CurrentWeatherSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // Location header skeleton
            VStack(spacing: 8) {
                SkeletonView()
                    .frame(height: 24)
                    .frame(maxWidth: 200)
                    .clipShape(Capsule())
                
                SkeletonView()
                    .frame(height: 16)
                    .frame(maxWidth: 120)
                    .clipShape(Capsule())
            }
            
            // Temperature skeleton
            VStack(spacing: 12) {
                SkeletonView()
                    .frame(width: 120, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                HStack(spacing: 8) {
                    SkeletonView()
                        .frame(width: 80, height: 20)
                        .clipShape(Capsule())
                    
                    SkeletonView()
                        .frame(width: 60, height: 20)
                        .clipShape(Capsule())
                }
            }
            
            // Weather details grid skeleton
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonView()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        
                        SkeletonView()
                            .frame(height: 16)
                            .frame(maxWidth: 80)
                            .clipShape(Capsule())
                        
                        SkeletonView()
                            .frame(height: 12)
                            .frame(maxWidth: 60)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct HourlyForecastSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header skeleton
            HStack {
                SkeletonView()
                    .frame(width: 140, height: 20)
                    .clipShape(Capsule())
                
                Spacer()
                
                SkeletonView()
                    .frame(width: 60, height: 32)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            
            // Chart skeleton
            VStack(spacing: 8) {
                // Chart area
                SkeletonView()
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Chart labels
                HStack {
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonView()
                            .frame(width: 30, height: 12)
                            .clipShape(Capsule())
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Hourly items skeleton
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(0..<12, id: \.self) { _ in
                        VStack(spacing: 8) {
                            SkeletonView()
                                .frame(width: 40, height: 12)
                                .clipShape(Capsule())
                            
                            SkeletonView()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                            
                            SkeletonView()
                                .frame(width: 44, height: 16)
                                .clipShape(Capsule())
                        }
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct DailyForecastSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header skeleton
            HStack {
                SkeletonView()
                    .frame(width: 120, height: 20)
                    .clipShape(Capsule())
                
                Spacer()
                
                SkeletonView()
                    .frame(width: 80, height: 20)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            
            // Daily rows skeleton
            LazyVStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    HStack(spacing: 12) {
                        // Day name
                        SkeletonView()
                            .frame(width: 80, height: 16)
                            .clipShape(Capsule())
                        
                        // Weather icon
                        SkeletonView()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        
                        // Precipitation
                        SkeletonView()
                            .frame(width: 40, height: 12)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        // Temperatures
                        HStack(spacing: 12) {
                            SkeletonView()
                                .frame(width: 40, height: 16)
                                .clipShape(Capsule())
                            
                            SkeletonView()
                                .frame(width: 40, height: 16)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    
                    if index < 6 {
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

struct WeatherRecommendationsSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                SkeletonView()
                    .frame(width: 140, height: 20)
                    .clipShape(Capsule())
                
                Spacer()
                
                SkeletonView()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 20)
            
            // Recommendations
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        SkeletonView()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonView()
                                .frame(height: 16)
                                .frame(maxWidth: 200)
                                .clipShape(Capsule())
                            
                            SkeletonView()
                                .frame(height: 12)
                                .frame(maxWidth: 160)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.vertical, 16)
        .glassEffect(GlassStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Loading State View

struct WeatherLoadingView: View {
    @State private var currentStep = 0
    private let loadingSteps = [
        "Getting location...",
        "Fetching weather data...",
        "Processing forecast...",
        "Almost ready..."
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Loading status with animated text
                VStack(spacing: 8) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text(loadingSteps[currentStep])
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // Progress bar
                    ProgressView(value: Double(currentStep + 1), total: Double(loadingSteps.count))
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 16)
                
                // Skeleton cards
                CurrentWeatherSkeleton()
                
                WeatherRecommendationsSkeleton()
                
                // Section separator
                HStack {
                    SkeletonView()
                        .frame(width: 100, height: 20)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                HourlyForecastSkeleton()
                
                DailyForecastSkeleton()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SkeletonView()
                    .frame(width: 120, height: 20)
                    .clipShape(Capsule())
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                SkeletonView()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            }
        }
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = (currentStep + 1) % loadingSteps.count
            }
            
            // Stop after a reasonable time to avoid infinite loading
            if currentStep == 0 {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Progressive Loading Coordinator

@MainActor
class ProgressiveLoadingCoordinator: ObservableObject {
    @Published var loadingState: LoadingState = .initial
    @Published var dataAvailable: [DataType] = []
    
    enum LoadingState {
        case initial
        case loadingLocation
        case loadingWeather
        case loadingDetails
        case complete
        case failed(Error)
    }
    
    enum DataType {
        case current, hourly, daily, airQuality, alerts, recommendations
    }
    
    func updateLoadingState(_ state: LoadingState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            loadingState = state
        }
    }
    
    func markDataAvailable(_ type: DataType) {
        withAnimation(.easeInOut(duration: 0.3)) {
            dataAvailable.append(type)
        }
    }
    
    func isDataAvailable(_ type: DataType) -> Bool {
        dataAvailable.contains(type)
    }
    
    var shouldShowSkeleton: Bool {
        switch loadingState {
        case .initial, .loadingLocation, .loadingWeather:
            return true
        case .loadingDetails, .complete, .failed:
            return false
        }
    }
}