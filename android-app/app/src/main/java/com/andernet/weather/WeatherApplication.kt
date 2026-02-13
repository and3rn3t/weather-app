package com.andernet.weather

import android.app.Application
import com.andernet.weather.notification.NotificationChannels
import com.andernet.weather.workers.DailyForecastWorker
import com.andernet.weather.workers.RainAlertWorker
import com.andernet.weather.workers.WidgetUpdateWorker
import dagger.hilt.android.HiltAndroidApp

/**
 * Application class for Weather app
 * Annotated with @HiltAndroidApp to trigger Hilt code generation
 */
@HiltAndroidApp
class WeatherApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize notification channels
        NotificationChannels.createChannels(this)
        
        // Schedule background workers
        WidgetUpdateWorker.schedule(this)
        DailyForecastWorker.schedule(this)
        RainAlertWorker.schedule(this)
    }
}
