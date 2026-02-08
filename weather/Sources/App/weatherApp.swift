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
    let modelContainer: ModelContainer
    @State private var themeManager = ThemeManager()
    
    init() {
        let appInitStart = CFAbsoluteTimeGetCurrent()
        os_signpost(.begin, log: StartupSignpost.log, name: "App.init")

        // Log time elapsed since process launch (includes pre-main dylib loading)
        let preMainMs = (appInitStart - StartupSignpost.processStart) * 1_000
        Logger.startup.info("Pre-main elapsed: \(preMainMs, format: .fixed(precision: 0))ms")

        // MARK: - ModelContainer Initialization
        os_signpost(.begin, log: StartupSignpost.log, name: "ModelContainer.init")
        let containerStart = CFAbsoluteTimeGetCurrent()
        do {
            let config = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            modelContainer = try ModelContainer(
                for: SavedLocation.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let containerMs = (CFAbsoluteTimeGetCurrent() - containerStart) * 1_000
        os_signpost(.end, log: StartupSignpost.log, name: "ModelContainer.init")
        Logger.startup.info("ModelContainer.init: \(containerMs, format: .fixed(precision: 0))ms")

        let appInitMs = (CFAbsoluteTimeGetCurrent() - appInitStart) * 1_000
        os_signpost(.end, log: StartupSignpost.log, name: "App.init")
        Logger.startup.info("App.init total: \(appInitMs, format: .fixed(precision: 0))ms")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(themeManager)
                .task {
                    // Defer non-critical initialization to after first render
                    await deferredInitialization()
                }
        }
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
