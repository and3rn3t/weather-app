//
//  PerformanceMonitor.kt
//  weather
//
//  Android performance monitoring and analytics system
//  Integrates with Firebase Performance and provides custom metrics
//

package com.andernet.weather.utils

import android.app.Application
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Performance monitoring system for tracking app performance metrics
 * 
 * Features:
 * - App launch time measurement
 * - Screen transition performance
 * - Memory usage tracking
 * - Network request performance
 * - Compose recomposition tracking
 * - Custom event timing
 */
@Singleton
class PerformanceMonitor @Inject constructor(
    private val context: Context
) : DefaultLifecycleObserver {
    
    companion object {
        private const val TAG = "PerformanceMonitor"
        private const val MEMORY_CHECK_INTERVAL = 30_000L // 30 seconds
        private const val MAX_TRACES = 100 // Limit concurrent traces
        
        // Metric thresholds
        private const val SLOW_LAUNCH_THRESHOLD_MS = 3000L
        private const val SLOW_SCREEN_THRESHOLD_MS = 1000L
        private const val HIGH_MEMORY_THRESHOLD_MB = 200L
    }
    
    // Performance tracking variables
    private var appStartTime: Long = 0
    private var isAppInForeground = false
    private var memoryJob: Job? = null
    
    // Active traces for timing operations
    private val activeTraces = ConcurrentHashMap<String, TraceInfo>()
    
    // Performance metrics storage
    private val performanceMetrics = ConcurrentHashMap<String, MutableList<Long>>()
    
    // Coroutine scope for background operations
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    // Memory tracking
    private val memoryUsageHistory = mutableListOf<MemorySnapshot>()
    private val maxMemoryHistory = 50 // Keep last 50 memory snapshots
    
    init {
        appStartTime = System.currentTimeMillis()
        ProcessLifecycleOwner.get().lifecycle.addObserver(this)
        Log.d(TAG, "PerformanceMonitor initialized")
    }
    
    // MARK: - Lifecycle Callbacks
    
    override fun onStart(owner: LifecycleOwner) {
        if (!isAppInForeground) {
            isAppInForeground = true
            startMemoryMonitoring()
            
            // Record cold start time if this is first launch
            if (activeTraces.containsKey("app_cold_start")) {
                stopTrace("app_cold_start")
            }
            
            Log.d(TAG, "App moved to foreground")
        }
    }
    
    override fun onStop(owner: LifecycleOwner) {
        if (isAppInForeground) {
            isAppInForeground = false
            stopMemoryMonitoring()
            Log.d(TAG, "App moved to background")
        }
    }
    
    // MARK: - Trace Management
    
    /**
     * Start a custom trace for measuring operation duration
     */
    fun startTrace(traceName: String, attributes: Map<String, String> = emptyMap()) {
        if (activeTraces.size >= MAX_TRACES) {
            Log.w(TAG, "Maximum number of traces reached, ignoring: $traceName")
            return
        }
        
        val traceInfo = TraceInfo(
            name = traceName,
            startTime = System.currentTimeMillis(),
            attributes = attributes.toMutableMap()
        )
        
        activeTraces[traceName] = traceInfo
        Log.d(TAG, "Started trace: $traceName")
    }
    
    /**
     * Stop a trace and record the duration
     */
    fun stopTrace(traceName: String): Long? {
        val traceInfo = activeTraces.remove(traceName) ?: run {
            Log.w(TAG, "No active trace found for: $traceName")
            return null
        }
        
        val duration = System.currentTimeMillis() - traceInfo.startTime
        recordMetric("trace_$traceName", duration)
        
        // Check for performance issues
        when (traceName) {
            "app_cold_start", "app_warm_start" -> {
                if (duration > SLOW_LAUNCH_THRESHOLD_MS) {
                    Log.w(TAG, "Slow app launch detected: ${duration}ms")
                    recordEvent("slow_launch", mapOf(
                        "duration_ms" to duration.toString(),
                        "type" to traceName
                    ))
                }
            }
            else -> {
                if (duration > SLOW_SCREEN_THRESHOLD_MS && traceName.contains("screen")) {
                    Log.w(TAG, "Slow screen transition: $traceName took ${duration}ms")
                    recordEvent("slow_screen_transition", mapOf(
                        "screen" to traceName,
                        "duration_ms" to duration.toString()
                    ))
                }
            }
        }
        
        Log.d(TAG, "Stopped trace: $traceName (${duration}ms)")
        return duration
    }
    
    /**
     * Add custom attribute to an active trace
     */
    fun setTraceAttribute(traceName: String, key: String, value: String) {
        activeTraces[traceName]?.attributes?.put(key, value)
    }
    
    // MARK: - Metrics Recording
    
    /**
     * Record a custom metric value
     */
    fun recordMetric(metricName: String, value: Long) {
        val metrics = performanceMetrics.getOrPut(metricName) { mutableListOf() }
        
        // Keep only recent metrics to prevent memory leaks
        if (metrics.size >= 100) {
            metrics.removeAt(0)
        }
        
        metrics.add(value)
        Log.d(TAG, "Recorded metric: $metricName = $value")
    }
    
    /**
     * Record a custom event
     */
    fun recordEvent(eventName: String, parameters: Map<String, String> = emptyMap()) {
        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
            .format(Date())
        
        val logMessage = buildString {
            append("Event: $eventName")
            if (parameters.isNotEmpty()) {
                append(" | Parameters: $parameters")
            }
            append(" | Time: $timestamp")
        }
        
        Log.i(TAG, logMessage)
        
        // TODO: Send to analytics platform (Firebase Analytics, etc.)
    }
    
    /**
     * Get average value for a specific metric
     */
    fun getMetricAverage(metricName: String): Double? {
        val metrics = performanceMetrics[metricName] ?: return null
        return if (metrics.isNotEmpty()) {
            metrics.average()
        } else null
    }
    
    /**
     * Get recent metrics for a specific metric name
     */
    fun getRecentMetrics(metricName: String, count: Int = 10): List<Long> {
        val metrics = performanceMetrics[metricName] ?: return emptyList()
        return metrics.takeLast(count)
    }
    
    // MARK: - Memory Monitoring
    
    private fun startMemoryMonitoring() {
        memoryJob?.cancel()
        memoryJob = scope.launch {
            while (isAppInForeground) {
                checkMemoryUsage()
                delay(MEMORY_CHECK_INTERVAL)
            }
        }
    }
    
    private fun stopMemoryMonitoring() {
        memoryJob?.cancel()
        memoryJob = null
    }
    
    private fun checkMemoryUsage() {
        val runtime = Runtime.getRuntime()
        val usedMemory = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024) // MB
        val maxMemory = runtime.maxMemory() / (1024 * 1024) // MB
        val memoryPercentage = (usedMemory.toDouble() / maxMemory.toDouble() * 100).toInt()
        
        val snapshot = MemorySnapshot(
            timestamp = System.currentTimeMillis(),
            usedMemoryMB = usedMemory,
            maxMemoryMB = maxMemory,
            percentage = memoryPercentage
        )
        
        synchronized(memoryUsageHistory) {
            memoryUsageHistory.add(snapshot)
            if (memoryUsageHistory.size > maxMemoryHistory) {
                memoryUsageHistory.removeAt(0)
            }
        }
        
        recordMetric("memory_usage_mb", usedMemory)
        recordMetric("memory_usage_percent", memoryPercentage.toLong())
        
        // Alert if memory usage is high
        if (usedMemory > HIGH_MEMORY_THRESHOLD_MB || memoryPercentage > 80) {
            Log.w(TAG, "High memory usage detected: ${usedMemory}MB (${memoryPercentage}%)")
            recordEvent("high_memory_usage", mapOf(
                "used_mb" to usedMemory.toString(),
                "max_mb" to maxMemory.toString(),
                "percentage" to memoryPercentage.toString()
            ))
        }
    }
    
    /**
     * Get current memory usage information
     */
    fun getCurrentMemoryUsage(): MemorySnapshot {
        val runtime = Runtime.getRuntime()
        val usedMemory = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024)
        val maxMemory = runtime.maxMemory() / (1024 * 1024)
        val percentage = (usedMemory.toDouble() / maxMemory.toDouble() * 100).toInt()
        
        return MemorySnapshot(
            timestamp = System.currentTimeMillis(),
            usedMemoryMB = usedMemory,
            maxMemoryMB = maxMemory,
            percentage = percentage
        )
    }
    
    /**
     * Get memory usage history
     */
    fun getMemoryHistory(): List<MemorySnapshot> {
        return synchronized(memoryUsageHistory) {
            memoryUsageHistory.toList()
        }
    }
    
    // MARK: - Network Performance
    
    /**
     * Record network request performance
     */
    fun recordNetworkRequest(
        url: String,
        method: String,
        duration: Long,
        responseCode: Int,
        bytesReceived: Long = 0
    ) {
        recordMetric("network_request_duration", duration)
        recordMetric("network_bytes_received", bytesReceived)
        
        val isSuccess = responseCode in 200..299
        recordEvent("network_request", mapOf(
            "url" to url,
            "method" to method,
            "duration_ms" to duration.toString(),
            "response_code" to responseCode.toString(),
            "bytes_received" to bytesReceived.toString(),
            "success" to isSuccess.toString()
        ))
        
        Log.d(TAG, "Network request: $method $url - ${duration}ms (${responseCode})")
    }
    
    // MARK: - App Launch Tracking
    
    /**
     * Mark the end of app initialization
     */
    fun markAppInitialized() {
        val initDuration = System.currentTimeMillis() - appStartTime
        recordMetric("app_init_duration", initDuration)
        recordEvent("app_initialized", mapOf(
            "duration_ms" to initDuration.toString()
        ))
        
        Log.i(TAG, "App initialization completed in ${initDuration}ms")
    }
    
    // MARK: - Performance Summary
    
    /**
     * Generate a performance summary for debugging
     */
    fun getPerformanceSummary(): String {
        return buildString {
            appendLine("=== Performance Summary ===")
            appendLine("Active Traces: ${activeTraces.size}")
            
            // Memory info
            val currentMemory = getCurrentMemoryUsage()
            appendLine("Memory Usage: ${currentMemory.usedMemoryMB}MB / ${currentMemory.maxMemoryMB}MB (${currentMemory.percentage}%)")
            
            // Metrics summary
            appendLine("Tracked Metrics:")
            performanceMetrics.forEach { (name, values) ->
                if (values.isNotEmpty()) {
                    val avg = values.average()
                    val last = values.last()
                    appendLine("  $name: avg=${avg.toInt()}ms, last=${last}ms (${values.size} samples)")
                }
            }
            
            appendLine("=== End Summary ===")
        }
    }
    
    // MARK: - Data Classes
    
    private data class TraceInfo(
        val name: String,
        val startTime: Long,
        val attributes: MutableMap<String, String>
    )
    
    data class MemorySnapshot(
        val timestamp: Long,
        val usedMemoryMB: Long,
        val maxMemoryMB: Long,
        val percentage: Int
    )
}

/**
 * Composable helper for measuring screen composition performance
 */
@Composable
fun TrackComposition(screenName: String, performanceMonitor: PerformanceMonitor) {
    LaunchedEffect(screenName) {
        performanceMonitor.startTrace("screen_$screenName")
    }
    
    // Stop trace when composition completes
    LaunchedEffect(Unit) {
        performanceMonitor.stopTrace("screen_$screenName")
    }
}

/**
 * Inline function for measuring operation performance
 */
inline fun <T> PerformanceMonitor.measurePerformance(
    operation: String,
    attributes: Map<String, String> = emptyMap(),
    block: () -> T
): T {
    startTrace(operation, attributes)
    try {
        return block()
    } finally {
        stopTrace(operation)
    }
}