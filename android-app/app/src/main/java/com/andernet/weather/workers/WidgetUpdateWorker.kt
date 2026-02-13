package com.andernet.weather.workers

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.updateAll
import androidx.hilt.work.HiltWorker
import androidx.work.*
import com.andernet.weather.ui.widget.LargeWeatherWidget
import com.andernet.weather.ui.widget.MediumWeatherWidget
import com.andernet.weather.ui.widget.SmallWeatherWidget
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import java.util.concurrent.TimeUnit

/**
 * Worker to update weather widgets periodically
 */
@HiltWorker
class WidgetUpdateWorker @AssistedInject constructor(
    @Assisted private val context: Context,
    @Assisted workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            // Update all widget instances
            SmallWeatherWidget().updateAll(context)
            MediumWeatherWidget().updateAll(context)
            LargeWeatherWidget().updateAll(context)
            
            Result.success()
        } catch (e: Exception) {
            // Retry on failure
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }

    companion object {
        private const val WORK_NAME = "WidgetUpdateWork"
        
        /**
         * Schedule periodic widget updates every 30 minutes
         */
        fun schedule(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .setRequiresBatteryNotLow(true)
                .build()
            
            val workRequest = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                repeatInterval = 30,
                repeatIntervalTimeUnit = TimeUnit.MINUTES,
                flexTimeInterval = 10,
                flexTimeIntervalUnit = TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .setBackoffCriteria(
                    BackoffPolicy.EXPONENTIAL,
                    WorkRequest.MIN_BACKOFF_MILLIS,
                    TimeUnit.MILLISECONDS
                )
                .build()
            
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                workRequest
            )
        }
        
        /**
         * Cancel widget updates
         */
        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
        
        /**
         * Trigger immediate widget update
         */
        fun updateNow(context: Context) {
            val workRequest = OneTimeWorkRequestBuilder<WidgetUpdateWorker>()
                .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                .build()
            
            WorkManager.getInstance(context).enqueue(workRequest)
        }
    }
}
