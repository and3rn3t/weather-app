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
    private val locationRepository: LocationRepository,
    private val settingsRepository: SettingsRepository,
    private val notificationManager: WeatherNotificationManager
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            // Check if notifications are enabled
            val notificationsEnabled = settingsRepository.dailyForecastEnabled.first()
            if (!notificationsEnabled) {
                return Result.success()
            }
            
            // Get weather data and location
            val weatherData = weatherRepository.getCachedData()
            val locationResult = locationRepository.getCurrentLocation()
            
            if (weatherData != null && weatherData.daily != null && locationResult.isSuccess) {
                val location = locationResult.getOrNull()
                val daily = weatherData.daily
                
                // Get today's forecast (first day in arrays)
                if (daily.time.isNotEmpty()) {
                    val today = com.andernet.weather.data.model.DailyForecastItem(
                        date = daily.time[0],
                        weatherCode = daily.weatherCode[0],
                        temperatureMax = daily.temperatureMax[0],
                        temperatureMin = daily.temperatureMin[0],
                        precipitationProbability = daily.precipitationProbabilityMax?.getOrNull(0) ?: 0,
                        sunrise = daily.sunrise[0],
                        sunset = daily.sunset[0]
                    )
                    
                    notificationManager.showDailyForecast(
                        locationName = location?.displayName ?: "Your Location",
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
