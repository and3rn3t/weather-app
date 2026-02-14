//
//  TelemetryManager.swift
//  weather
//
//  MetricKit integration for crash diagnostics and performance monitoring
//  Privacy-first: No PII, respects Apple's analytics settings
//

import MetricKit
import OSLog

/// Manages telemetry collection using Apple's MetricKit framework
///
/// Automatically collects:
/// - Crash reports and hangs
/// - CPU/memory/disk metrics
/// - Network performance
/// - Launch time and app exits
///
/// Data is delivered daily by the system and can be uploaded to a backend
@MainActor
final class TelemetryManager: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = TelemetryManager()
    
    private let logger = Logger(subsystem: "dev.andernet.weather", category: "Telemetry")
    
    // MARK: - Configuration
    
    /// Whether to save diagnostic reports locally for debugging
    private let saveLocally = true
    
    /// Directory for saving diagnostic reports (DEBUG only)
    private var diagnosticsDirectory: URL? {
        #if DEBUG
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let diagnosticsPath = documentsPath.appendingPathComponent("Diagnostics", isDirectory: true)
        try? FileManager.default.createDirectory(at: diagnosticsPath, withIntermediateDirectories: true)
        return diagnosticsPath
        #else
        return nil
        #endif
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupMetricKit()
    }
    
    private func setupMetricKit() {
        MXMetricManager.shared.add(self)
        logger.info("MetricKit telemetry enabled")
    }
    
    deinit {
        MXMetricManager.shared.remove(self)
    }
    
    // MARK: - MXMetricManagerSubscriber
    
    /// Called daily with diagnostic payloads (crashes, hangs, disk writes)
    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        let count = payloads.count
        
        // Extract JSON data in nonisolated context to avoid sendability issues
        let jsonDataArray = payloads.map { $0.jsonRepresentation() }
        
        Task { @MainActor in
            logger.notice("Received \(count) diagnostic payload(s)")
            
            for jsonData in jsonDataArray {
                await processDiagnosticData(jsonData)
            }
        }
    }
    
    /// Called daily with metric payloads (performance, battery, network)
    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        let count = payloads.count
        
        // Extract JSON data in nonisolated context to avoid sendability issues
        let jsonDataArray = payloads.map { $0.jsonRepresentation() }
        
        Task { @MainActor in
            logger.notice("Received \(count) metric payload(s)")
            
            for jsonData in jsonDataArray {
                await processMetricData(jsonData)
            }
        }
    }
    
    // MARK: - Diagnostic Processing
    
    private func processDiagnosticData(_ jsonData: Data) async {
        logger.info("Processing diagnostic data: \(jsonData.count) bytes")
        
        // Save locally in debug builds
        #if DEBUG
        if saveLocally, let directory = diagnosticsDirectory {
            saveDiagnosticsLocally(jsonData, directory: directory, type: "diagnostic")
        }
        #endif
        
        // Upload to backend (implement when you have a logging endpoint)
        await uploadDiagnostics(jsonData)
    }
    
    // MARK: - Metric Processing
    
    private func processMetricData(_ jsonData: Data) async {
        logger.info("Processing metric data: \(jsonData.count) bytes")
        
        // Save locally in debug builds
        #if DEBUG
        if saveLocally, let directory = diagnosticsDirectory {
            saveDiagnosticsLocally(jsonData, directory: directory, type: "metrics")
        }
        #endif
        
        // Upload to backend (implement when you have a logging endpoint)
        await uploadMetrics(jsonData)
    }
    
    // MARK: - Local Storage (DEBUG)
    
    #if DEBUG
    private func saveDiagnosticsLocally(_ data: Data, directory: URL, type: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "\(type)-\(timestamp).json"
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            logger.debug("Saved \(type) to \(fileURL.lastPathComponent)")
        } catch {
            logger.error("Failed to save \(type): \(error.localizedDescription)")
        }
    }
    #endif
    
    // MARK: - Upload (Placeholder)
    
    /// Upload diagnostic data to your backend
    ///
    /// Implement this when you have a logging endpoint.
    /// MetricKit data contains NO PII and is safe to upload.
    private func uploadDiagnostics(_ data: Data) async {
        // TODO: Implement upload to your backend
        // Example:
        // guard let url = URL(string: "https://your-api.com/diagnostics") else { return }
        // var request = URLRequest(url: url)
        // request.httpMethod = "POST"
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // request.httpBody = data
        // _ = try? await URLSession.shared.data(for: request)
        
        logger.debug("Diagnostic upload not configured (data size: \(data.count) bytes)")
    }
    
    /// Upload metric data to your backend
    private func uploadMetrics(_ data: Data) async {
        // TODO: Implement upload to your backend
        logger.debug("Metrics upload not configured (data size: \(data.count) bytes)")
    }
}
