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
struct weatherApp: App {
    let modelContainer: ModelContainer
    @State private var themeManager = ThemeManager()
    
    init() {
        do {
            modelContainer = try ModelContainer(for: SavedLocation.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Register App Shortcuts with Siri
        WeatherAppShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(themeManager)
        }
    }
}
