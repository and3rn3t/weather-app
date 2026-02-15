//
//  weatherApp.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import SwiftUI
import SwiftData
import CoreLocation
import AppIntents
import OSLog
import os.signpost

@main
struct WeatherApp: App {
    // All observable state created here so it initializes before the first
    // SwiftUI render pass, instead of blocking ContentView's body evaluation.
    @State private var themeManager = ThemeManager()
    @State private var locationManager = LocationManager()
    @State private var weatherService = WeatherService()
    @State private var settings = SettingsManager()

    /// ModelContainer is loaded asynchronously so SQLite setup never blocks
    /// the main thread. Nil until ready — SwiftData-dependent UI (Favorites)
    /// is already deferred behind a sleep in ContentView's secondary task.
    @State private var modelContainer: ModelContainer?

    init() {
        #if DEBUG
        resetStartupLog()
        #endif
        os_signpost(.begin, log: StartupSignpost.log, name: "App.init")
        
        // Start app initialization performance tracking
        PerformanceTracker.shared.startTrace("app_initialization", attributes: ["app_version": Bundle.main.appVersionLong])
        
        // Initialize MetricKit telemetry (crash reporting & performance monitoring)
        _ = TelemetryManager.shared

        #if DEBUG
        let preMainMs = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
        startupLog("Pre-main elapsed: \(String(format: "%.0f", preMainMs))ms")
        #endif

        // Kick off ModelContainer creation on a background thread immediately.
        // By the time the user taps Favorites it will long be ready.
        Task.detached(priority: .utility) { [self] in
            PerformanceTracker.shared.startTrace("model_container_background_init")
            let container: ModelContainer
            do {
                container = try ModelContainer(for: SavedLocation.self)
            } catch {
                Logger.startup.error("ModelContainer failed: \(error)")
                PerformanceTracker.shared.recordEvent("model_container_init_failed", parameters: [
                    "error": error.localizedDescription
                ])
                PerformanceTracker.shared.stopTrace("model_container_background_init")
                return
            }
            
            await MainActor.run {
                self.modelContainer = container
            }
            PerformanceTracker.shared.stopTrace("model_container_background_init")
            PerformanceTracker.shared.recordEvent("model_container_init_success")
        }

        // If location is already authorized, request GPS fix immediately —
        // don't wait for ContentView's .task (which won't fire for ~3-4s).
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
            #if DEBUG
            startupLog("GPS request fired eagerly from App.init")
            #endif
        }

        // Complete app initialization tracking
        PerformanceTracker.shared.stopTrace("app_initialization")
        PerformanceTracker.shared.recordEvent("app_init_complete", parameters: [
            "location_authorized": String(locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways)
        ])

        os_signpost(.end, log: StartupSignpost.log, name: "App.init")
        #if DEBUG
        let appInitMs = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
        startupLog("App.init total: \(String(format: "%.0f", appInitMs))ms")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: $modelContainer)
                .environment(themeManager)
                .environment(locationManager)
                .environment(weatherService)
                .environment(settings)
                .task {
                    await deferredInitialization()
                }
        }
    }

    // MARK: - Deferred Initialization

    @MainActor
    private func deferredInitialization() async {
        try? await Task.sleep(for: .milliseconds(100))
        WeatherAppShortcuts.updateAppShortcutParameters()
    }
}
