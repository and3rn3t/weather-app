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
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
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
