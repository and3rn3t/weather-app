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
import java.util.*
import java.util.concurrent.TimeUnit

/**
 * Worker to send daily forecast notification
 */
@HiltWorker
class DailyForecastWorker @AssistedInject constructor(
    @Assisted private val context: Context,
    @Assisted workerParams: WorkerParameters,
    private val weatherRepository: WeatherRepository,
    private val settingsRepository: SettingsRepository,
    private val notificationManager: WeatherNotificationManager
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            // Check if notifications are enabled
            val notificationsEnabled = settingsRepository.getDailyForecastEnabled().first()
            if (!notificationsEnabled) {
                return Result.success()
            }
            
            // Get weather data
            val weatherData = weatherRepository.getCachedWeatherData()
            val location = weatherRepository.getCurrentLocation()
            
            if (weatherData != null && location != null) {
                val today = weatherData.daily.firstOrNull()
                if (today != null) {
                    notificationManager.showDailyForecast(
                        locationName = location.displayName ?: "Your Location",
                        todayForecast = today,
                        currentWeather = weatherData.current
                    )
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
        private const val WORK_NAME = "DailyForecastWork"
        
        /**
         * Schedule daily forecast notification at specified hour (7 AM default)
         */
        fun schedule(context: Context, hour: Int = 7, minute: Int = 0) {
            // Calculate initial delay to reach the target time
            val currentTime = Calendar.getInstance()
            val targetTime = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                
                // If target time is in the past today, schedule for tomorrow
                if (before(currentTime)) {
                    add(Calendar.DAY_OF_MONTH, 1)
                }
            }
            
            val initialDelay = targetTime.timeInMillis - currentTime.timeInMillis
            
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            
            val workRequest = PeriodicWorkRequestBuilder<DailyForecastWorker>(
                repeatInterval = 24,
                repeatIntervalTimeUnit = TimeUnit.HOURS,
                flexTimeInterval = 1,
                flexTimeIntervalUnit = TimeUnit.HOURS
            )
                .setInitialDelay(initialDelay, TimeUnit.MILLISECONDS)
                .setConstraints(constraints)
                .build()
            
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                workRequest
            )
        }
        
        /**
         * Cancel daily forecast notifications
         */
        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
