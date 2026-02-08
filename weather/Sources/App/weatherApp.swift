//
//  weatherApp.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import SwiftUI
import SwiftData
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

        let preMainMs = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
        startupLog("Pre-main elapsed: \(String(format: "%.0f", preMainMs))ms")

        let appInitMs = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
        os_signpost(.end, log: StartupSignpost.log, name: "App.init")
        startupLog("App.init total: \(String(format: "%.0f", appInitMs))ms")
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
