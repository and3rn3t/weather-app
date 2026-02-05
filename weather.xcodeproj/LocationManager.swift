//
//  LocationManager.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation
import CoreLocation
import Contacts

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    var location: CLLocation?
    var locationName: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestLocation() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || 
                  authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else {
            errorMessage = "Location access denied. Please enable in Settings."
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            if authorizationStatus == .authorizedWhenInUse || 
               authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            } else if authorizationStatus == .denied || authorizationStatus == .restricted {
                errorMessage = "Location access denied. Please enable in Settings."
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let newLocation = locations.last else { return }
            location = newLocation
            errorMessage = nil
            
            // Reverse geocode to get location name
            await fetchLocationName(for: newLocation)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reverse Geocoding
    
    private func fetchLocationName(for location: CLLocation) async {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                await MainActor.run {
                    locationName = formatLocationName(from: placemark)
                }
            }
        } catch {
            print("Geocoding error: \(error.localizedDescription)")
        }
    }
    
    private func formatLocationName(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        
        if components.isEmpty, let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}
