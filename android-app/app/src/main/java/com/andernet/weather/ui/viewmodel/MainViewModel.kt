package com.andernet.weather.ui.viewmodel

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
import javax.inject.Inject

/**
 * UI State for the main weather screen
 */
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
    private val settingsRepository: SettingsRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(WeatherUiState())
    val uiState: StateFlow<WeatherUiState> = _uiState.asStateFlow()
    
    init {
        // Load cached data immediately on init (like iOS synchronous cache loading)
        loadCachedData()
        
        // Observe settings changes
        observeSettings()
        
        // Start loading current location and weather
        loadCurrentLocationAndWeather()
    }
    
    /**
     * Load cached data synchronously for instant startup
     */
    private fun loadCachedData() {
        weatherRepository.getCachedData()?.let { cachedData ->
            _uiState.update { it.copy(weatherData = cachedData) }
        }
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
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            locationRepository.getCurrentLocation()
                .onSuccess { location ->
                    _uiState.update { it.copy(location = location) }
                    
                    // Save last location
                    settingsRepository.saveLastLocation(location.latitude, location.longitude)
                    
                    // Fetch weather for location
                    fetchWeather(location.latitude, location.longitude)
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error as? WeatherError ?: WeatherError.fromThrowable(error)
                        )
                    }
                }
        }
    }
    
    /**
     * Fetch weather for specific coordinates
     */
    fun fetchWeather(latitude: Double, longitude: Double, forceRefresh: Boolean = false) {
        viewModelScope.launch {
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
    
    /**
     * Get hourly forecast items for UI display
     */
    fun getHourlyForecast(hours: Int = 24): List<HourlyForecastItem> {
        val hourly = _uiState.value.weatherData?.hourly ?: return emptyList()
        
        return (0 until minOf(hours, hourly.time.size)).map { index ->
            HourlyForecastItem(
                time = hourly.time[index],
                temperature = hourly.temperature[index],
                weatherCode = hourly.weatherCode[index],
                precipitationProbability = hourly.precipitationProbability?.getOrNull(index) ?: 0,
                windSpeed = hourly.windSpeed[index]
            )
        }
    }
    
    /**
     * Get daily forecast items for UI display
     */
    fun getDailyForecast(): List<DailyForecastItem> {
        val daily = _uiState.value.weatherData?.daily ?: return emptyList()
        
        return daily.time.indices.map { index ->
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
