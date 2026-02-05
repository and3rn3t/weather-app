//
//  Models.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import UserNotifications

// MARK: - Saved Location Model (SwiftData)

@Model
final class SavedLocation {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var order: Int
    var dateAdded: Date
    var isCurrentLocation: Bool
    
    init(
        name: String,
        latitude: Double,
        longitude: Double,
        order: Int = 0,
        isCurrentLocation: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.order = order
        self.dateAdded = Date()
        self.isCurrentLocation = isCurrentLocation
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Temperature Unit

enum TemperatureUnit: String, CaseIterable, Codable {
    case fahrenheit = "Fahrenheit (°F)"
    case celsius = "Celsius (°C)"
    
    var apiValue: String {
        switch self {
        case .fahrenheit: return "fahrenheit"
        case .celsius: return "celsius"
        }
    }
    
    var symbol: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        }
    }
}

// MARK: - Wind Speed Unit

enum WindSpeedUnit: String, CaseIterable, Codable {
    case mph = "Miles per hour (mph)"
    case kmh = "Kilometers per hour (km/h)"
    case ms = "Meters per second (m/s)"
    case knots = "Knots"
    
    var apiValue: String {
        switch self {
        case .mph: return "mph"
        case .kmh: return "kmh"
        case .ms: return "ms"
        case .knots: return "kn"
        }
    }
    
    var symbol: String {
        switch self {
        case .mph: return "mph"
        case .kmh: return "km/h"
        case .ms: return "m/s"
        case .knots: return "kts"
        }
    }
}

// MARK: - Precipitation Unit

enum PrecipitationUnit: String, CaseIterable, Codable {
    case inches = "Inches"
    case millimeters = "Millimeters"
    
    var apiValue: String {
        switch self {
        case .inches: return "inch"
        case .millimeters: return "mm"
        }
    }
    
    var symbol: String {
        switch self {
        case .inches: return "in"
        case .millimeters: return "mm"
        }
    }
}
