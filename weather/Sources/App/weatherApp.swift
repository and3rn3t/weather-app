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
    @State private var themeManager = ThemeManager()
    // Lifted out of ContentView so they initialize as early as possible
    // and don't block the first SwiftUI render pass.
    @State private var locationManager = LocationManager()
    @State private var weatherService = WeatherService()
    
    init() {
        #if DEBUG
        resetStartupLog()
        #endif
        os_signpost(.begin, log: StartupSignpost.log, name: "App.init")

        // Log time elapsed since process launch (includes pre-main dylib loading)
        let preMainMs = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
        startupLog("Pre-main elapsed: \(String(format: "%.0f", preMainMs))ms")

        let appInitMs = (CFAbsoluteTimeGetCurrent() - StartupSignpost.processStart) * 1_000
        os_signpost(.end, log: StartupSignpost.log, name: "App.init")
        startupLog("App.init total: \(String(format: "%.0f", appInitMs))ms")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .environment(locationManager)
                .environment(weatherService)
                .task {
                    // Defer non-critical initialization to after first render
                    await deferredInitialization()
                }
        }
        // ModelContainer is created lazily by the scene modifier — after the
        // first view appears — so it no longer blocks App.init on the main thread.
        .modelContainer(for: SavedLocation.self)
    }
    
    // MARK: - Deferred Initialization
    
    /// Perform non-critical initialization after the UI is visible
    @MainActor
    private func deferredInitialization() async {
        // Small delay to ensure UI is fully rendered
        try? await Task.sleep(for: .milliseconds(100))
        
        // Register App Shortcuts with Siri (can be deferred)
        WeatherAppShortcuts.updateAppShortcutParameters()
    }
}
