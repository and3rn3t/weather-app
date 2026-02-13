package com.andernet.weather.ui.widget

import android.content.Context
import com.andernet.weather.data.local.WeatherDatabase
import com.andernet.weather.data.model.CurrentWeather
import com.andernet.weather.data.model.HourlyForecastItem
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.repository.SettingsRepository
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

/**
 * Data container for widget content
 */
data class WeatherWidgetData(
    val locationName: String,
    val currentWeather: CurrentWeather?,
    val hourlyForecast: List<HourlyForecastItem>,
    val temperatureUnit: TemperatureUnit
) {
    companion object {
        /**
         * Load widget data from cache
         */
        fun load(context: Context): WeatherWidgetData = runBlocking {
            try {
                val settingsRepository = SettingsRepository(context)
                
                // Get settings
                val temperatureUnit = settingsRepository.temperatureUnit.first()
                
                // Get location name from SharedPreferences
                val locationName = context.getSharedPreferences("weather_prefs", Context.MODE_PRIVATE)
                    .getString("last_location_name", "Unknown") ?: "Unknown"
                
                // Return default data - will be updated by worker
                WeatherWidgetData(
                    locationName = locationName,
                    currentWeather = null,
                    hourlyForecast = emptyList(),
                    temperatureUnit = temperatureUnit
                )
            } catch (e: Exception) {
                WeatherWidgetData(
                    locationName = "Loading...",
                    currentWeather = null,
                    hourlyForecast = emptyList(),
                    temperatureUnit = TemperatureUnit.FAHRENHEIT
                )
            }
        }
    }
}
