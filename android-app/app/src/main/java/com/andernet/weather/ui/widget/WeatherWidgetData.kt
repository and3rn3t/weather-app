package com.andernet.weather.ui.widget

import android.content.Context
import com.andernet.weather.data.local.WeatherDatabase
import com.andernet.weather.data.model.CurrentWeatherData
import com.andernet.weather.data.model.HourlyWeatherData
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.repository.SettingsRepository
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

/**
 * Data container for widget content
 */
data class WeatherWidgetData(
    val locationName: String,
    val currentWeather: CurrentWeatherData?,
    val hourlyForecast: List<HourlyWeatherData>,
    val temperatureUnit: TemperatureUnit
) {
    companion object {
        /**
         * Load widget data from cache/database
         * This runs synchronously to provide quick widget updates
         */
        fun load(context: Context): WeatherWidgetData = runBlocking {
            try {
                val database = WeatherDatabase.getInstance(context)
                val settingsRepository = SettingsRepository(context)
                
                // Get last cached weather data
                val cachedWeatherJson = context.getSharedPreferences("weather_cache", Context.MODE_PRIVATE)
                    .getString("last_weather_data", null)
                
                // Get settings
                val temperatureUnit = settingsRepository.getTemperatureUnit().first()
                
                // Get location name from SharedPreferences
                val locationName = context.getSharedPreferences("weather_prefs", Context.MODE_PRIVATE)
                    .getString("last_location_name", "Unknown") ?: "Unknown"
                
                // Parse cached weather or provide defaults
                // In production, you'd deserialize the JSON here
                WeatherWidgetData(
                    locationName = locationName,
                    currentWeather = null, // Will be updated by worker
                    hourlyForecast = emptyList(),
                    temperatureUnit = temperatureUnit
                )
            } catch (e: Exception) {
                // Return default data on error
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
