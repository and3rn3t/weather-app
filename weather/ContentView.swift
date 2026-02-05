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
    
    var body: some View {
        Group {
            if let weatherData = weatherService.weatherData {
                WeatherDetailView(weatherData: weatherData)
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
            if let location = newLocation {
                Task {
                    await weatherService.fetchWeather(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                }
            }
        }
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
        if let location = locationManager.location {
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
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading weather data...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Oops!")
                .font(.title.bold())
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retryAction) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
}

struct WelcomeView: View {
    let requestLocationAction: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "cloud.sun.rain.fill")
                .font(.system(size: 100))
                .symbolRenderingMode(.multicolor)
            
            VStack(spacing: 12) {
                Text("Welcome to Weather")
                    .font(.largeTitle.bold())
                
                Text("Get accurate weather forecasts for your location")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: requestLocationAction) {
                Label("Enable Location", systemImage: "location.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            
            Text("Location access is required to show weather for your area")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
