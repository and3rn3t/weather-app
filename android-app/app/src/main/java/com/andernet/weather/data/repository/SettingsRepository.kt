package com.andernet.weather.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.andernet.weather.data.model.PrecipitationUnit
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.model.WindSpeedUnit
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

/**
 * Repository for user preferences/settings
 * Similar to iOS SettingsManager
 */
@Singleton
class SettingsRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    companion object {
        private val TEMPERATURE_UNIT = stringPreferencesKey("temperature_unit")
        private val WIND_SPEED_UNIT = stringPreferencesKey("wind_speed_unit")
        private val PRECIPITATION_UNIT = stringPreferencesKey("precipitation_unit")
        private val USE_24_HOUR_FORMAT = booleanPreferencesKey("use_24_hour_format")
        private val DAILY_FORECAST_ENABLED = booleanPreferencesKey("daily_forecast_enabled")
        private val DAILY_FORECAST_HOUR = stringPreferencesKey("daily_forecast_hour")
        private val RAIN_ALERTS_ENABLED = booleanPreferencesKey("rain_alerts_enabled")
        private val RAIN_ALERT_THRESHOLD = stringPreferencesKey("rain_alert_threshold")
        private val LAST_LATITUDE = doublePreferencesKey("last_latitude")
        private val LAST_LONGITUDE = doublePreferencesKey("last_longitude")
    }
    
    /**
     * Temperature unit preference
     */
    val temperatureUnit: Flow<TemperatureUnit> = context.dataStore.data.map { preferences ->
        val unitName = preferences[TEMPERATURE_UNIT] ?: getDefaultTemperatureUnit().name
        TemperatureUnit.valueOf(unitName)
    }
    
    suspend fun setTemperatureUnit(unit: TemperatureUnit) {
        context.dataStore.edit { preferences ->
            preferences[TEMPERATURE_UNIT] = unit.name
        }
    }
    
    /**
     * Wind speed unit preference
     */
    val windSpeedUnit: Flow<WindSpeedUnit> = context.dataStore.data.map { preferences ->
        val unitName = preferences[WIND_SPEED_UNIT] ?: getDefaultWindSpeedUnit().name
        WindSpeedUnit.valueOf(unitName)
    }
    
    suspend fun setWindSpeedUnit(unit: WindSpeedUnit) {
        context.dataStore.edit { preferences ->
            preferences[WIND_SPEED_UNIT] = unit.name
        }
    }
    
    /**
     * Precipitation unit preference
     */
    val precipitationUnit: Flow<PrecipitationUnit> = context.dataStore.data.map { preferences ->
        val unitName = preferences[PRECIPITATION_UNIT] ?: getDefaultPrecipitationUnit().name
        PrecipitationUnit.valueOf(unitName)
    }
    
    suspend fun setPrecipitationUnit(unit: PrecipitationUnit) {
        context.dataStore.edit { preferences ->
            preferences[PRECIPITATION_UNIT] = unit.name
        }
    }
    
    /**
     * 24-hour time format preference
     */
    val use24HourFormat: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[USE_24_HOUR_FORMAT] ?: false
    }
    
    suspend fun setUse24HourFormat(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[USE_24_HOUR_FORMAT] = enabled
        }
    }
    
    /**
     * Daily forecast notification preference
     */
    val dailyForecastEnabled: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[DAILY_FORECAST_ENABLED] ?: false
    }
    
    suspend fun setDailyForecastEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[DAILY_FORECAST_ENABLED] = enabled
        }
    }
    
    /**
     * Rain alerts preference
     */
    val rainAlertsEnabled: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[RAIN_ALERTS_ENABLED] ?: true
    }
    
    suspend fun setRainAlertsEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[RAIN_ALERTS_ENABLED] = enabled
        }
    }
    
    /**
     * Daily forecast notification hour (7 AM default)
     */
    fun getDailyForecastHour(): Flow<Int> = context.dataStore.data.map { preferences ->
        preferences[DAILY_FORECAST_HOUR]?.toIntOrNull() ?: 7
    }
    
    suspend fun setDailyForecastHour(hour: Int) {
        context.dataStore.edit { preferences ->
            preferences[DAILY_FORECAST_HOUR] = hour.toString()
        }
    }
    
    /**
     * Rain alert threshold percentage (50% default)
     */
    fun getRainAlertThreshold(): Flow<Int> = context.dataStore.data.map { preferences ->
        preferences[RAIN_ALERT_THRESHOLD]?.toIntOrNull() ?: 50
    }
    
    suspend fun setRainAlertThreshold(threshold: Int) {
        context.dataStore.edit { preferences ->
            preferences[RAIN_ALERT_THRESHOLD] = threshold.coerceIn(30, 80).toString()
        }
    }
    
    /**
     * Convenience methods for compatibility with existing code
     */
    fun getDailyForecastEnabled(): Flow<Boolean> = dailyForecastEnabled
    fun getRainAlertsEnabled(): Flow<Boolean> = rainAlertsEnabled
    fun getTemperatureUnit(): Flow<TemperatureUnit> = temperatureUnit
    fun getWindSpeedUnit(): Flow<WindSpeedUnit> = windSpeedUnit
    
    /**
     * Last known location
     */
    suspend fun saveLastLocation(latitude: Double, longitude: Double) {
        context.dataStore.edit { preferences ->
            preferences[LAST_LATITUDE] = latitude
            preferences[LAST_LONGITUDE] = longitude
        }
    }
    
    suspend fun getLastLocation(): Pair<Double, Double>? {
        val preferences = context.dataStore.data.map { it }.first()
        val lat = preferences[LAST_LATITUDE]
        val lon = preferences[LAST_LONGITUDE]
        return if (lat != null && lon != null) Pair(lat, lon) else null
    }
    
    /**
     * Get default units based on locale (like iOS)
     */
    private fun getDefaultTemperatureUnit(): TemperatureUnit {
        return when (Locale.getDefault().country) {
            "US", "BS", "BZ", "KY", "PW" -> TemperatureUnit.FAHRENHEIT
            else -> TemperatureUnit.CELSIUS
        }
    }
    
    private fun getDefaultWindSpeedUnit(): WindSpeedUnit {
        return when (Locale.getDefault().country) {
            "US" -> WindSpeedUnit.MPH
            else -> WindSpeedUnit.KMH
        }
    }
    
    private fun getDefaultPrecipitationUnit(): PrecipitationUnit {
        return when (Locale.getDefault().country) {
            "US" -> PrecipitationUnit.INCHES
            else -> PrecipitationUnit.MM
        }
    }
}

// Extension to get first value from Flow
private suspend fun <T> Flow<T>.first(): T {
    var result: T? = null
    collect { value ->
        result = value
        throw StopCollectionException()
    }
    return result ?: throw NoSuchElementException("Flow is empty")
}

private class StopCollectionException : Exception()
