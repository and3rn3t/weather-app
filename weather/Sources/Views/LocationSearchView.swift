//
//  LocationSearchView.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
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
                Task {
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
            print("Search error: \(error)")
            searchResults = []
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        
        // Build location name
        var components: [String] = []
        if let locality = item.placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = item.placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let country = item.placemark.country, components.isEmpty {
            components.append(country)
        }
        
        let locationName = components.joined(separator: ", ")
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
        var components: [String] = []
        
        if let locality = mapItem.placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = mapItem.placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let country = mapItem.placemark.country {
            components.append(country)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}
