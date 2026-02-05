//
//  ContentView.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var locationManager = LocationManager()
    @State private var weatherService = WeatherService()
    @State private var showingSearch = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    
    var body: some View {
        Group {
            if let weatherData = weatherService.weatherData {
                WeatherDetailView(
                    weatherData: weatherData,
                    locationName: displayLocationName,
                    onRefresh: refreshWeather,
                    onSearchTapped: { showingSearch = true }
                )
            } else if weatherService.isLoading {
                LoadingView()
            } else if let errorMessage = weatherService.errorMessage ?? locationManager.errorMessage {
                ErrorView(message: errorMessage, retryAction: fetchWeather)
            } else {
                WelcomeView(requestLocationAction: requestLocation)
            }
        }
        .task {
            await checkAndFetchWeather()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            // Only use location manager if no manual location selected
            if selectedCoordinate == nil, let location = newLocation {
                Task {
                    await weatherService.fetchWeather(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            LocationSearchView { coordinate, locationName in
                selectedCoordinate = coordinate
                selectedLocationName = locationName
                Task {
                    await weatherService.fetchWeather(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                }
            }
        }
    }
    
    private var displayLocationName: String? {
        selectedLocationName ?? locationManager.locationName
    }
    
    private func checkAndFetchWeather() async {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    private func requestLocation() {
        locationManager.requestLocation()
    }
    
    private func fetchWeather() {
        if let coordinate = selectedCoordinate {
            // Fetch for manually selected location
            Task {
                await weatherService.fetchWeather(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            }
        } else if let location = locationManager.location {
            // Fetch for current location
            Task {
                await weatherService.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        } else {
            locationManager.requestLocation()
        }
    }
    
    private func refreshWeather() async {
        if let coordinate = selectedCoordinate {
            await weatherService.fetchWeather(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } else if let location = locationManager.location {
            await weatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.8)
                .tint(.blue)
            
            Text("Loading weather data...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 72))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.orange.gradient)
            
            VStack(spacing: 12) {
                Text("Oops!")
                    .font(.title.bold())
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: retryAction) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.bottom, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

struct WelcomeView: View {
    let requestLocationAction: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "cloud.sun.rain.fill")
                    .font(.system(size: 120))
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.pulse)
                
                VStack(spacing: 12) {
                    Text("Welcome to Weather")
                        .font(.largeTitle.bold())
                    
                    Text("Get accurate weather forecasts\nfor your location")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: requestLocationAction) {
                    Label("Enable Location", systemImage: "location.fill")
                        .font(.headline)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                
                Text("Location access is required to show\nweather for your area")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    ContentView()
}
