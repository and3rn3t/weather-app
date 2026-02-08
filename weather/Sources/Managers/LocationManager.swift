//
//  LocationManager.swift
//  weather
//
//  Created by Matt on 2/4/26.
//

import Foundation
import CoreLocation
import Contacts
@preconcurrency import MapKit
import OSLog
import os.signpost

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    var location: CLLocation?
    var locationName: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String?
    
    override init() {
        super.init()
        os_signpost(.begin, log: StartupSignpost.log, name: "LocationManager.init")
        manager.delegate = self
        // Kilometer accuracy is sufficient for weather and produces a much faster initial fix
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
        os_signpost(.end, log: StartupSignpost.log, name: "LocationManager.init")
        #if DEBUG
        startupLog("LocationManager.init complete, auth=\(self.authorizationStatus.rawValue)")
        #endif
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
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            
            if status == .authorizedWhenInUse || 
               status == .authorizedAlways {
                self.manager.requestLocation()
            } else if status == .denied || status == .restricted {
                self.errorMessage = "Location access denied. Please enable in Settings."
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let newLocation = locations.last else { return }
            self.location = newLocation
            self.errorMessage = nil
            
            // Reverse geocode to get location name
            await self.fetchLocationName(for: newLocation)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reverse Geocoding
    
    @MainActor
    private func fetchLocationName(for location: CLLocation) async {
        do {
            guard let request = MKReverseGeocodingRequest(location: location) else { return }
            let mapItems = try await request.mapItems
            
            if let mapItem = mapItems.first {
                locationName = formatLocationName(from: mapItem)
            }
        } catch {
            Logger.location.warning("Reverse geocoding failed: \(error.localizedDescription)")
        }
    }
    
    private func formatLocationName(from mapItem: MKMapItem) -> String {
        // Use the short address for a concise location name, falling back to full address
        if let address = mapItem.address {
            if let shortAddress = address.shortAddress {
                return shortAddress
            }
            return address.fullAddress
        }
        
        // Fallback to name if address isn't available
        return mapItem.name ?? "Unknown Location"
    }
}
