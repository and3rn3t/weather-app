package com.andernet.weather.notification

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.andernet.weather.MainActivity
import com.andernet.weather.R
import com.andernet.weather.data.model.CurrentWeather
import com.andernet.weather.data.model.DailyForecastItem
import com.andernet.weather.data.model.WeatherCondition
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manager for creating and showing weather notifications
 */
@Singleton
class WeatherNotificationManager @Inject constructor(
    private val context: Context
) {
    
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    init {
        NotificationChannels.createChannels(context)
    }
    
    /**
     * Show daily forecast notification
     */
    fun showDailyForecast(
        locationName: String,
        todayForecast: DailyForecastItem,
        currentWeather: CurrentWeather?
    ) {
        val condition = WeatherCondition.fromCode(todayForecast.weatherCode)
        
        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(context, NotificationChannels.DAILY_FORECAST_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Today in $locationName")
            .setContentText("${condition.description} • High ${todayForecast.temperatureMax.toInt()}° Low ${todayForecast.temperatureMin.toInt()}°")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(buildDailyForecastText(todayForecast, currentWeather, condition))
            )
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        
        notificationManager.notify(DAILY_FORECAST_NOTIFICATION_ID, notification)
    }
    
    /**
     * Show rain alert notification
     */
    fun showRainAlert(
        locationName: String,
        minutesUntilRain: Int,
        durationMinutes: Int,
        probability: Int
    ) {
        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val timeText = when {
            minutesUntilRain < 15 -> "starting soon"
            minutesUntilRain < 60 -> "in ${minutesUntilRain} minutes"
            else -> "in ${minutesUntilRain / 60} hour(s)"
        }
        
        val notification = NotificationCompat.Builder(context, NotificationChannels.RAIN_ALERTS_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("☔ Rain Expected in $locationName")
            .setContentText("$probability% chance of rain $timeText, lasting ~$durationMinutes min")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("$probability% chance of rain $timeText, lasting approximately $durationMinutes minutes. Don't forget your umbrella!")
            )
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        
        notificationManager.notify(RAIN_ALERT_NOTIFICATION_ID, notification)
    }
    
    /**
     * Cancel all notifications
     */
    fun cancelAll() {
        notificationManager.cancelAll()
    }
    
    /**
     * Cancel specific notification
     */
    fun cancel(notificationId: Int) {
        notificationManager.cancel(notificationId)
    }
    
    private fun buildDailyForecastText(
        todayForecast: DailyForecastItem,
        currentWeather: CurrentWeather?,
        condition: WeatherCondition
    ): String {
        val parts = mutableListOf<String>()
        
        // Condition and temperatures
        parts.add("${condition.description} with a high of ${todayForecast.temperatureMax.toInt()}° and low of ${todayForecast.temperatureMin.toInt()}°")
        
        // Current temperature if available
        currentWeather?.let {
            parts.add("Currently ${it.temperature.toInt()}° (feels like ${it.apparentTemperature.toInt()}°)")
        }
        
        // Precipitation
        if (todayForecast.precipitationProbability > 20) {
            parts.add("${todayForecast.precipitationProbability}% chance of precipitation")
        }
        
        // Wind - not available in DailyForecastItem
        
        return parts.joinToString(". ") + "."
    }
    
    companion object {
        const val DAILY_FORECAST_NOTIFICATION_ID = 1001
        const val RAIN_ALERT_NOTIFICATION_ID = 1002
    }
}
