package com.andernet.weather.workers

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.*
import com.andernet.weather.data.repository.SettingsRepository
import com.andernet.weather.data.repository.WeatherRepository
import com.andernet.weather.notification.WeatherNotificationManager
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import kotlinx.coroutines.flow.first
import java.util.concurrent.TimeUnit

/**
 * Worker to check for rain in the next 2 hours and send alerts
 */
@HiltWorker
class RainAlertWorker @AssistedInject constructor(
    @Assisted private val context: Context,
    @Assisted workerParams: WorkerParameters,
    private val weatherRepository: WeatherRepository,
    private val settingsRepository: SettingsRepository,
    private val notificationManager: WeatherNotificationManager
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            // Check if rain alerts are enabled
            val rainAlertsEnabled = settingsRepository.getRainAlertsEnabled().first()
            if (!rainAlertsEnabled) {
                return Result.success()
            }
            
            val rainThreshold = settingsRepository.getRainAlertThreshold().first()
            
            // Get weather data
            val weatherData = weatherRepository.getCachedWeatherData()
            val location = weatherRepository.getCurrentLocation()
            
            if (weatherData != null && location != null) {
                // Check next 2 hours for rain
                val now = System.currentTimeMillis()
                val twoHoursLater = now + (2 * 60 * 60 * 1000)
                
                val upcomingRain = weatherData.hourly
                    .filter { it.time in now until twoHoursLater }
                    .firstOrNull { it.precipitationProbability >= rainThreshold }
                
                if (upcomingRain != null) {
                    val minutesUntilRain = ((upcomingRain.time - now) / (60 * 1000)).toInt()
                    
                    // Calculate duration of rain
                    val rainDuration = weatherData.hourly
                        .filter { it.time >= upcomingRain.time }
                        .takeWhile { it.precipitationProbability >= rainThreshold }
                        .size * 60 // Each entry is 1 hour
                    
                    // Only send notification if we haven't sent one recently
                    val lastNotificationTime = context.getSharedPreferences("rain_alerts", Context.MODE_PRIVATE)
                        .getLong("last_rain_alert_time", 0)
                    
                    val timeSinceLastAlert = now - lastNotificationTime
                    val minTimeBetweenAlerts = 4 * 60 * 60 * 1000L // 4 hours
                    
                    if (timeSinceLastAlert > minTimeBetweenAlerts) {
                        notificationManager.showRainAlert(
                            locationName = location.displayName ?: "Your Location",
                            minutesUntilRain = minutesUntilRain,
                            durationMinutes = rainDuration,
                            probability = upcomingRain.precipitationProbability
                        )
                        
                        // Update last notification time
                        context.getSharedPreferences("rain_alerts", Context.MODE_PRIVATE)
                            .edit()
                            .putLong("last_rain_alert_time", now)
                            .apply()
                    }
                }
            }
            
            Result.success()
        } catch (e: Exception) {
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }

    companion object {
        private const val WORK_NAME = "RainAlertWork"
        
        /**
         * Schedule hourly rain alert checks
         */
        fun schedule(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            
            val workRequest = PeriodicWorkRequestBuilder<RainAlertWorker>(
                repeatInterval = 1,
                repeatIntervalTimeUnit = TimeUnit.HOURS,
                flexTimeInterval = 15,
                flexTimeIntervalUnit = TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .build()
            
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                workRequest
            )
        }
        
        /**
         * Cancel rain alert checks
         */
        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
