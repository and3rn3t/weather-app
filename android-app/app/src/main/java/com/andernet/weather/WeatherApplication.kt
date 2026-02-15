package com.andernet.weather

import android.app.Application
import androidx.lifecycle.ProcessLifecycleOwner
import com.andernet.weather.notification.NotificationChannels
import com.andernet.weather.utils.PerformanceMonitor
import com.andernet.weather.workers.DailyForecastWorker
import com.andernet.weather.workers.RainAlertWorker
import com.andernet.weather.workers.WidgetUpdateWorker
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

/**
 * Application class for Weather app
 * Annotated with @HiltAndroidApp to trigger Hilt code generation
 */
@HiltAndroidApp
class WeatherApplication : Application() {
    
    @Inject
    lateinit var performanceMonitor: PerformanceMonitor
    
    private var appStartTime = System.currentTimeMillis()
    
    override fun onCreate() {
        // Start app cold start tracking
        performanceMonitor.startTrace("app_cold_start")
        
        super.onCreate()
        
        // Initialize notification channels
        NotificationChannels.createChannels(this)
        
        // Schedule background workers
        WidgetUpdateWorker.schedule(this)
        DailyForecastWorker.schedule(this)
        RainAlertWorker.schedule(this)
        
        // Track app initialization completion
        performanceMonitor.markAppInitialized()
        
        // Add lifecycle observer for background/foreground tracking
        ProcessLifecycleOwner.get().lifecycle.addObserver(performanceMonitor)
        
        // Record app startup event
        val versionName = try {
            packageManager.getPackageInfo(packageName, 0).versionName ?: "unknown"
        } catch (e: Exception) {
            "unknown"
        }
        
        performanceMonitor.recordEvent("app_startup", mapOf(
            "app_version" to versionName,
            "startup_duration_ms" to (System.currentTimeMillis() - appStartTime).toString()
        ))
    }
}
