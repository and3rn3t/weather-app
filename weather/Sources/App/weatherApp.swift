//
//  weatherApp.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import AppIntents
import CoreLocation
import os.signpost
import OSLog
import SwiftData
import SwiftUI

@main
struct WeatherApp: App {
    // All observable state created here so it initializes before the first
    // SwiftUI render pass, instead of blocking ContentView's body evaluation.
    @State private var themeManager = ThemeManager()
    @State private var locationManager = LocationManager()
    @State private var weatherService = WeatherService.shared
    @State private var settings = SettingsManager()
    @State private var notificationManager = NotificationManager()

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
        Task { @MainActor in
            PerformanceTracker.shared.startTrace("app_initialization", attributes: ["app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"])
        }
        
        // Initialize MetricKit telemetry (crash reporting & performance monitoring)
        _ = TelemetryManager.shared

        #if DEBUG
        let preMainMs = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
        startupLog("Pre-main elapsed: \(String(format: "%.0f", preMainMs))ms")
        #endif

        // Complete app initialization tracking. LocationManager.init already fires the
        // GPS request when authorized, and @State must not be read from App.init.
        Task { @MainActor in
            PerformanceTracker.shared.stopTrace("app_initialization")
            PerformanceTracker.shared.recordEvent("app_init_complete")
        }

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
                .environment(notificationManager)
                .task {
                    await deferredInitialization()
                }
        }
    }

    // MARK: - Deferred Initialization

    /// Builds the container off the main thread so SQLite setup never blocks the UI.
    private nonisolated static func makeModelContainer() async -> ModelContainer? {
        await PerformanceTracker.shared.startTrace("model_container_background_init")
        defer { Task { @MainActor in PerformanceTracker.shared.stopTrace("model_container_background_init") } }
        do {
            let container = try ModelContainer(for: SavedLocation.self)
            await PerformanceTracker.shared.recordEvent("model_container_init_success")
            return container
        } catch {
            Logger.startup.error("ModelContainer failed: \(error)")
            await PerformanceTracker.shared.recordEvent("model_container_init_failed", parameters: [
                "error": error.localizedDescription
            ])
            return nil
        }
    }

    @MainActor
    private func deferredInitialization() async {
        // Publish the container from the view's task, where @State is installed,
        // so ContentView is guaranteed to observe it (App.init writes were lost).
        async let container = Self.makeModelContainer()

        notificationManager.checkAuthorizationStatus()
        weatherService.onFetchSucceeded = { [notificationManager, settings] weather, alerts, locationName in
            await notificationManager.handleWeatherUpdate(
                weather: weather,
                alerts: alerts,
                locationName: locationName,
                preferences: NotificationPreferences(settings: settings)
            )
        }
        try? await Task.sleep(for: .milliseconds(100))
        WeatherAppShortcuts.updateAppShortcutParameters()
        modelContainer = await container
    }
}
