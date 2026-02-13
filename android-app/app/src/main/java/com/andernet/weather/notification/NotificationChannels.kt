package com.andernet.weather.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.andernet.weather.R

/**
 * Notification channel definitions
 */
object NotificationChannels {
    
    const val DAILY_FORECAST_CHANNEL_ID = "daily_forecast"
    const val WEATHER_ALERTS_CHANNEL_ID = "weather_alerts"
    const val RAIN_ALERTS_CHANNEL_ID = "rain_alerts"
    
    /**
     * Create all notification channels
     */
    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Daily Forecast Channel
            val dailyForecastChannel = NotificationChannel(
                DAILY_FORECAST_CHANNEL_ID,
                "Daily Forecast",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Daily weather forecast notifications"
                setShowBadge(true)
            }
            
            // Weather Alerts Channel
            val weatherAlertsChannel = NotificationChannel(
                WEATHER_ALERTS_CHANNEL_ID,
                "Weather Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Severe weather alerts and warnings"
                setShowBadge(true)
            }
            
            // Rain Alerts Channel
            val rainAlertsChannel = NotificationChannel(
                RAIN_ALERTS_CHANNEL_ID,
                "Rain Alerts",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications when rain is expected"
                setShowBadge(true)
            }
            
            notificationManager.createNotificationChannels(
                listOf(
                    dailyForecastChannel,
                    weatherAlertsChannel,
                    rainAlertsChannel
                )
            )
        }
    }
}
