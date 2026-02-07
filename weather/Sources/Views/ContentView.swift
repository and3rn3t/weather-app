//
//  ContentView.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import SwiftUI
import CoreLocation
import SwiftData

struct ContentView: View {
    @State private var locationManager = LocationManager()
    @State private var weatherService = WeatherService()
    @State private var showingSearch = false
    @State private var showingEffectsShowcase = false
    @State private var showingSettings = false
    @State private var showingFavorites = false
    @State private var showingComparison = false
    @State private var showingMap = false
    @State private var showingHourlyChart = false
    @State private var showingOnboarding = !OnboardingChecker.hasCompletedOnboarding
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var autoRefreshTask: Task<Void, Never>?
    
    @State private var settings = SettingsManager()
    @State private var notificationManager = NotificationManager()
    @State private var liveActivityManager = LiveActivityManager()
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @State private var favoritesManager: FavoritesManager?
    
    var body: some View {
        NavigationStack {
            Group {
                if let weatherData = weatherService.weatherData {
                    WeatherDetailView(
                        weatherData: weatherData,
                        locationName: displayLocationName,
                        onRefresh: refreshWeather,
                        onSearchTapped: { showingSearch = true },
                        airQualityData: weatherService.airQualityData,
                        settings: settings
                    )
                    .id(settings.temperatureUnit) // Force refresh when settings change
                } else if weatherService.isLoading {
                    LoadingView()
                } else if let errorMessage = weatherService.errorMessage ?? locationManager.errorMessage {
                    ErrorView(
                        message: errorMessage,
                        error: weatherService.lastError,
                        retryAction: fetchWeather
                    )
                } else {
                    WelcomeView(
                        requestLocationAction: requestLocation,
                        authorizationStatus: locationManager.authorizationStatus
                    )
                }
            }
            .task {
                await checkAndFetchWeather()
                
                // Initialize favorites manager
                if favoritesManager == nil {
                    favoritesManager = FavoritesManager(modelContext: modelContext)
                }
                
                // Restore any existing Live Activity
                if settings.liveActivitiesEnabled {
                    liveActivityManager.restoreExistingActivity()
                }
                
                // Start auto-refresh timer
                startAutoRefreshTimer()
            }
            .onChange(of: locationManager.location) { _, newLocation in
                // Only use location manager if no manual location selected
                if selectedCoordinate == nil, let location = newLocation {
                    Task {
                        await weatherService.fetchWeather(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            locationName: locationManager.locationName
                        )
                        // Start Live Activity with new weather data
                        if settings.liveActivitiesEnabled, let weatherData = weatherService.weatherData {
                            await liveActivityManager.startActivity(
                                weatherData: weatherData,
                                locationName: locationManager.locationName
                            )
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                LocationSearchView { coordinate, locationName in
                    selectedCoordinate = coordinate
                    selectedLocationName = locationName
                    Task {
                        await weatherService.fetchWeather(
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude,
                            locationName: locationName
                        )
                        // Update Live Activity with new location weather
                        if settings.liveActivitiesEnabled, let weatherData = weatherService.weatherData {
                            await liveActivityManager.startActivity(
                                weatherData: weatherData,
                                locationName: locationName
                            )
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEffectsShowcase) {
                VisualEffectsShowcase()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings, notifications: notificationManager)
            }
            .sheet(isPresented: $showingFavorites) {
                if let favManager = favoritesManager {
                    FavoritesView { location in
                        selectedCoordinate = location.coordinate
                        selectedLocationName = location.name
                        Task {
                            await weatherService.fetchWeather(
                                latitude: location.latitude,
                                longitude: location.longitude,
                                locationName: location.name
                            )
                            // Update Live Activity with favorite location weather
                            if settings.liveActivitiesEnabled, let weatherData = weatherService.weatherData {
                                await liveActivityManager.startActivity(
                                    weatherData: weatherData,
                                    locationName: location.name
                                )
                            }
                        }
                    }
                    .environment(favManager)
                }
            }
            .sheet(isPresented: $showingComparison) {
                WeatherComparisonView()
                    .environment(settings)
                    .environment(locationManager)
                    .environment(weatherService)
            }
            .sheet(isPresented: $showingMap) {
                if let weatherData = weatherService.weatherData {
                    WeatherMapView(
                        weatherData: weatherData,
                        locationName: displayLocationName ?? "Current Location",
                        latitude: currentLatitude,
                        longitude: currentLongitude
                    )
                }
            }
            .sheet(isPresented: $showingHourlyChart) {
                if let weatherData = weatherService.weatherData {
                    HourlyChartView(weatherData: weatherData)
                        .environment(settings)
                }
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView(isPresented: $showingOnboarding)
                    .environment(locationManager)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFavorites = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .symbolEffect(.pulse)
                    }
                    .buttonStyle(.glass)
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Comparison button
                    if weatherService.weatherData != nil {
                        Button {
                            showingComparison = true
                        } label: {
                            Image(systemName: "square.grid.2x2")
                        }
                        .buttonStyle(.glass)
                        .help("Compare weather across locations")
                    }
                    
                    // Map button
                    if weatherService.weatherData != nil {
                        Button {
                            showingMap = true
                        } label: {
                            Image(systemName: "map")
                        }
                        .buttonStyle(.glass)
                        
                        // Chart button
                        Button {
                            showingHourlyChart = true
                        } label: {
                            Image(systemName: "chart.xyaxis.line")
                        }
                        .buttonStyle(.glass)
                    }
                    
                    // Settings button
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .symbolEffect(.pulse)
                    }
                    .buttonStyle(.glass)
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .onChange(of: settings.liveActivitiesEnabled) { _, enabled in
                Task {
                    if enabled {
                        // Start Live Activity when enabled
                        if let weatherData = weatherService.weatherData {
                            await liveActivityManager.startActivity(
                                weatherData: weatherData,
                                locationName: displayLocationName
                            )
                        }
                    } else {
                        // End all Live Activities when disabled
                        await liveActivityManager.endAllActivities()
                    }
                }
            }
        }
    }
    
    private var displayLocationName: String? {
        selectedLocationName ?? locationManager.locationName
    }
    
    private var currentLatitude: Double {
        selectedCoordinate?.latitude ?? locationManager.location?.coordinate.latitude ?? 0
    }
    
    private var currentLongitude: Double {
        selectedCoordinate?.longitude ?? locationManager.location?.coordinate.longitude ?? 0
    }
    
    private func checkAndFetchWeather() async {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    private func requestLocation() {
        locationManager.requestLocation()
    }
    
    private func fetchWeather() {
        if let coordinate = selectedCoordinate {
            // Fetch for manually selected location
            Task {
                await weatherService.fetchWeather(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    locationName: selectedLocationName
                )
            }
        } else if let location = locationManager.location {
            // Fetch for current location
            Task {
                await weatherService.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    locationName: locationManager.locationName
                )
            }
        } else {
            locationManager.requestLocation()
        }
    }
    
    private func refreshWeather() async {
        if let coordinate = selectedCoordinate {
            await weatherService.fetchWeather(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                locationName: selectedLocationName
            )
        } else if let location = locationManager.location {
            await weatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: locationManager.locationName
            )
        }
        
        // Update Live Activity with new weather data
        if settings.liveActivitiesEnabled, let weatherData = weatherService.weatherData {
            await liveActivityManager.updateActivity(weatherData: weatherData)
        }
    }
    
    private func startAutoRefreshTimer() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task {
            while !Task.isCancelled {
                let interval = TimeInterval(settings.autoRefreshInterval * 60)
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await refreshWeather()
            }
        }
    }
}

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [.blue.opacity(0.2), .cyan.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 32) {
                ZStack {
                    // Single pulsing circle
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.3 : 0.9)
                        .opacity(isAnimating ? 0 : 0.8)
                        .animation(
                            .easeOut(duration: 1.2)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 50))
                        .symbolRenderingMode(.multicolor)
                        .symbolEffect(.pulse.byLayer)
                }
                
                VStack(spacing: 6) {
                    Text("Loading weather...")
                        .font(.headline)
                    
                    ProgressView()
                        .tint(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

// Simple sparkle effect for loading view
struct FloatingSparkles: View {
    let count: Int
    @State private var particles: [(id: UUID, x: CGFloat, y: CGFloat, delay: Double)] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow.opacity(0.6))
                        .font(.system(size: CGFloat.random(in: 12...20)))
                        .position(x: particle.x, y: particle.y)
                        .opacity(0.8)
                }
            }
            .onAppear {
                particles = (0..<count).map { _ in
                    (
                        id: UUID(),
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height),
                        delay: Double.random(in: 0...2)
                    )
                }
                animateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func animateParticles(in size: CGSize) {
        for index in particles.indices {
            withAnimation(
                .easeInOut(duration: 3)
                .delay(particles[index].delay)
                .repeatForever(autoreverses: true)
            ) {
                particles[index].y += CGFloat.random(in: -50...50)
                particles[index].x += CGFloat.random(in: -30...30)
            }
        }
    }
}

struct ErrorView: View {
    let message: String
    var error: WeatherError?
    let retryAction: () -> Void
    
    init(message: String, error: WeatherError? = nil, retryAction: @escaping () -> Void) {
        self.message = message
        self.error = error
        self.retryAction = retryAction
    }
    
    private var displayIcon: String {
        error?.systemImage ?? "exclamationmark.triangle.fill"
    }
    
    private var displayTitle: String {
        error?.errorDescription ?? "Oops!"
    }
    
    private var displayMessage: String {
        error?.recoverySuggestion ?? message
    }
    
    private var showRetry: Bool {
        error?.isRetryable ?? true
    }
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            Image(systemName: displayIcon)
                .font(.system(size: 72))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.orange.gradient)
                .accessibilityLabel("Error icon")
            
            VStack(spacing: 12) {
                Text(displayTitle)
                    .font(.title.bold())
                
                Text(displayMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .accessibilityElement(children: .combine)
            
            Spacer()
            
            if showRetry {
                Button(action: retryAction) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.bottom, 40)
                .accessibilityHint("Double tap to retry loading weather data")
            } else if error == .locationAccessDenied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .font(.headline)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.bottom, 40)
                .accessibilityHint("Double tap to open Settings and enable location access")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

struct WelcomeView: View {
    let requestLocationAction: () -> Void
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var needsLocationPermission: Bool {
        authorizationStatus == .notDetermined || 
        authorizationStatus == .denied || 
        authorizationStatus == .restricted
    }
    
    var body: some View {
        ZStack {
            // Animated mesh gradient background
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [isAnimating ? 0.8 : 0.2, isAnimating ? 0.2 : 0.8], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .blue, .cyan, .purple,
                    .indigo, .pink, .orange,
                    .purple, .blue, .cyan
                ]
            )
            .ignoresSafeArea()
            .opacity(0.5)
            
            // Floating weather particles
            FloatingSparkles(count: 20)
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 24) {
                    Image(systemName: "cloud.sun.rain.fill")
                        .font(.system(size: 120))
                        .symbolRenderingMode(.multicolor)
                        .symbolEffect(.pulse)
                        .symbolEffect(.variableColor.iterative)
                    
                    VStack(spacing: 12) {
                        Text("Welcome to Weather")
                            .font(.largeTitle.bold())
                        
                        Text("Get accurate weather forecasts\nfor your location")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .glassEffect(Glass.regular, in: .rect(cornerRadius: 16))
                }
                
                Spacer()
                
                // Only show location button if permission is needed
                if needsLocationPermission {
                    VStack(spacing: 16) {
                        Button(action: requestLocationAction) {
                            Label(
                                authorizationStatus == .denied ? "Open Settings" : "Enable Location",
                                systemImage: authorizationStatus == .denied ? "gearshape" : "location.fill"
                            )
                            .font(.headline)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        
                        Text(authorizationStatus == .denied 
                             ? "Location access was denied.\nEnable in Settings to continue."
                             : "Location access is required to show\nweather for your area")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 50)
                } else {
                    // Permission granted but still loading - show progress
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Getting your location...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 50)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Visual Effects Showcase

struct VisualEffectsShowcase: View {
    @State private var isAnimating = false
    @State private var showExtraGlass = false
    @Namespace private var glassNamespace
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 8) {
                    Text("Visual Effects")
                        .font(.largeTitle.bold())
                    
                    Text("Explore the latest iOS design effects")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Liquid Glass Section
                liquidGlassSection
                
                // Interactive Glass Buttons
                glassButtonsSection
                
                // Morphing Glass Animation
                morphingGlassSection
                
                // Material Effects
                materialEffectsSection
                
                // Symbol Effects
                symbolEffectsSection
                
                // Mesh Gradients
                meshGradientSection
            }
            .padding()
        }
        .background(
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [isAnimating ? 0.8 : 0.2, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .blue, .cyan, .purple,
                    .indigo, .pink, .orange,
                    .purple, .blue, .cyan
                ]
            )
            .ignoresSafeArea()
            .opacity(0.4)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var liquidGlassSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Liquid Glass", icon: "drop.fill")
            
            GlassEffectContainer(spacing: 30) {
                HStack(spacing: 30) {
                    glassCard(icon: "sun.max.fill", title: "Sunny", color: .orange)
                    glassCard(icon: "cloud.rain.fill", title: "Rainy", color: .blue)
                }
            }
        }
    }
    
    private func glassCard(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .symbolRenderingMode(.multicolor)
            Text(title)
                .font(.headline)
        }
        .frame(width: 140, height: 140)
        .background(color.opacity(0.2))
        .glassEffect(Glass.regular, in: .rect(cornerRadius: 20))
    }
    
    private var glassButtonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Interactive Glass Buttons", icon: "hand.tap.fill")
            
            VStack(spacing: 16) {
                Button("Standard Glass") {
                    withAnimation(.spring(response: 0.3)) {
                        showExtraGlass.toggle()
                    }
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                
                Button("Prominent Glass") {
                    withAnimation(.spring(response: 0.3)) {
                        showExtraGlass.toggle()
                    }
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            }
        }
    }
    
    private var morphingGlassSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Morphing Transitions", icon: "wand.and.stars")
            
            GlassEffectContainer(spacing: 40) {
                HStack(spacing: 40) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 36))
                        .frame(width: 80, height: 80)
                        .background(Color.yellow.opacity(0.2))
                        .glassEffect(Glass.regular, in: .rect(cornerRadius: 16))
                        .glassEffectID("star", in: glassNamespace)
                    
                    if showExtraGlass {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 36))
                            .frame(width: 80, height: 80)
                            .background(Color.indigo.opacity(0.2))
                            .glassEffect(Glass.regular, in: .rect(cornerRadius: 16))
                            .glassEffectID("moon", in: glassNamespace)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            
            Text("Tap the buttons above to morph")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }
    
    private var materialEffectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Material Effects", icon: "circle.hexagongrid.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    materialCard("Ultra Thin", material: .ultraThinMaterial)
                    materialCard("Thin", material: .thinMaterial)
                    materialCard("Regular", material: .regularMaterial)
                    materialCard("Thick", material: .thickMaterial)
                    materialCard("Ultra Thick", material: .ultraThickMaterial)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func materialCard(_ title: String, material: Material) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.gradient)
                .frame(width: 100, height: 60)
                .overlay {
                    Text("BG")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(material, in: Capsule())
        }
    }
    
    private var symbolEffectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("SF Symbol Effects", icon: "rays")
            
            GlassEffectContainer(spacing: 20) {
                HStack(spacing: 20) {
                    symbolWithEffect("cloud.bolt.fill", effect: .variableColor.iterative, color: .yellow)
                    symbolWithEffect("heart.fill", effect: .pulse, color: .red)
                    symbolWithEffect("star.fill", effect: .breathe, color: .pink)
                    symbolWithEffect("waveform", effect: .variableColor.iterative.reversing, color: .green)
                }
            }
        }
    }
    
    private func symbolWithEffect(_ name: String, effect: some SymbolEffect & IndefiniteSymbolEffect, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 44))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color.gradient)
            .symbolEffect(effect)
            .frame(width: 70, height: 70)
            .background(color.opacity(0.15))
            .glassEffect(Glass.regular, in: .rect(cornerRadius: 14))
    }
    
    private var meshGradientSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Mesh Gradients", icon: "grid")
            
            ZStack {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        .purple, .blue, .cyan,
                        .pink, .white, .orange,
                        .red, .yellow, .green
                    ]
                )
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                VStack {
                    Text("Smooth Color Transitions")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    
                    Text("Mesh gradients create fluid color flows")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding()
                .glassEffect(Glass.regular, in: .rect(cornerRadius: 12))
            }
        }
        .padding(.bottom, 40)
    }
    
    private func sectionTitle(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.title2.bold())
            .foregroundStyle(.primary)
    }
}

#Preview {
    ContentView()
}


