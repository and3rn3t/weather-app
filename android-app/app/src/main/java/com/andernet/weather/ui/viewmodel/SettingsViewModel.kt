package com.andernet.weather.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.andernet.weather.data.model.PrecipitationUnit
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.model.WindSpeedUnit
import com.andernet.weather.data.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for settings screen
 * Similar to iOS SettingsManager
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository
) : ViewModel() {
    
    val temperatureUnit: StateFlow<TemperatureUnit> = settingsRepository.temperatureUnit
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = TemperatureUnit.CELSIUS
        )
    
    val windSpeedUnit: StateFlow<WindSpeedUnit> = settingsRepository.windSpeedUnit
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = WindSpeedUnit.KMH
        )
    
    val precipitationUnit: StateFlow<PrecipitationUnit> = settingsRepository.precipitationUnit
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = PrecipitationUnit.MM
        )
    
    val use24HourFormat: StateFlow<Boolean> = settingsRepository.use24HourFormat
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = false
        )
    
    val dailyForecastEnabled: StateFlow<Boolean> = settingsRepository.dailyForecastEnabled
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = false
        )
    
    val rainAlertsEnabled: StateFlow<Boolean> = settingsRepository.rainAlertsEnabled
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = true
        )
    
    fun setTemperatureUnit(unit: TemperatureUnit) {
        viewModelScope.launch {
            settingsRepository.setTemperatureUnit(unit)
        }
    }
    
    fun setWindSpeedUnit(unit: WindSpeedUnit) {
        viewModelScope.launch {
            settingsRepository.setWindSpeedUnit(unit)
        }
    }
    
    fun setPrecipitationUnit(unit: PrecipitationUnit) {
        viewModelScope.launch {
            settingsRepository.setPrecipitationUnit(unit)
        }
    }
    
    fun setUse24HourFormat(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setUse24HourFormat(enabled)
        }
    }
    
    fun setDailyForecastEnabled(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setDailyForecastEnabled(enabled)
        }
    }
    
    fun setRainAlertsEnabled(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setRainAlertsEnabled(enabled)
        }
    }
}
