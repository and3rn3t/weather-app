//
//  PerformanceTracker.swift
//  weather
//
//  Enhanced performance tracking for custom metrics and real-time monitoring
//  Complements MetricKit with app-specific performance measurements
//

import Foundation
import SwiftUI
import OSLog

/// Real-time performance tracking for custom app metrics
/// 
/// Provides immediate feedback and logging for:
/// - View rendering performance
/// - API call timing
/// - User interaction response times
/// - Memory pressure events
/// - Custom business metrics
@MainActor
@Observable
final class PerformanceTracker {
    
    // MARK: - Singleton
    
    static let shared = PerformanceTracker()
    
    // MARK: - Configuration
    
    private let logger = Logger(subsystem: "dev.andernet.weather", category: "Performance")
    
    /// Maximum number of concurrent traces to prevent memory issues
    private let maxConcurrentTraces = 100
    
    /// Thresholds for performance alerts
    private let slowOperationThreshold: TimeInterval = 1.0 // 1 second
    private let verySlowOperationThreshold: TimeInterval = 3.0 // 3 seconds
    
    // MARK: - Active Traces
    
    private var activeTraces: [String: TraceInfo] = [:]
    
    // MARK: - Performance Metrics
    
    private var performanceMetrics: [String: [TimeInterval]] = [:]
    private let maxMetricsPerCategory = 100 // Prevent unlimited memory growth
    
    // MARK: - Memory Monitoring
    
    private var memoryPressureTimer: Timer?
    private var isMonitoringMemory = false
    
    // MARK: - Initialization
    
    private init() {
        startMemoryMonitoring()
        logger.info("PerformanceTracker initialized")
    }
    
    deinit {
        // Timer will be cleaned up automatically when object is deallocated
        logger.debug("PerformanceTracker deallocated")
    }
    
    // MARK: - Trace Management
    
    /// Start timing an operation
    /// - Parameters:
    ///   - name: Unique identifier for this operation
    ///   - attributes: Optional metadata for the operation
    func startTrace(_ name: String, attributes: [String: String] = [:]) {
        // Clean up old traces if we're at the limit
        if activeTraces.count >= maxConcurrentTraces {
            logger.warning("Too many active traces, cleaning up oldest")
            cleanupOldestTraces()
        }
        
        let trace = TraceInfo(
            name: name,
            startTime: CFAbsoluteTimeGetCurrent(),
            attributes: attributes
        )
        
        activeTraces[name] = trace
        logger.debug("Started trace: \(name)")
    }
    
    /// Stop timing an operation and record the result
    /// - Parameter name: The trace identifier
    /// - Returns: Duration in seconds, or nil if trace wasn't found
    @discardableResult
    func stopTrace(_ name: String) -> TimeInterval? {
        guard let trace = activeTraces.removeValue(forKey: name) else {
            logger.warning("No active trace found for: \(name)")
            return nil
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - trace.startTime
        recordMetric(name, duration: duration)
        
        // Log performance issues
        if duration > verySlowOperationThreshold {
            logger.error("⚠️ Very slow operation: \(name) took \(String(format: "%.3f", duration))s")
            recordEvent("very_slow_operation", parameters: [
                "operation": name,
                "duration": String(format: "%.3f", duration),
                "threshold": String(verySlowOperationThreshold)
            ])
        } else if duration > slowOperationThreshold {
            logger.notice("🐌 Slow operation: \(name) took \(String(format: "%.3f", duration))s")
            recordEvent("slow_operation", parameters: [
                "operation": name,
                "duration": String(format: "%.3f", duration)
            ])
        }
        
        logger.debug("Stopped trace: \(name) (\(String(format: "%.3f", duration))s)")
        return duration
    }
    
    /// Add metadata to an active trace
    func setTraceAttribute(_ name: String, key: String, value: String) {
        activeTraces[name]?.attributes[key] = value
    }
    
    // MARK: - Metric Recording
    
    /// Record a performance metric
    private func recordMetric(_ name: String, duration: TimeInterval) {
        var metrics = performanceMetrics[name] ?? []
        
        // Keep only recent metrics to prevent memory leaks
        if metrics.count >= maxMetricsPerCategory {
            metrics.removeFirst()
        }
        
        metrics.append(duration)
        performanceMetrics[name] = metrics
        
        logger.debug("Recorded metric: \(name) = \(String(format: "%.3f", duration))s")
    }
    
    /// Record a custom event
    func recordEvent(_ name: String, parameters: [String: String] = [:]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let parametersString = parameters.isEmpty ? "" : " | \(parameters)"
        
        logger.info("📊 Event: \(name)\(parametersString) | Time: \(timestamp)")
        
        // TODO: Send to analytics platform if configured
    }
    
    // MARK: - Metric Analysis
    
    /// Get performance statistics for a specific metric
    func getPerformanceStats(for metricName: String) -> PerformanceStats? {
        guard let metrics = performanceMetrics[metricName], !metrics.isEmpty else {
            return nil
        }
        
        let sortedMetrics = metrics.sorted()
        let sum = metrics.reduce(0, +)
        let average = sum / Double(metrics.count)
        
        return PerformanceStats(
            metricName: metricName,
            sampleCount: metrics.count,
            average: average,
            min: sortedMetrics.first ?? 0,
            max: sortedMetrics.last ?? 0,
            median: sortedMetrics[sortedMetrics.count / 2],
            p95: sortedMetrics[min(Int(Double(sortedMetrics.count) * 0.95), sortedMetrics.count - 1)]
        )
    }
    
    /// Get all available performance metrics
    func getAllMetrics() -> [String: PerformanceStats] {
        var results: [String: PerformanceStats] = [:]
        
        for metricName in performanceMetrics.keys {
            if let stats = getPerformanceStats(for: metricName) {
                results[metricName] = stats
            }
        }
        
        return results
    }
    
    // MARK: - Memory Monitoring
    
    private func startMemoryMonitoring() {
        guard !isMonitoringMemory else { return }
        
        isMonitoringMemory = true
        memoryPressureTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkMemoryPressure()
        }
        
        logger.debug("Memory monitoring started")
    }
    
    private func stopMemoryMonitoring() {
        memoryPressureTimer?.invalidate()
        memoryPressureTimer = nil
        isMonitoringMemory = false
        
        logger.debug("Memory monitoring stopped")
    }
    
    private func checkMemoryPressure() {
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryUsageMB = Double(memoryInfo.resident_size) / 1024.0 / 1024.0
            
            // Log high memory usage
            if memoryUsageMB > 200 {
                logger.warning("High memory usage: \(String(format: "%.1f", memoryUsageMB))MB")
                recordEvent("high_memory_usage", parameters: [
                    "usage_mb": String(format: "%.1f", memoryUsageMB)
                ])
            }
            
            logger.debug("Memory usage: \(String(format: "%.1f", memoryUsageMB))MB")
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanupOldestTraces() {
        // Remove traces older than 5 minutes
        let cutoffTime = CFAbsoluteTimeGetCurrent() - 300 // 5 minutes
        let keysToRemove = activeTraces.compactMap { key, trace in
            trace.startTime < cutoffTime ? key : nil
        }
        
        for key in keysToRemove {
            activeTraces.removeValue(forKey: key)
            logger.warning("Cleaned up stale trace: \(key)")
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Measure the performance of a closure
    func measure<T>(_ name: String, attributes: [String: String] = [:], operation: () throws -> T) rethrows -> T {
        startTrace(name, attributes: attributes)
        defer { stopTrace(name) }
        return try operation()
    }
    
    /// Measure the performance of an async closure
    func measure<T>(_ name: String, attributes: [String: String] = [:], operation: () async throws -> T) async rethrows -> T {
        startTrace(name, attributes: attributes)
        defer { stopTrace(name) }
        return try await operation()
    }
    
    // MARK: - Debug Information
    
    /// Generate a performance report for debugging
    func generatePerformanceReport() -> String {
        var report = ["=== Performance Report ==="]
        report.append("Active Traces: \(activeTraces.count)")
        
        if !activeTraces.isEmpty {
            report.append("\nActive Operations:")
            for (name, trace) in activeTraces {
                let duration = CFAbsoluteTimeGetCurrent() - trace.startTime
                report.append("  \(name): \(String(format: "%.2f", duration))s")
            }
        }
        
        report.append("\nPerformance Metrics:")
        let allMetrics = getAllMetrics()
        for (name, stats) in allMetrics.sorted(by: { $0.key < $1.key }) {
            report.append("  \(name):")
            report.append("    Samples: \(stats.sampleCount)")
            report.append("    Average: \(String(format: "%.3f", stats.average))s")
            report.append("    Min/Max: \(String(format: "%.3f", stats.min))s / \(String(format: "%.3f", stats.max))s")
            report.append("    95th percentile: \(String(format: "%.3f", stats.p95))s")
        }
        
        report.append("=== End Report ===")
        return report.joined(separator: "\n")
    }
}

// MARK: - Supporting Types

private struct TraceInfo {
    let name: String
    let startTime: CFAbsoluteTime
    var attributes: [String: String]
}

/// Performance statistics for a specific metric
struct PerformanceStats {
    let metricName: String
    let sampleCount: Int
    let average: TimeInterval
    let min: TimeInterval
    let max: TimeInterval
    let median: TimeInterval
    let p95: TimeInterval // 95th percentile
}

// MARK: - SwiftUI Integration

/// View modifier for measuring view performance
struct PerformanceTrackerModifier: ViewModifier {
    let traceName: String
    let attributes: [String: String]
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                PerformanceTracker.shared.startTrace(traceName, attributes: attributes)
            }
            .onDisappear {
                PerformanceTracker.shared.stopTrace(traceName)
            }
    }
}

extension View {
    /// Track the performance of this view's lifecycle
    func trackPerformance(_ name: String, attributes: [String: String] = [:]) -> some View {
        modifier(PerformanceTrackerModifier(traceName: name, attributes: attributes))
    }
}