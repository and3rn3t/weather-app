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
        // MARK: - Launch Instrumentation
        os_signpost(.begin, log: StartupSignpost.log, name: "App.init")

        // MARK: - ModelContainer initialization
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
        let containerElapsed = (CFAbsoluteTimeGetCurrent() - containerStart) * 1_000
        os_signpost(.end, log: StartupSignpost.log, name: "ModelContainer.init")
        Logger.startup.info("ModelContainer.init: \(containerElapsed, format: .fixed(precision: 0))ms")

        os_signpost(.end, log: StartupSignpost.log, name: "App.init")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(themeManager)
                .task {
                    await deferredInitialization()
                }
        }
    }

    // MARK: - Deferred Initialization

    /// Perform non-critical initialization after the UI is visible
    @MainActor
    private func deferredInitialization() async {
        // Small delay to ensure UI is fully rendered before doing any extra work
        try? await Task.sleep(for: .milliseconds(100))

        os_signpost(.event, log: StartupSignpost.log, name: "DeferredInit.begin")
        WeatherAppShortcuts.updateAppShortcutParameters()
        os_signpost(.event, log: StartupSignpost.log, name: "DeferredInit.end")
    }
}
