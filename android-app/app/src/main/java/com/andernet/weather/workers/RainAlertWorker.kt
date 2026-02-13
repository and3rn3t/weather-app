package com.andernet.weather.workers

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.*
import com.andernet.weather.data.repository.LocationRepository
import com.andernet.weather.data.repository.SettingsRepository
import com.andernet.weather.data.repository.WeatherRepository
import com.andernet.weather.notification.WeatherNotificationManager
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import kotlinx.coroutines.flow.first
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.concurrent.TimeUnit

/**
 * Worker to check for rain in the next 2 hours and send alerts
 */
@HiltWorker
class RainAlertWorker @AssistedInject constructor(
    @Assisted private val context: Context,
    @Assisted workerParams: WorkerParameters,
    private val weatherRepository: WeatherRepository,
    private val locationRepository: LocationRepository,
    private val settingsRepository: SettingsRepository,
    private val notificationManager: WeatherNotificationManager
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            // Check if rain alerts are enabled
            val rainAlertsEnabled = settingsRepository.rainAlertsEnabled.first()
            if (!rainAlertsEnabled) {
                return Result.success()
            }
            
            val rainThreshold = settingsRepository.getRainAlertThreshold().first()
            
            // Get weather data and location
            val weatherData = weatherRepository.getCachedData()
            val locationResult = locationRepository.getCurrentLocation()
            
            if (weatherData != null && weatherData.hourly != null && locationResult.isSuccess) {
                val location = locationResult.getOrNull()
                val hourlyData = weatherData.hourly
                val now = LocalDateTime.now()
                val twoHoursLater = now.plusHours(2)
                
                // Find first hour with rain in next 2 hours
                var upcomingRainIndex = -1
                var upcomingRainTime: LocalDateTime? = null
                
                hourlyData.time.forEachIndexed { index, timeStr ->
                    val hourTime = LocalDateTime.parse(timeStr, DateTimeFormatter.ISO_DATE_TIME)
                    if (hourTime.isAfter(now) && hourTime.isBefore(twoHoursLater)) {
                        val probability = hourlyData.precipitationProbability?.getOrNull(index) ?: 0
                        if (probability >= rainThreshold && upcomingRainIndex == -1) {
                            upcomingRainIndex = index
                            upcomingRainTime = hourTime
                        }
                    }
                }
                
                if (upcomingRainIndex != -1 && upcomingRainTime != null) {
                    val minutesUntilRain = java.time.Duration.between(now, upcomingRainTime).toMinutes().toInt()
                    
                    // Calculate duration of rain (simplified)
                    var rainDuration = 60 // At least 1 hour
                    for (i in (upcomingRainIndex + 1) until minOf(upcomingRainIndex + 4, hourlyData.time.size)) {
                        val probability = hourlyData.precipitationProbability?.getOrNull(i) ?: 0
                        if (probability >= rainThreshold) {
                            rainDuration += 60
                        } else {
                            break
                        }
                    }
                    
                    // Only send notification if we haven't sent one recently
                    val lastNotificationTime = context.getSharedPreferences("rain_alerts", Context.MODE_PRIVATE)
                        .getLong("last_rain_alert_time", 0)
                    
                    val timeSinceLastAlert = System.currentTimeMillis() - lastNotificationTime
                    val minTimeBetweenAlerts = 4 * 60 * 60 * 1000L // 4 hours
                    
                    if (timeSinceLastAlert > minTimeBetweenAlerts) {
                        val probability = hourlyData.precipitationProbability?.getOrNull(upcomingRainIndex) ?: 0
                        notificationManager.showRainAlert(
                            locationName = location?.displayName?: "Your Location",
                            minutesUntilRain = minutesUntilRain,
                            durationMinutes = rainDuration,
                            probability = probability
                        )
                        
                        // Update last notification time
                        context.getSharedPreferences("rain_alerts", Context.MODE_PRIVATE)
                            .edit()
                            .putLong("last_rain_alert_time", System.currentTimeMillis())
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
