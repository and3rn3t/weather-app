//
//  LocationSearchView.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import SwiftUI
import MapKit
import OSLog

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    
    let onLocationSelected: (CLLocationCoordinate2D, String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(searchResults, id: \.self) { item in
                        Button(action: {
                            selectLocation(item)
                        }) {
                            LocationSearchRow(mapItem: item)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "City, state, or country")
            .onChange(of: searchText) { _, newValue in
                // Cancel previous search task
                searchTask?.cancel()
                
                // Debounce: wait 300ms before searching
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    await searchLocations(query: newValue)
                }
            }
        }
    }
    
    private func searchLocations(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        defer { isSearching = false }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            searchResults = response.mapItems
        } catch {
            Logger.search.error("Location search failed: \(error.localizedDescription)")
            searchResults = []
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        let coordinate = item.location.coordinate
        
        // Build location name using iOS 26 address APIs
        var locationName: String
        
        if let cityWithContext = item.addressRepresentations?.cityWithContext {
            // cityWithContext includes "City, State" format
            locationName = cityWithContext
        } else if let cityName = item.addressRepresentations?.cityName {
            locationName = cityName
        } else if let regionName = item.addressRepresentations?.regionName {
            locationName = regionName
        } else {
            locationName = item.name ?? "Unknown Location"
        }
        
        onLocationSelected(coordinate, locationName)
        dismiss()
    }
}

struct LocationSearchRow: View {
    let mapItem: MKMapItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mapItem.name ?? "Unknown")
                .font(.body.weight(.medium))
            
            if let address = formattedAddress {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var formattedAddress: String? {
        // Use iOS 26 addressRepresentations API
        // cityWithContext gives "City, State" format, and we can optionally include region (country)
        if let cityWithContext = mapItem.addressRepresentations?.cityWithContext(.full) {
            return cityWithContext
        } else if let cityName = mapItem.addressRepresentations?.cityName {
            if let regionName = mapItem.addressRepresentations?.regionName {
                return "\(cityName), \(regionName)"
            }
            return cityName
        } else if let regionName = mapItem.addressRepresentations?.regionName {
            return regionName
        }
        return nil
    }
}
