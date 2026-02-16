//
//  FavoritesView.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI
import SwiftData
import CoreLocation

struct FavoritesView: View {
    @Environment(FavoritesManager.self) private var favoritesManager
    @Environment(\.dismiss) private var dismiss
    
    let onLocationSelected: (SavedLocation) -> Void
    
    @State private var showingSearch = false
    @State private var locationWeather: [String: WeatherData] = [:]
    @State private var isLoadingWeather = false
    
    var body: some View {
        NavigationStack {
            Group {
                if favoritesManager.savedLocations.isEmpty {
                    emptyState
                } else {
                    locationsList
                }
            }
            .navigationTitle("Saved Locations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.glass)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .sheet(isPresented: $showingSearch) {
                LocationSearchView { coordinate, locationName in
                    favoritesManager.addLocation(name: locationName, coordinate: coordinate)
                }
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Saved Locations", systemImage: "location.slash")
        } description: {
            Text("Add locations to quickly check their weather")
        } actions: {
            Button {
                showingSearch = true
            } label: {
                Label("Add Location", systemImage: "plus")
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
    }
    
    private var locationsList: some View {
        List {
            ForEach(favoritesManager.savedLocations) { location in
                Button {
                    onLocationSelected(location)
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        // Weather icon or location icon
                        if let weather = locationWeather[location.id.uuidString] {
                            Image(systemName: WeatherCondition(code: weather.current.weatherCode).symbolName)
                                .font(.title2)
                                .symbolRenderingMode(.multicolor)
                                .frame(width: 40)
                        } else {
                            Image(systemName: location.isCurrentLocation ? "location.fill" : "mappin.and.ellipse")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.blue.gradient)
                                .frame(width: 40)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name)
                                .font(.headline)
                            
                            if let weather = locationWeather[location.id.uuidString] {
                                Text(WeatherCondition(code: weather.current.weatherCode).description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if isLoadingWeather {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                        }
                        
                        Spacer()
                        
                        // Temperature or chevron
                        if let weather = locationWeather[location.id.uuidString] {
                            Text("\(Int(weather.current.temperature2m))°")
                                .font(.title2.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.primary)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let location = favoritesManager.savedLocations[index]
                    favoritesManager.removeLocation(location)
                }
            }
            .onMove { from, to in
                favoritesManager.moveLocation(from: from, to: to)
            }
        }
        .listStyle(.plain)
        .task {
            await loadWeatherPreviews()
        }
    }
    
    private func loadWeatherPreviews() async {
        guard !favoritesManager.savedLocations.isEmpty else { return }
        isLoadingWeather = true
        
        await withTaskGroup(of: (String, WeatherData?).self) { group in
            for location in favoritesManager.savedLocations {
                let lat = location.latitude
                let lon = location.longitude
                let id = location.id.uuidString
                
                group.addTask {
                    let service = await MainActor.run { WeatherService() }
                    await service.fetchWeatherData(latitude: lat, longitude: lon)
                    let data = await MainActor.run { service.weatherData }
                    return (id, data)
                }
            }
            
            for await (id, data) in group {
                if let data = data {
                    locationWeather[id] = data
                }
            }
        }
        isLoadingWeather = false
    }
}

// MARK: - Favorites Button (for Weather Detail View)

struct FavoritesButton: View {
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    @Environment(FavoritesManager.self) private var favoritesManager
    
    private var isFavorite: Bool {
        favoritesManager.isFavorite(coordinate: coordinate)
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                favoritesManager.toggleFavorite(name: locationName, coordinate: coordinate)
            }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isFavorite ? Color.yellow : Color.blue)
                .frame(width: 44, height: 44)
                .background(.secondary.opacity(0.2), in: Circle())
                .symbolEffect(.bounce, value: isFavorite)
        }
    }
}

#Preview {
    FavoritesView { _ in }
        .environment(FavoritesManager(modelContext: ModelContext(
            try! ModelContainer(for: SavedLocation.self)
        )))
}
