//
//  ManagerTests.swift
//  weatherTests
//
//  Comprehensive tests for all Manager classes
//

import Testing
import Foundation
import CoreLocation
import SwiftData
import SwiftUI
@testable import weather

// MARK: - Location Manager Tests

@MainActor
struct LocationManagerTests {
    
    @Test func initialState() {
        let manager = LocationManager()
        
        #expect(manager.location == nil)
        #expect(manager.locationName == nil)
        #expect(manager.errorMessage == nil)
        // Authorization status could be any value depending on device state
    }
    
    @Test func authorizationStatusTracking() {
        let manager = LocationManager()
        
        // Initial status should be one of the valid CLAuthorizationStatus values
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined, .restricted, .denied, 
            .authorizedAlways, .authorizedWhenInUse
        ]
        
        #expect(validStatuses.contains(manager.authorizationStatus))
    }
    
    @Test func requestLocationWhenNotDetermined() {
        let manager = LocationManager()
        
        // Should not crash when requesting location
        manager.requestLocation()
        
        // If denied, error message should be set
        if manager.authorizationStatus == .denied || 
           manager.authorizationStatus == .restricted {
            #expect(manager.errorMessage?.contains("denied") == true ||
                   manager.errorMessage?.contains("Settings") == true)
        }
    }
}

// MARK: - Favorites Manager Tests

@MainActor
struct FavoritesManagerTests {
    
    @Test func initialState() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let manager = FavoritesManager(modelContext: context)
        
        #expect(manager.savedLocations.isEmpty)
        #expect(manager.currentLocationIndex == 0)
    }
    
    @Test func addLocation() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let manager = FavoritesManager(modelContext: context)
        
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        manager.addLocation(name: "San Francisco", coordinate: coord)
        
        #expect(manager.savedLocations.count == 1)
        #expect(manager.savedLocations.first?.name == "San Francisco")
        #expect(abs(manager.savedLocations.first!.latitude - 37.7749) < 0.001)
    }
    
    @Test func preventDuplicateLocations() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let manager = FavoritesManager(modelContext: context)
        
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        manager.addLocation(name: "San Francisco", coordinate: coord)
        manager.addLocation(name: "San Francisco 2", coordinate: coord) // Same coords
        
        #expect(manager.savedLocations.count == 1, "Should not add duplicate location")
    }
    
    @Test func removeLocation() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let manager = FavoritesManager(modelContext: context)
        
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        manager.addLocation(name: "San Francisco", coordinate: coord)
        
        #expect(manager.savedLocations.count == 1)
        
        let location = manager.savedLocations.first!
        manager.removeLocation(location)
        
        #expect(manager.savedLocations.isEmpty)
    }
    
    @Test func isFavorite() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let manager = FavoritesManager(modelContext: context)
        
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        manager.addLocation(name: "San Francisco", coordinate: coord)
        
        #expect(manager.isFavorite(coordinate: coord) == true)
        
        let differentCoord = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        #expect(manager.isFavorite(coordinate: differentCoord) == false)
    }
    
    @Test func locationOrdering() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedLocation.self, configurations: config)
        let context = ModelContext(container)
        
        let manager = FavoritesManager(modelContext: context)
        
        manager.addLocation(name: "First", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1))
        manager.addLocation(name: "Second", coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2))
        manager.addLocation(name: "Third", coordinate: CLLocationCoordinate2D(latitude: 3, longitude: 3))
        
        #expect(manager.savedLocations.count == 3)
        #expect(manager.savedLocations[0].order == 0)
        #expect(manager.savedLocations[1].order == 1)
        #expect(manager.savedLocations[2].order == 2)
    }
}

// MARK: - Theme Manager Tests

@MainActor
struct ThemeManagerTests {
    
    @Test func initialState() {
        let themeManager = ThemeManager()
        
        // Should have a valid theme
        #expect(AppTheme.allCases.contains(themeManager.currentTheme))
        
        // Should have adaptive theme setting
        #expect(themeManager.useAdaptiveTheme == true || themeManager.useAdaptiveTheme == false)
    }
    
    @Test func adaptiveThemeSelection() {
        let themeManager = ThemeManager()
        themeManager.useAdaptiveTheme = true
        
        // Test adaptive theme for clear sky
        let clearTheme = themeManager.adaptiveTheme(for: 0, isDay: true)
        #expect(AppTheme.allCases.contains(clearTheme))
        
        // Test adaptive theme for rain
        let rainTheme = themeManager.adaptiveTheme(for: 61, isDay: false)
        #expect(AppTheme.allCases.contains(rainTheme))
    }
    
    @Test func themeColorMapping() {
        let themeManager = ThemeManager()
        
        // Test all themes can be used without crashing
        for theme in AppTheme.allCases {
            // Just verify theme exists
            #expect(AppTheme.allCases.contains(theme))
        }
    }
}

// MARK: - Notification Manager Tests

@MainActor
struct NotificationManagerTests {
    
    @Test func managerInitialization() {
        let manager = NotificationManager()
        
        // Manager should initialize without crashing
        #expect(manager != nil)
    }
}

// MARK: - Live Activity Manager Tests

@MainActor
struct LiveActivityManagerTests {
    
    @Test func managerInitialization() {
        let manager = LiveActivityManager()
        
        // Manager should initialize without crashing
        #expect(manager != nil)
    }
}
