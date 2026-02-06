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
    
    @State private var position: MapCameraPosition
    @State private var selectedLayer: MapLayer = .standard
    @State private var showingLayerPicker = false
    @State private var radarTimestamp: String = ""
    @State private var isLoadingRadar = false
    
    init(weatherData: WeatherData?, locationName: String, latitude: Double, longitude: Double) {
        self.weatherData = weatherData
        self.locationName = locationName
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Initialize camera position centered on the location
        _position = State(initialValue: .camera(
            MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                     distance: 500000, // ~500km view for better radar coverage
                     heading: 0,
                     pitch: 0)
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map with optional radar overlay
                MapReader { reader in
                    Map(position: $position) {
                        // Weather annotation at current location
                        Annotation(locationName, coordinate: coordinate) {
                            WeatherAnnotationView(weatherData: weatherData)
                        }
                    }
                    .mapStyle(selectedLayer.mapStyle)
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                        MapUserLocationButton()
                    }
                    .overlay {
                        // Radar overlay when precipitation layer is selected
                        if selectedLayer == .precipitation && !radarTimestamp.isEmpty {
                            RadarOverlayView(timestamp: radarTimestamp, position: position)
                                .allowsHitTesting(false)
                        }
                    }
                }
                
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
                
                // Loading indicator for radar
                if isLoadingRadar {
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
                    Button {
                        // Reset to current location
                        withAnimation {
                            position = .camera(
                                MapCamera(centerCoordinate: coordinate,
                                         distance: 500000,
                                         heading: 0,
                                         pitch: 0)
                            )
                        }
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .task {
                await loadRadarTimestamp()
            }
            .onChange(of: selectedLayer) { _, newLayer in
                if newLayer == .precipitation && radarTimestamp.isEmpty {
                    Task {
                        await loadRadarTimestamp()
                    }
                }
            }
        }
    }
    
    private func loadRadarTimestamp() async {
        isLoadingRadar = true
        defer { isLoadingRadar = false }
        
        // Fetch the latest radar timestamp from RainViewer API
        guard let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)
            
            if let latestRadar = response.radar.past.last {
                await MainActor.run {
                    radarTimestamp = String(latestRadar.time)
                }
            }
        } catch {
            print("Failed to load radar timestamp: \(error)")
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

// MARK: - Radar Tile Overlay View

struct RadarOverlayView: View {
    let timestamp: String
    let position: MapCameraPosition
    
    var body: some View {
        GeometryReader { geometry in
            // Create a grid of radar tiles based on current map view
            if let camera = position.camera {
                RadarTileGrid(
                    centerCoordinate: camera.centerCoordinate,
                    distance: camera.distance,
                    timestamp: timestamp,
                    size: geometry.size
                )
            }
        }
    }
}

struct RadarTileGrid: View {
    let centerCoordinate: CLLocationCoordinate2D
    let distance: Double
    let timestamp: String
    let size: CGSize
    
    // Calculate zoom level from distance
    private var zoomLevel: Int {
        // Approximate zoom level calculation based on camera distance
        let zoom = max(1, min(10, Int(log2(40000000 / distance))))
        return zoom
    }
    
    // Calculate tile coordinates
    private var tileX: Int {
        let n = pow(2.0, Double(zoomLevel))
        return Int((centerCoordinate.longitude + 180.0) / 360.0 * n)
    }
    
    private var tileY: Int {
        let n = pow(2.0, Double(zoomLevel))
        let latRad = centerCoordinate.latitude * .pi / 180.0
        return Int((1.0 - asinh(tan(latRad)) / .pi) / 2.0 * n)
    }
    
    var body: some View {
        // Load radar tiles in a 3x3 grid around center
        ZStack {
            ForEach(-1...1, id: \.self) { dy in
                ForEach(-1...1, id: \.self) { dx in
                    AsyncImage(url: radarTileURL(x: tileX + dx, y: tileY + dy)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(0.6)
                        case .failure:
                            Color.clear
                        case .empty:
                            Color.clear
                        @unknown default:
                            Color.clear
                        }
                    }
                    .frame(width: size.width / 3, height: size.height / 3)
                    .offset(
                        x: CGFloat(dx) * size.width / 3,
                        y: CGFloat(dy) * size.height / 3
                    )
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    private func radarTileURL(x: Int, y: Int) -> URL? {
        // RainViewer tile URL format
        // https://tilecache.rainviewer.com/v2/radar/{timestamp}/256/{z}/{x}/{y}/2/1_1.png
        let urlString = "https://tilecache.rainviewer.com/v2/radar/\(timestamp)/256/\(zoomLevel)/\(x)/\(y)/2/1_1.png"
        return URL(string: urlString)
    }
}

// MARK: - Map Layers

enum MapLayer: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"
    case temperature = "Temperature"
    case precipitation = "Precipitation"
    case wind = "Wind"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.americas"
        case .hybrid: return "map.fill"
        case .temperature: return "thermometer.medium"
        case .precipitation: return "cloud.rain"
        case .wind: return "wind"
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
        case .temperature, .precipitation, .wind:
            // For weather layers, use standard map with overlay indication
            return .standard(emphasis: .muted)
        }
    }
    
    var isWeatherLayer: Bool {
        switch self {
        case .temperature, .precipitation, .wind:
            return true
        default:
            return false
        }
    }
}

// MARK: - Weather Annotation View

struct WeatherAnnotationView: View {
    let weatherData: WeatherData?
    
    var body: some View {
        VStack(spacing: 4) {
            // Weather icon
            ZStack {
                Circle()
                    .fill(temperatureGradient)
                    .frame(width: 50, height: 50)
                
                Image(systemName: weatherIcon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .shadow(color: .black.opacity(0.3), radius: 4)
            
            // Temperature badge
            if let temp = weatherData?.current.temperature2m {
                Text("\(Int(temp))°")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
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
                    ForEach([MapLayer.temperature, .precipitation, .wind]) { layer in
                        layerRow(layer)
                    }
                } header: {
                    Text("Weather Layers")
                } footer: {
                    Text("Weather layers show simulated data for demonstration purposes.")
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
        if layer.isWeatherLayer {
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
        switch layer {
        case .temperature:
            return [
                (.blue, "<32°"),
                (.cyan, "32-50°"),
                (.green, "50-68°"),
                (.yellow, "68-85°"),
                (.orange, "85-95°"),
                (.red, ">95°")
            ]
        case .precipitation:
            return [
                (.green.opacity(0.3), "Light"),
                (.green, "Mod"),
                (.yellow, "Heavy"),
                (.orange, "Intense"),
                (.red, "Extreme")
            ]
        case .wind:
            return [
                (.green, "Calm"),
                (.yellow, "Breeze"),
                (.orange, "Windy"),
                (.red, "Strong"),
                (.purple, "Severe")
            ]
        default:
            return []
        }
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
