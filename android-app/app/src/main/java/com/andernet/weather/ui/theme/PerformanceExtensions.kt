//
//  PerformanceExtensions.kt
//  weather
//
//  Compose extensions for performance tracking
//

package com.andernet.weather.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import com.andernet.weather.utils.PerformanceMonitor
import dagger.hilt.android.EntryPointAccessors

/**
 * Composable helper for tracking screen performance
 * Usage: TrackScreenPerformance("home_screen") { /* screen content */ }
 */
@Composable
fun TrackScreenPerformance(
    screenName: String,
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    val performanceMonitor = remember {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            PerformanceEntryPoint::class.java
        )
        entryPoint.performanceMonitor()
    }
    
    LaunchedEffect(screenName) {
        performanceMonitor.startTrace("screen_$screenName")
    }
    
    // Content renders first
    content()
    
    // Track completion after content renders
    LaunchedEffect(Unit) {
        performanceMonitor.stopTrace("screen_$screenName")
    }
}

/**
 * Entry Point for accessing PerformanceMonitor in Composables
 */
@dagger.hilt.EntryPoint
@dagger.hilt.InstallIn(dagger.hilt.components.SingletonComponent::class)
interface PerformanceEntryPoint {
    fun performanceMonitor(): PerformanceMonitor
}

/**
 * Composable utility for measuring operation performance
 */
@Composable
fun <T> rememberPerformanceTracking(
    operationName: String,
    operation: () -> T
): T {
    val context = LocalContext.current
    val performanceMonitor = remember {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            PerformanceEntryPoint::class.java
        )
        entryPoint.performanceMonitor()
    }
    
    return remember(operationName) {
        performanceMonitor.measurePerformance(operationName) {
            operation()
        }
    }
}