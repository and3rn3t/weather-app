//
//  weatherApp.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import SwiftUI
import SwiftData
import AppIntents

@main
struct WeatherApp: App {
    let modelContainer: ModelContainer
    @State private var themeManager = ThemeManager()
    
    init() {
        // MARK: - Launch Optimization
        // Only perform critical initialization here
        // Defer non-essential work to after first frame renders
        
        do {
            // Configure SwiftData with optimized settings
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
