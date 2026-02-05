//
//  LocationManager.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation
import CoreLocation

@Observable
final class LocationManager: NSObject {
    var location: CLLocation?
    var locationName: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Reverse geocoding failed: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                // Format location name
                var components: [String] = []
                
                if let locality = placemark.locality {
                    components.append(locality)
                }
                
                if let administrativeArea = placemark.administrativeArea {
                    components.append(administrativeArea)
                }
                
                self.locationName = components.joined(separator: ", ")
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.first {
            location = newLocation
            reverseGeocode(location: newLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Failed to get location: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable it in Settings."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
