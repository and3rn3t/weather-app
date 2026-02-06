//
//  WeatherMapView.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI
import MapKit

// MARK: - Weather Map View

struct WeatherMapView: View {
    let weatherData: WeatherData?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    
    @State private var selectedLayer: MapLayer = .standard
    @State private var showingLayerPicker = false
    @State private var radarPath: String = ""
    @State private var isLoadingRadar = false
    @State private var hasLoadedRadar = false
    
    init(weatherData: WeatherData?, locationName: String, latitude: Double, longitude: Double) {
        self.weatherData = weatherData
        self.locationName = locationName
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map with radar overlay using UIKit wrapper
                RadarMapView(
                    coordinate: coordinate,
                    locationName: locationName,
                    weatherData: weatherData,
                    radarPath: radarPath,
                    showRadar: selectedLayer == .precipitation,
                    mapType: selectedLayer.mkMapType
                )
                .ignoresSafeArea(edges: .bottom)
                
                // Layer selector overlay
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // Layer picker button
                        Button {
                            showingLayerPicker.toggle()
                        } label: {
                            Image(systemName: "square.3.layers.3d")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .padding()
                    }
                    
                    // Weather legend
                    WeatherMapLegend(layer: selectedLayer)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Loading indicator for radar (only show when actively loading)
                if isLoadingRadar && !hasLoadedRadar {
                    VStack {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text("Loading radar...")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        Spacer()
                    }
                    .padding(.top, 60)
                }
            }
            .navigationTitle("Weather Map")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingLayerPicker) {
                MapLayerPicker(selectedLayer: $selectedLayer)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Refresh radar button
                    Button {
                        Task {
                            hasLoadedRadar = false
                            await loadRadarData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadRadarData()
            }
            .onChange(of: selectedLayer) { _, newLayer in
                if newLayer == .precipitation && radarPath.isEmpty {
                    Task {
                        await loadRadarData()
                    }
                }
            }
        }
    }
    
    private func loadRadarData() async {
        guard !hasLoadedRadar else { return }
        
        isLoadingRadar = true
        
        // Fetch the latest radar data from RainViewer API
        guard let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json") else {
            isLoadingRadar = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)
            
            if let latestRadar = response.radar.past.last {
                await MainActor.run {
                    radarPath = latestRadar.path
                    hasLoadedRadar = true
                    isLoadingRadar = false
                }
            } else {
                await MainActor.run {
                    isLoadingRadar = false
                }
            }
        } catch {
            print("Failed to load radar data: \(error)")
            await MainActor.run {
                isLoadingRadar = false
            }
        }
    }
}

// MARK: - UIKit Map View Wrapper

struct RadarMapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    let locationName: String
    let weatherData: WeatherData?
    let radarPath: String
    let showRadar: Bool
    let mapType: MKMapType
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        
        // Set initial region
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500000,
            longitudinalMeters: 500000
        )
        mapView.setRegion(region, animated: false)
        
        // Add weather annotation
        let annotation = WeatherAnnotation(
            coordinate: coordinate,
            title: locationName,
            weatherData: weatherData
        )
        mapView.addAnnotation(annotation)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map type
        mapView.mapType = mapType
        
        // Update radar overlay
        context.coordinator.updateRadarOverlay(
            mapView: mapView,
            radarPath: radarPath,
            showRadar: showRadar
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(weatherData: weatherData)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let weatherData: WeatherData?
        private var currentOverlay: MKTileOverlay?
        
        init(weatherData: WeatherData?) {
            self.weatherData = weatherData
        }
        
        func updateRadarOverlay(mapView: MKMapView, radarPath: String, showRadar: Bool) {
            // Remove existing overlay if conditions changed
            if let overlay = currentOverlay {
                mapView.removeOverlay(overlay)
                currentOverlay = nil
            }
            
            // Add new overlay if needed
            if showRadar && !radarPath.isEmpty {
                let template = "https://tilecache.rainviewer.com\(radarPath)/256/{z}/{x}/{y}/2/1_1.png"
                let overlay = MKTileOverlay(urlTemplate: template)
                overlay.canReplaceMapContent = false
                mapView.addOverlay(overlay, level: .aboveLabels)
                currentOverlay = overlay
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
                renderer.alpha = 0.7
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let weatherAnnotation = annotation as? WeatherAnnotation else { return nil }
            
            let identifier = "WeatherAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Create custom view for annotation
            let hostingController = UIHostingController(
                rootView: WeatherAnnotationContent(weatherData: weatherAnnotation.weatherData)
            )
            hostingController.view.backgroundColor = .clear
            hostingController.view.frame = CGRect(x: 0, y: 0, width: 60, height: 70)
            
            // Convert to image
            let renderer = UIGraphicsImageRenderer(size: hostingController.view.bounds.size)
            let image = renderer.image { _ in
                hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
            }
            
            annotationView?.image = image
            annotationView?.centerOffset = CGPoint(x: 0, y: -35)
            
            return annotationView
        }
    }
}

// MARK: - Weather Annotation

class WeatherAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let weatherData: WeatherData?
    
    init(coordinate: CLLocationCoordinate2D, title: String, weatherData: WeatherData?) {
        self.coordinate = coordinate
        self.title = title
        self.weatherData = weatherData
    }
}

struct WeatherAnnotationContent: View {
    let weatherData: WeatherData?
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(temperatureGradient)
                    .frame(width: 44, height: 44)
                
                Image(systemName: weatherIcon)
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: 4)
            
            if let temp = weatherData?.current.temperature2m {
                Text("\(Int(temp))°")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(temperatureColor.opacity(0.9), in: Capsule())
            }
        }
    }
    
    private var weatherIcon: String {
        guard let code = weatherData?.current.weatherCode else { return "cloud" }
        return WeatherCondition(code: code).sfSymbol
    }
    
    private var temperatureGradient: LinearGradient {
        LinearGradient(
            colors: [temperatureColor.opacity(0.8), temperatureColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var temperatureColor: Color {
        guard let temp = weatherData?.current.temperature2m else { return .blue }
        
        switch temp {
        case ..<32: return .blue
        case 32..<50: return .cyan
        case 50..<68: return .green
        case 68..<85: return .orange
        default: return .red
        }
    }
}

// MARK: - RainViewer API Response

struct RainViewerResponse: Codable {
    let version: String
    let generated: Int
    let host: String
    let radar: RadarData
    
    struct RadarData: Codable {
        let past: [RadarFrame]
        let nowcast: [RadarFrame]
    }
    
    struct RadarFrame: Codable {
        let time: Int
        let path: String
    }
}

// MARK: - Map Layers

enum MapLayer: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"
    case precipitation = "Precipitation"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.americas"
        case .hybrid: return "map.fill"
        case .precipitation: return "cloud.rain"
        }
    }
    
    var mapStyle: MapStyle {
        switch self {
        case .standard:
            return .standard
        case .satellite:
            return .imagery
        case .hybrid:
            return .hybrid
        case .precipitation:
            return .standard(emphasis: .muted)
        }
    }
    
    var mkMapType: MKMapType {
        switch self {
        case .standard, .precipitation: return .standard
        case .satellite: return .satellite
        case .hybrid: return .hybrid
        }
    }
    
    var isWeatherLayer: Bool {
        self == .precipitation
    }
}

// MARK: - Map Layer Picker

struct MapLayerPicker: View {
    @Binding var selectedLayer: MapLayer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Base Maps") {
                    ForEach([MapLayer.standard, .satellite, .hybrid]) { layer in
                        layerRow(layer)
                    }
                }
                
                Section {
                    layerRow(.precipitation)
                } header: {
                    Text("Weather Layers")
                } footer: {
                    Text("Precipitation layer shows live radar data from RainViewer.")
                        .font(.caption)
                }
            }
            .navigationTitle("Map Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func layerRow(_ layer: MapLayer) -> some View {
        Button {
            selectedLayer = layer
            dismiss()
        } label: {
            HStack {
                Image(systemName: layer.icon)
                    .font(.title3)
                    .foregroundStyle(layer.isWeatherLayer ? .blue : .primary)
                    .frame(width: 30)
                
                Text(layer.rawValue)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if selectedLayer == layer {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}

// MARK: - Weather Map Legend

struct WeatherMapLegend: View {
    let layer: MapLayer
    
    var body: some View {
        if layer == .precipitation {
            HStack(spacing: 4) {
                ForEach(legendItems, id: \.label) { item in
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(item.color)
                            .frame(width: 30, height: 8)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        
                        Text(item.label)
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var legendItems: [(color: Color, label: String)] {
        [
            (.green.opacity(0.5), "Light"),
            (.green, "Mod"),
            (.yellow, "Heavy"),
            (.orange, "Intense"),
            (.red, "Extreme")
        ]
    }
}

// MARK: - Map Button for Main View

struct MapButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "map")
                Text("Weather Map")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

#Preview {
    WeatherMapView(
        weatherData: nil,
        locationName: "San Francisco",
        latitude: 37.7749,
        longitude: -122.4194
    )
}
