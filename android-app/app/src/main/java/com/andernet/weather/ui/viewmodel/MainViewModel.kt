package com.andernet.weather.ui.viewmodel

import androidx.compose.runtime.Stable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.andernet.weather.data.model.DailyForecastItem
import com.andernet.weather.data.model.HourlyForecastItem
import com.andernet.weather.data.model.LocationData
import com.andernet.weather.data.model.PrecipitationUnit
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.model.WeatherData
import com.andernet.weather.data.model.WeatherError
import com.andernet.weather.data.model.WindSpeedUnit
import com.andernet.weather.data.repository.LocationRepository
import com.andernet.weather.data.repository.SettingsRepository
import com.andernet.weather.data.repository.WeatherRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import com.andernet.weather.utils.PerformanceMonitor
import javax.inject.Inject

/**
 * UI State for the main weather screen
 */
@Stable
data class WeatherUiState(
    val weatherData: WeatherData? = null,
    val location: LocationData? = null,
    val isLoading: Boolean = false,
    val error: WeatherError? = null,
    val isRefreshing: Boolean = false,
    val isOffline: Boolean = false,
    val temperatureUnit: TemperatureUnit = TemperatureUnit.CELSIUS,
    val windSpeedUnit: WindSpeedUnit = WindSpeedUnit.KMH,
    val precipitationUnit: PrecipitationUnit = PrecipitationUnit.MM
)

/**
 * Main ViewModel for weather screen
 * Similar to iOS MainView with @Observable
 */
@HiltViewModel
class MainViewModel @Inject constructor(
    private val weatherRepository: WeatherRepository,
    private val locationRepository: LocationRepository,
    private val settingsRepository: SettingsRepository,
    private val performanceMonitor: PerformanceMonitor
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(WeatherUiState())
    val uiState: StateFlow<WeatherUiState> = _uiState.asStateFlow()
    
    // Derived state for computed properties to optimize recomposition
    val hourlyForecast by derivedStateOf {
        val hourly = _uiState.value.weatherData?.hourly
        if (hourly == null || hourly.time.isEmpty()) {
            emptyList()
        } else {
            (0 until minOf(24, hourly.time.size)).map { index ->
                HourlyForecastItem(
                    time = hourly.time[index],
                    temperature = hourly.temperature[index],
                    weatherCode = hourly.weatherCode[index],
                    precipitationProbability = hourly.precipitationProbability?.getOrNull(index) ?: 0,
                    windSpeed = hourly.windSpeed[index]
                )
            }
        }
    }
    
    val dailyForecast by derivedStateOf {
        val daily = _uiState.value.weatherData?.daily
        if (daily == null || daily.time.isEmpty()) {
            emptyList()
        } else {
            daily.time.indices.map { index ->
                DailyForecastItem(
                    date = daily.time[index],
                    weatherCode = daily.weatherCode[index],
                    temperatureMax = daily.temperatureMax[index],
                    temperatureMin = daily.temperatureMin[index],
                    precipitationProbability = daily.precipitationProbabilityMax?.getOrNull(index) ?: 0,
                    sunrise = daily.sunrise[index],
                    sunset = daily.sunset[index]
                )
            }
        }
    }
    
    // Derived state for temperature trend
    val temperatureTrend by derivedStateOf {
        val temps = _uiState.value.weatherData?.hourly?.temperature
        if (temps == null || temps.size < 6) {
            "steady"
        } else {
            val firstThree = temps.take(3).average()
            val nextThree = temps.drop(3).take(3).average()
            val diff = nextThree - firstThree
            when {
                diff > 2 -> "warming"
                diff < -2 -> "cooling"
                else -> "steady"
            }
        }
    }
    
    init {
        // Track ViewModel initialization
        performanceMonitor.startTrace("viewmodel_init")
        
        // Load cached data immediately on init (like iOS synchronous cache loading)
        loadCachedData()
        
        // Observe settings changes
        observeSettings()
        
        // Start loading current location and weather
        loadCurrentLocationAndWeather()
        
        performanceMonitor.stopTrace("viewmodel_init")
    }
    
    /**
     * Load cached data synchronously for instant startup
     */
    private fun loadCachedData() {
        performanceMonitor.startTrace("load_cached_data")
        weatherRepository.getCachedData()?.let { cachedData ->
            _uiState.update { it.copy(weatherData = cachedData) }
        }
        performanceMonitor.stopTrace("load_cached_data")
    }
    
    /**
     * Observe user settings for reactive updates
     */
    private fun observeSettings() {
        viewModelScope.launch {
            launch {
                settingsRepository.temperatureUnit.collect { unit ->
                    _uiState.update { it.copy(temperatureUnit = unit) }
                }
            }
            launch {
                settingsRepository.windSpeedUnit.collect { unit ->
                    _uiState.update { it.copy(windSpeedUnit = unit) }
                }
            }
            launch {
                settingsRepository.precipitationUnit.collect { unit ->
                    _uiState.update { it.copy(precipitationUnit = unit) }
                }
            }
        }
    }
    
    /**
     * Load current location and fetch weather
     */
    fun loadCurrentLocationAndWeather() {
        viewModelScope.launch {
            performanceMonitor.startTrace("load_current_location_weather", mapOf(
                "trigger" to "user_action"
            ))
            
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            locationRepository.getCurrentLocation()
                .onSuccess { location ->
                    _uiState.update { it.copy(location = location) }
                    
                    // Save last location
                    settingsRepository.saveLastLocation(location.latitude, location.longitude)
                    
                    // Fetch weather for location
                    fetchWeather(location.latitude, location.longitude)
                    performanceMonitor.stopTrace("load_current_location_weather")
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error as? WeatherError ?: WeatherError.fromThrowable(error)
                        )
                    }
                    performanceMonitor.stopTrace("load_current_location_weather")
                    performanceMonitor.recordEvent("location_load_failed", mapOf(
                        "error" to error.message.orEmpty()
                    ))
                }
        }
    }
    
    /**
     * Fetch weather for specific coordinates
     */
    fun fetchWeather(latitude: Double, longitude: Double, forceRefresh: Boolean = false) {
        viewModelScope.launch {
            val traceKey = if (forceRefresh) "fetch_weather_refresh" else "fetch_weather"
            performanceMonitor.startTrace(traceKey, mapOf(
                "force_refresh" to forceRefresh.toString(),
                "lat" to latitude.toString().take(5), // Truncated for privacy
                "lng" to longitude.toString().take(5)
            ))
            
            if (forceRefresh) {
                _uiState.update { it.copy(isRefreshing = true, error = null) }
            } else {
                _uiState.update { it.copy(isLoading = true, error = null) }
            }
            
            val temperatureUnit = settingsRepository.temperatureUnit.first()
            val windSpeedUnit = settingsRepository.windSpeedUnit.first()
            val precipitationUnit = settingsRepository.precipitationUnit.first()
            
            weatherRepository.getWeatherData(
                latitude = latitude,
                longitude = longitude,
                temperatureUnit = temperatureUnit,
                windSpeedUnit = windSpeedUnit,
                precipitationUnit = precipitationUnit,
                forceRefresh = forceRefresh
            )
                .onSuccess { weatherData ->
                    _uiState.update {
                        it.copy(
                            weatherData = weatherData,
                            isLoading = false,
                            isRefreshing = false,
                            error = null,
                            isOffline = false
                        )
                    }
                    performanceMonitor.stopTrace(traceKey)
                    performanceMonitor.recordEvent("weather_loaded_successfully", mapOf(
                        "force_refresh" to forceRefresh.toString(),
                        "has_hourly_data" to (weatherData.hourly != null).toString(),
                        "has_daily_data" to (weatherData.daily != null).toString()
                    ))
                }
                .onFailure { error ->
                    val weatherError = error as? WeatherError ?: WeatherError.fromThrowable(error)
                    
                    // If we have cached data, show it with offline indicator
                    val cachedData = weatherRepository.getCachedData()
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            isRefreshing = false,
                            error = if (cachedData == null) weatherError else null,
                            isOffline = cachedData != null
                        )
                    }
                    performanceMonitor.stopTrace(traceKey)
                    performanceMonitor.recordEvent("weather_load_failed", mapOf(
                        "error_type" to weatherError.javaClass.simpleName,
                        "has_cached_data" to (cachedData != null).toString(),
                        "force_refresh" to forceRefresh.toString()
                    ))
                }
        }
    }
    
    /**
     * Load weather for a specific location (from favorites or search)
     */
    fun loadWeatherForLocation(location: LocationData) {
        _uiState.update { it.copy(location = location) }
        fetchWeather(location.latitude, location.longitude)
    }
    
    /**
     * Refresh current weather
     */
    fun refresh() {
        val location = _uiState.value.location
        if (location != null) {
            fetchWeather(location.latitude, location.longitude, forceRefresh = true)
        } else {
            loadCurrentLocationAndWeather()
        }
    }
    
    /**
     * Retry after error
     */
    fun retry() {
        _uiState.update { it.copy(error = null) }
        val location = _uiState.value.location
        if (location != null) {
            fetchWeather(location.latitude, location.longitude, forceRefresh = true)
        } else {
            loadCurrentLocationAndWeather()
        }
    }
}
