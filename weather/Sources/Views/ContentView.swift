//
//  ContentView.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import SwiftUI
import CoreLocation
import SwiftData
import OSLog
import os.signpost

struct ContentView: View {
    /// Passed in from App so we never block the main thread on SQLite init.
    /// Nil until the background container setup completes (~100-500ms in).
    @Binding var modelContainer: ModelContainer?

    @Environment(LocationManager.self) private var locationManager
    @Environment(WeatherService.self) private var weatherService
    @State private var showingSearch = false
    @State private var showingEffectsShowcase = false
    @State private var showingSettings = false
    @State private var showingFavorites = false
    @State private var showingComparison = false
    @State private var showingMap = false
    @State private var showingHourlyChart = false
    @State private var showingShareCard = false
    @State private var showingOnboarding = !OnboardingChecker.hasCompletedOnboarding
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var autoRefreshTask: Task<Void, Never>?
    @State private var lastLocationFetchTime: Date?

    @Environment(SettingsManager.self) private var settings
    @State private var notificationManager: NotificationManager?
    @State private var liveActivityManager: LiveActivityManager?
    @State private var hasLoggedFirstData = false
    @Environment(ThemeManager.self) private var themeManager
    @State private var favoritesManager: FavoritesManager?

    init(modelContainer: Binding<ModelContainer?>) {
        self._modelContainer = modelContainer
        startupLog("ContentView.init")
    }

    var body: some View {
        NavigationStack {
            let _ = startupLog("ContentView.body")
            Group {
                if let weatherData = weatherService.weatherData {
                    WeatherDetailView(
                        weatherData: weatherData,
                        locationName: displayLocationName,
                        onRefresh: refreshWeather,
                        onSearchTapped: { showingSearch = true },
                        onShareCardTapped: { showingShareCard = true },
                        airQualityData: weatherService.airQualityData,
                        settings: settings
                    )
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
                // MARK: - Background Refresh
                // WeatherService.init() already loaded cache and kicked off a
                // background refresh with last-known coords. This task only
                // needs to request a fresh GPS fix (which fires .onChange when
                // ready, triggering a location-accurate fetch).

                os_signpost(.begin, log: StartupSignpost.log, name: "ContentView.task1")
                let taskStart = CFAbsoluteTimeGetCurrent()

                // Request fresh GPS location (will update via .onChange when ready).
                // App.init already called requestLocation() if authorized, but
                // calling again is a no-op — CLLocationManager deduplicates.
                os_signpost(.begin, log: StartupSignpost.log, name: "GPSRequest")
                checkAndFetchWeather()

                let task1Ms = (CFAbsoluteTimeGetCurrent() - taskStart) * 1_000
                os_signpost(.end, log: StartupSignpost.log, name: "ContentView.task1")
                startupLog("ContentView.task1 synchronous: \(String(format: "%.0f", task1Ms))ms")
            }
            .task {
                // Priority 2: Deferred non-critical setup after weather is visible
                os_signpost(.begin, log: StartupSignpost.log, name: "ContentView.deferredSetup")
                try? await Task.sleep(for: .milliseconds(300))

                // Initialize ModelContainer off the critical path if not yet ready
                if modelContainer == nil {
                    modelContainer = await Task.detached(priority: .utility) {
                        try? ModelContainer(for: SavedLocation.self)
                    }.value
                }

                // Initialize favorites manager (SwiftData fetch)
                if favoritesManager == nil, let container = modelContainer {
                    let t = CFAbsoluteTimeGetCurrent()
                    favoritesManager = FavoritesManager(modelContext: container.mainContext)
                    startupLog("FavoritesManager.init: \(String(format: "%.0f", (CFAbsoluteTimeGetCurrent() - t) * 1_000))ms")
                }

                // Restore any existing Live Activity (only if enabled)
                if settings.liveActivitiesEnabled {
                    let lam = ensureLiveActivityManager()
                    lam.restoreExistingActivity()
                }

                // Start auto-refresh timer
                startAutoRefreshTimer()
                os_signpost(.end, log: StartupSignpost.log, name: "ContentView.deferredSetup")
            }
            .onChange(of: weatherService.weatherData != nil) { _, hasData in
                guard hasData, !hasLoggedFirstData else { return }
                hasLoggedFirstData = true
                let totalMs = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
                os_signpost(.event, log: StartupSignpost.log, name: "FirstDataVisible")
                startupLog("⛅ STARTUP COMPLETE — First weather data visible: \(String(format: "%.0f", totalMs))ms since process start")
            }
            .onChange(of: locationManager.location) { _, newLocation in
                // GPS fix received — end the signpost started in task1
                os_signpost(.end, log: StartupSignpost.log, name: "GPSRequest")
                let gpsMs = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
                startupLog("GPS fix received — \(String(format: "%.0f", gpsMs))ms since process start")

                // Debounce: CLLocationManager often fires multiple fixes in quick
                // succession. Only act on one every 5 seconds to avoid redundant
                // network fetches racing each other.
                let now = Date()
                if let last = lastLocationFetchTime, now.timeIntervalSince(last) < 5 { return }
                lastLocationFetchTime = now

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
                            await ensureLiveActivityManager().startActivity(
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
                            await ensureLiveActivityManager().startActivity(
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
                SettingsView(settings: settings, notifications: ensureNotificationManager())
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
                                await ensureLiveActivityManager().startActivity(
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
            .sheet(isPresented: $showingShareCard) {
                if let weatherData = weatherService.weatherData {
                    ShareableWeatherCardSheet(
                        weatherData: weatherData,
                        locationName: displayLocationName
                    )
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
                    }
                    .accessibilityLabel("Favorites")
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Explore menu — groups Map, Chart, and Comparison
                    if weatherService.weatherData != nil {
                        Menu {
                            Button {
                                showingMap = true
                            } label: {
                                Label("Weather Map", systemImage: "map")
                            }
                            
                            Button {
                                showingHourlyChart = true
                            } label: {
                                Label("Hourly Chart", systemImage: "chart.xyaxis.line")
                            }
                            
                            Button {
                                showingComparison = true
                            } label: {
                                Label("Compare Locations", systemImage: "square.grid.2x2")
                            }
                        } label: {
                            Image(systemName: "square.grid.2x2")
                        }
                        .accessibilityLabel("Explore")
                    }
                    
                    // Settings button
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .onChange(of: settings.liveActivitiesEnabled) { _, enabled in
                Task {
                    if enabled {
                        // Start Live Activity when enabled
                        if let weatherData = weatherService.weatherData {
                            await ensureLiveActivityManager().startActivity(
                                weatherData: weatherData,
                                locationName: displayLocationName
                            )
                        }
                    } else {
                        // End all Live Activities when disabled
                        await ensureLiveActivityManager().endAllActivities()
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
    
    private func checkAndFetchWeather() {
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
            await ensureLiveActivityManager().updateActivity(weatherData: weatherData)
        }
    }
    
    // MARK: - Lazy Manager Helpers
    
    /// Lazily create NotificationManager only when settings sheet opens
    private func ensureNotificationManager() -> NotificationManager {
        if let existing = notificationManager {
            return existing
        }
        let manager = NotificationManager()
        manager.checkAuthorizationStatus()
        notificationManager = manager
        return manager
    }
    
    /// Lazily create LiveActivityManager only when Live Activities are needed
    @discardableResult
    private func ensureLiveActivityManager() -> LiveActivityManager {
        if let existing = liveActivityManager {
            return existing
        }
        let manager = LiveActivityManager()
        liveActivityManager = manager
        return manager
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
    @State private var isReady = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var needsLocationPermission: Bool {
        authorizationStatus == .notDetermined || 
        authorizationStatus == .denied || 
        authorizationStatus == .restricted
    }
    
    var body: some View {
        ZStack {
            // Deferred gradient + particles: render a solid color on the first frame,
            // then swap in the expensive MeshGradient once the view is on screen.
            if isReady {
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
                .transition(.opacity)
                
                // Floating weather particles (reduced for startup performance)
                FloatingSparkles(count: 8)
            } else {
                Color.blue.opacity(0.3)
                    .ignoresSafeArea()
            }
            
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
        .task {
            // Defer heavy rendering to after the first frame is on screen
            withAnimation(.easeIn(duration: 0.3)) {
                isReady = true
            }
            guard !reduceMotion else { return }
            // Slight delay so the gradient is visible before animation begins
            try? await Task.sleep(for: .milliseconds(100))
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
    ContentView(modelContainer: .constant(nil))
}


