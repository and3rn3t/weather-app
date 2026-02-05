//
//  FavoritesManager.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import Foundation
import CoreLocation
import SwiftData
import SwiftUI

// MARK: - Favorites Manager

@Observable
class FavoritesManager {
    var savedLocations: [SavedLocation] = []
    var currentLocationIndex: Int = 0
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSavedLocations()
    }
    
    // MARK: - Load & Save
    
    func loadSavedLocations() {
        let descriptor = FetchDescriptor<SavedLocation>(
            sortBy: [SortDescriptor(\.order)]
        )
        
        do {
            savedLocations = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch saved locations: \(error)")
            savedLocations = []
        }
    }
    
    func addLocation(name: String, coordinate: CLLocationCoordinate2D) {
        // Check if location already exists
        if savedLocations.contains(where: { 
            abs($0.latitude - coordinate.latitude) < 0.01 && 
            abs($0.longitude - coordinate.longitude) < 0.01 
        }) {
            return
        }
        
        let location = SavedLocation(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            order: savedLocations.count
        )
        
        modelContext.insert(location)
        
        do {
            try modelContext.save()
            loadSavedLocations()
        } catch {
            print("Failed to save location: \(error)")
        }
    }
    
    func removeLocation(_ location: SavedLocation) {
        modelContext.delete(location)
        
        do {
            try modelContext.save()
            loadSavedLocations()
        } catch {
            print("Failed to delete location: \(error)")
        }
    }
    
    func moveLocation(from source: IndexSet, to destination: Int) {
        savedLocations.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for (index, location) in savedLocations.enumerated() {
            location.order = index
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to reorder locations: \(error)")
        }
    }
    
    func isFavorite(coordinate: CLLocationCoordinate2D) -> Bool {
        savedLocations.contains { location in
            abs(location.latitude - coordinate.latitude) < 0.01 &&
            abs(location.longitude - coordinate.longitude) < 0.01
        }
    }
    
    func toggleFavorite(name: String, coordinate: CLLocationCoordinate2D) {
        if let existing = savedLocations.first(where: { 
            abs($0.latitude - coordinate.latitude) < 0.01 && 
            abs($0.longitude - coordinate.longitude) < 0.01 
        }) {
            removeLocation(existing)
        } else {
            addLocation(name: name, coordinate: coordinate)
        }
    }
}
