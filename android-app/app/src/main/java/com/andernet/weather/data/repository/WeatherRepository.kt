package com.andernet.weather.data.repository

import android.content.Context
import com.andernet.weather.data.model.PrecipitationUnit
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.model.WeatherData
import com.andernet.weather.data.model.WeatherError
import com.andernet.weather.data.model.WindSpeedUnit
import com.andernet.weather.data.remote.WeatherApiService
import com.squareup.moshi.Moshi
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.pow

/**
 * Repository for weather data with caching and retry logic
 * Implements similar patterns to iOS WeatherService.swift
 */
@Singleton
class WeatherRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val apiService: WeatherApiService,
    private val moshi: Moshi
) {
    private val cacheDir = File(context.filesDir, "weather_cache")
    private var lastFetchTime: Long = 0
    private val minFetchInterval = 60_000L // 1 minute debouncing
    private var cachedWeatherData: WeatherData? = null
    
    init {
        cacheDir.mkdirs()
        // Load cached data synchronously on init for instant startup
        loadCachedDataSync()
    }
    
    /**
     * Fetch weather data with caching, debouncing, and retry logic
     */
    suspend fun getWeatherData(
        latitude: Double,
        longitude: Double,
        temperatureUnit: TemperatureUnit = TemperatureUnit.CELSIUS,
        windSpeedUnit: WindSpeedUnit = WindSpeedUnit.KMH,
        precipitationUnit: PrecipitationUnit = PrecipitationUnit.MM,
        forceRefresh: Boolean = false
    ): kotlin.Result<WeatherData> = withContext(Dispatchers.IO) {
        try {
            // Check debouncing - don't fetch if recently fetched
            val now = System.currentTimeMillis()
            if (!forceRefresh && (now - lastFetchTime) < minFetchInterval && cachedWeatherData != null) {
                return@withContext kotlin.Result.success(cachedWeatherData!!)
            }
            
            // Try to fetch from API with retry logic
            val weatherData = fetchWithRetry(
                latitude = latitude,
                longitude = longitude,
                temperatureUnit = temperatureUnit,
                windSpeedUnit = windSpeedUnit,
                precipitationUnit = precipitationUnit
            )
            
            // Cache successful response
            cacheWeatherData(weatherData)
            cachedWeatherData = weatherData
            lastFetchTime = now
            
            kotlin.Result.success(weatherData)
            
        } catch (e: Exception) {
            // If network fails, try to return cached data
            cachedWeatherData?.let {
                return@withContext kotlin.Result.success(it)
            }
            
            // No cached data available
            kotlin.Result.failure(WeatherError.fromThrowable(e))
        }
    }
    
    /**
     * Fetch with exponential backoff retry logic
     */
    private suspend fun fetchWithRetry(
        latitude: Double,
        longitude: Double,
        temperatureUnit: TemperatureUnit,
        windSpeedUnit: WindSpeedUnit,
        precipitationUnit: PrecipitationUnit,
        maxRetries: Int = 3
    ): WeatherData {
        var lastException: Exception? = null
        
        repeat(maxRetries) { attempt ->
            try {
                val response = apiService.getWeatherForecast(
                    latitude = latitude,
                    longitude = longitude,
                    temperatureUnit = temperatureUnit.apiParam,
                    windSpeedUnit = windSpeedUnit.apiParam,
                    precipitationUnit = precipitationUnit.apiParam
                )
                
                if (response.isSuccessful && response.body() != null) {
                    return response.body()!!
                } else {
                    throw WeatherError.APIError(
                        statusCode = response.code(),
                        errorMessage = response.message()
                    )
                }
            } catch (e: Exception) {
                lastException = e
                
                // Don't retry on last attempt
                if (attempt < maxRetries - 1) {
                    // Exponential backoff: 100ms, 400ms, 1600ms
                    val delayMs = (100 * 2.0.pow(attempt * 2)).toLong()
                    delay(delayMs)
                }
            }
        }
        
        throw lastException ?: WeatherError.UnknownError()
    }
    
    /**
     * Cache weather data to disk
     */
    private fun cacheWeatherData(weatherData: WeatherData) {
        try {
            val cacheFile = File(cacheDir, "weather_data.json")
            val adapter = moshi.adapter(WeatherData::class.java)
            val json = adapter.toJson(weatherData)
            cacheFile.writeText(json)
        } catch (e: Exception) {
            // Cache errors are non-fatal
            e.printStackTrace()
        }
    }
    
    /**
     * Load cached data synchronously for instant startup
     */
    private fun loadCachedDataSync() {
        try {
            val cacheFile = File(cacheDir, "weather_data.json")
            if (cacheFile.exists()) {
                val json = cacheFile.readText()
                val adapter = moshi.adapter(WeatherData::class.java)
                cachedWeatherData = adapter.fromJson(json)
            }
        } catch (e: Exception) {
            // Cache errors are non-fatal
            e.printStackTrace()
        }
    }
    
    /**
     * Get cached data if available
     */
    fun getCachedData(): WeatherData? = cachedWeatherData
    
    /**
     * Clear all cached data
     */
    fun clearCache() {
        cachedWeatherData = null
        lastFetchTime = 0
        cacheDir.listFiles()?.forEach { it.delete() }
    }
}
