//
//  WeatherMapView.swift
//  weather
//
//  Created by Matt on 2/5/26.
//

import SwiftUI
import MapKit
import OSLog

// MARK: - Weather Map View

struct WeatherMapView: View {
    let weatherData: WeatherData?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasSeenMapHints") private var hasSeenMapHints = false
    
    @State private var selectedLayer: MapLayer = .standard
    @State private var showingLayerPicker = false
    @State private var radarFrames: [RainViewerResponse.RadarFrame] = []
    @State private var nowcastFrames: [RainViewerResponse.RadarFrame] = []
    @State private var currentFrameIndex: Int = 0
    @State private var isLoadingRadar = false
    @State private var hasLoadedRadar = false
    @State private var radarOpacity: Double = 0.7
    @State private var isPlaying = false
    @State private var showForecast = false
    @State private var showingHints = false
    @State private var mapViewRef: MKMapView?
    
    // Task for animation
    @State private var animationTask: Task<Void, Never>?
    
    init(weatherData: WeatherData?, locationName: String, latitude: Double, longitude: Double) {
        self.weatherData = weatherData
        self.locationName = locationName
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private var currentRadarPath: String {
        let frames = showForecast ? nowcastFrames : radarFrames
        guard !frames.isEmpty, currentFrameIndex < frames.count else { return "" }
        return frames[currentFrameIndex].path
    }
    
    private var totalFrames: Int {
        showForecast ? nowcastFrames.count : radarFrames.count
    }
    
    private static let mapTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private var currentFrameTime: String {
        let frames = showForecast ? nowcastFrames : radarFrames
        guard !frames.isEmpty, currentFrameIndex < frames.count else { return "" }
        let timestamp = frames[currentFrameIndex].time
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return Self.mapTimeFormatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map with radar overlay using UIKit wrapper
                RadarMapView(
                    coordinate: coordinate,
                    locationName: locationName,
                    weatherData: weatherData,
                    radarPath: currentRadarPath,
                    showRadar: selectedLayer == .precipitation,
                    radarOpacity: radarOpacity,
                    mapType: effectiveMapType,
                    onMapViewCreated: { mapView in
                        mapViewRef = mapView
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                
                // Controls overlay
                VStack(spacing: 0) {
                    // Top controls - Map type quick toggle
                    HStack {
                        MapTypeSegmentedControl(selectedLayer: $selectedLayer)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Right side controls
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Zoom controls
                            VStack(spacing: 0) {
                                Button {
                                    zoomIn()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title3.weight(.medium))
                                        .frame(width: 44, height: 44)
                                }
                                
                                Divider()
                                    .frame(width: 30)
                                
                                Button {
                                    zoomOut()
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.title3.weight(.medium))
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .foregroundStyle(.primary)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            
                            // Center on location
                            Button {
                                centerOnLocation()
                            } label: {
                                Image(systemName: "location.fill")
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                            }
                            .foregroundStyle(.blue)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            
                            // Reset rotation (compass)
                            Button {
                                resetRotation()
                            } label: {
                                Image(systemName: "compass.drawing")
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                            }
                            .foregroundStyle(.primary)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            
                            // Layer picker button
                            Button {
                                showingLayerPicker.toggle()
                            } label: {
                                Image(systemName: "square.3.layers.3d")
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                            }
                            .foregroundStyle(.primary)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.trailing, 12)
                    }
                    
                    // Bottom controls for radar
                    if selectedLayer == .precipitation && hasLoadedRadar {
                        VStack(spacing: 12) {
                            // Radar timeline controls
                            RadarTimelineControls(
                                currentFrameIndex: $currentFrameIndex,
                                isPlaying: $isPlaying,
                                showForecast: $showForecast,
                                totalFrames: totalFrames,
                                currentTime: currentFrameTime,
                                onPlayPause: togglePlayback
                            )
                            
                            // Opacity slider
                            RadarOpacitySlider(opacity: $radarOpacity)
                            
                            // Weather legend
                            WeatherMapLegend(layer: selectedLayer)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    } else {
                        // Weather legend only
                        WeatherMapLegend(layer: selectedLayer)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
                
                // Loading indicator for radar
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
                
                // First-use hints overlay
                if showingHints {
                    MapHintsOverlay(isPresented: $showingHints)
                }
            }
            .navigationTitle("Weather Map")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingLayerPicker) {
                MapLayerPicker(selectedLayer: $selectedLayer, radarOpacity: $radarOpacity)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Help button
                        Button {
                            showingHints = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        
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
            }
            .task {
                await loadRadarData()
                
                // Show hints on first use
                if !hasSeenMapHints {
                    try? await Task.sleep(for: .seconds(0.5))
                    showingHints = true
                    hasSeenMapHints = true
                }
            }
            .onChange(of: selectedLayer) { _, newLayer in
                if newLayer == .precipitation && radarFrames.isEmpty {
                    Task {
                        await loadRadarData()
                    }
                }
                // Stop playback when switching away from precipitation
                if newLayer != .precipitation {
                    stopPlayback()
                }
            }
            .onChange(of: showForecast) { _, _ in
                // Reset to first frame when switching between past/forecast
                currentFrameIndex = 0
            }
            .onDisappear {
                stopPlayback()
            }
        }
    }
    
    // MARK: - Map Type Based on Color Scheme
    
    private var effectiveMapType: MKMapType {
        if selectedLayer == .precipitation {
            return colorScheme == .dark ? .mutedStandard : .standard
        }
        return selectedLayer.mkMapType
    }
    
    // MARK: - Zoom Controls
    
    private func zoomIn() {
        guard let mapView = mapViewRef else { return }
        var region = mapView.region
        region.span.latitudeDelta /= 2
        region.span.longitudeDelta /= 2
        mapView.setRegion(region, animated: true)
    }
    
    private func zoomOut() {
        guard let mapView = mapViewRef else { return }
        var region = mapView.region
        region.span.latitudeDelta = min(region.span.latitudeDelta * 2, 180)
        region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 360)
        mapView.setRegion(region, animated: true)
    }
    
    private func centerOnLocation() {
        guard let mapView = mapViewRef else { return }
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500000,
            longitudinalMeters: 500000
        )
        mapView.setRegion(region, animated: true)
    }
    
    private func resetRotation() {
        guard let mapView = mapViewRef else { return }
        let camera = MKMapCamera(
            lookingAtCenter: mapView.centerCoordinate,
            fromDistance: mapView.camera.centerCoordinateDistance,
            pitch: 0,
            heading: 0
        )
        mapView.setCamera(camera, animated: true)
    }
    
    // MARK: - Radar Animation
    
    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        isPlaying = true
        animationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentFrameIndex = (currentFrameIndex + 1) % max(1, totalFrames)
                    }
                }
            }
        }
    }
    
    private func stopPlayback() {
        isPlaying = false
        animationTask?.cancel()
        animationTask = nil
    }
    
    // MARK: - Data Loading
    
    private func loadRadarData() async {
        guard !hasLoadedRadar else { return }
        
        isLoadingRadar = true
        
        guard let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json") else {
            isLoadingRadar = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)
            
            await MainActor.run {
                radarFrames = response.radar.past
                nowcastFrames = response.radar.nowcast
                currentFrameIndex = max(0, radarFrames.count - 1)
                hasLoadedRadar = true
                isLoadingRadar = false
            }
        } catch {
            Logger.weatherMap.error("Failed to load radar data: \(error.localizedDescription)")
            await MainActor.run {
                isLoadingRadar = false
            }
        }
    }
}

// MARK: - Radar Timeline Controls

struct RadarTimelineControls: View {
    @Binding var currentFrameIndex: Int
    @Binding var isPlaying: Bool
    @Binding var showForecast: Bool
    let totalFrames: Int
    let currentTime: String
    let onPlayPause: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Past/Forecast toggle
            Picker("Mode", selection: $showForecast) {
                Text("Past").tag(false)
                Text("Forecast").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            
            HStack(spacing: 16) {
                // Play/Pause button
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(.blue)
                
                // Timeline slider
                VStack(spacing: 4) {
                    Slider(value: Binding(
                        get: { Double(currentFrameIndex) },
                        set: { currentFrameIndex = Int($0) }
                    ), in: 0...Double(max(0, totalFrames - 1)), step: 1)
                    .tint(.blue)
                    
                    Text(currentTime)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Radar Opacity Slider

struct RadarOpacitySlider: View {
    @Binding var opacity: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.lefthalf.filled")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Slider(value: $opacity, in: 0.2...1.0)
                .tint(.blue)
                .frame(width: 150)
            
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(Int(opacity * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 40)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Map Type Segmented Control

struct MapTypeSegmentedControl: View {
    @Binding var selectedLayer: MapLayer
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([MapLayer.standard, .satellite, .precipitation]) { layer in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedLayer = layer
                    }
                } label: {
                    Image(systemName: layer.icon)
                        .font(.subheadline)
                        .frame(width: 44, height: 32)
                        .foregroundStyle(selectedLayer == layer ? .white : .primary)
                        .background(selectedLayer == layer ? Color.blue : Color.clear)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Map Hints Overlay

struct MapHintsOverlay: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 24) {
                Text("Map Controls")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 16) {
                    HintRow(icon: "hand.pinch", text: "Pinch to zoom in/out")
                    HintRow(icon: "hand.draw", text: "Drag to pan the map")
                    HintRow(icon: "rotate.right", text: "Two-finger rotate")
                    HintRow(icon: "square.3.layers.3d", text: "Tap layers for radar view")
                    HintRow(icon: "play.fill", text: "Animate radar over time")
                }
                
                Button {
                    withAnimation {
                        isPresented = false
                    }
                } label: {
                    Text("Got it!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 44)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(40)
        }
    }
}

struct HintRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            Text(text)
                .foregroundStyle(.white)
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
    let radarOpacity: Double
    let mapType: MKMapType
    let onMapViewCreated: (MKMapView) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500000,
            longitudinalMeters: 500000
        )
        mapView.setRegion(region, animated: false)
        
        let annotation = WeatherAnnotation(
            coordinate: coordinate,
            title: locationName,
            weatherData: weatherData
        )
        mapView.addAnnotation(annotation)
        
        DispatchQueue.main.async {
            onMapViewCreated(mapView)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        
        context.coordinator.updateRadarOverlay(
            mapView: mapView,
            radarPath: radarPath,
            showRadar: showRadar,
            opacity: radarOpacity
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(weatherData: weatherData)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let weatherData: WeatherData?
        private var currentOverlay: MKTileOverlay?
        private var currentOpacity: Double = 0.7
        
        init(weatherData: WeatherData?) {
            self.weatherData = weatherData
        }
        
        func updateRadarOverlay(mapView: MKMapView, radarPath: String, showRadar: Bool, opacity: Double) {
            currentOpacity = opacity
            
            let newTemplate = showRadar && !radarPath.isEmpty ?
                "https://tilecache.rainviewer.com\(radarPath)/256/{z}/{x}/{y}/2/1_1.png" : nil
            
            let currentTemplate = currentOverlay?.urlTemplate
            
            if newTemplate != currentTemplate {
                if let overlay = currentOverlay {
                    mapView.removeOverlay(overlay)
                    currentOverlay = nil
                }
                
                if let template = newTemplate {
                    let overlay = MKTileOverlay(urlTemplate: template)
                    overlay.canReplaceMapContent = false
                    mapView.addOverlay(overlay, level: .aboveLabels)
                    currentOverlay = overlay
                }
            }
            
            if let overlay = currentOverlay,
               let renderer = mapView.renderer(for: overlay) as? MKTileOverlayRenderer {
                renderer.alpha = opacity
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
                renderer.alpha = currentOpacity
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let weatherAnnotation = annotation as? WeatherAnnotation else { return nil }
            
            let identifier = "WeatherAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                let detailView = UIHostingController(
                    rootView: WeatherCalloutView(weatherData: weatherAnnotation.weatherData)
                )
                detailView.view.frame = CGRect(x: 0, y: 0, width: 200, height: 120)
                detailView.view.backgroundColor = .clear
                annotationView?.detailCalloutAccessoryView = detailView.view
            } else {
                annotationView?.annotation = annotation
            }
            
            if let temp = weatherAnnotation.weatherData?.current.temperature2m {
                annotationView?.glyphText = "\(Int(temp))°"
                annotationView?.markerTintColor = temperatureUIColor(for: temp)
            } else {
                annotationView?.glyphImage = UIImage(systemName: "cloud")
                annotationView?.markerTintColor = .systemBlue
            }
            
            return annotationView
        }
        
        private func temperatureUIColor(for temp: Double) -> UIColor {
            switch temp {
            case ..<32: return .systemBlue
            case 32..<50: return .systemCyan
            case 50..<68: return .systemGreen
            case 68..<85: return .systemOrange
            default: return .systemRed
            }
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

// MARK: - Weather Callout View

struct WeatherCalloutView: View {
    let weatherData: WeatherData?
    
    var body: some View {
        if let data = weatherData {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: WeatherCondition(code: data.current.weatherCode).symbolName)
                        .font(.title2)
                        .symbolRenderingMode(.multicolor)
                    
                    VStack(alignment: .leading) {
                        Text("\(Int(data.current.temperature2m))°")
                            .font(.title2.bold())
                        Text("Feels like \(Int(data.current.apparentTemperature))°")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                HStack(spacing: 16) {
                    Label("\(data.current.relativeHumidity2m)%", systemImage: "humidity")
                        .font(.caption)
                    
                    Label("\(Int(data.current.windSpeed10m)) mph", systemImage: "wind")
                        .font(.caption)
                }
                
                if let precip = data.hourly.precipitationProbability?.first {
                    Label("\(precip)% rain", systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding(8)
        } else {
            Text("No weather data")
                .font(.caption)
                .foregroundStyle(.secondary)
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
    
    var mkMapType: MKMapType {
        switch self {
        case .standard: return .standard
        case .satellite: return .satellite
        case .hybrid: return .hybrid
        case .precipitation: return .mutedStandard
        }
    }
    
    var isWeatherLayer: Bool {
        self == .precipitation
    }
}

// MARK: - Map Layer Picker

struct MapLayerPicker: View {
    @Binding var selectedLayer: MapLayer
    @Binding var radarOpacity: Double
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
                    
                    if selectedLayer == .precipitation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Radar Opacity")
                                .font(.subheadline)
                            
                            HStack {
                                Slider(value: $radarOpacity, in: 0.2...1.0)
                                Text("\(Int(radarOpacity * 100))%")
                                    .font(.caption.monospacedDigit())
                                    .frame(width: 40)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Weather Layers")
                } footer: {
                    Text("Precipitation layer shows live radar data from RainViewer with animation controls.")
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

#Preview {
    WeatherMapView(
        weatherData: nil,
        locationName: "San Francisco",
        latitude: 37.7749,
        longitude: -122.4194
    )
}
