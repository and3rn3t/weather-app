package com.andernet.weather.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.andernet.weather.data.local.SavedLocation
import com.andernet.weather.data.model.LocationData
import com.andernet.weather.data.repository.FavoritesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI State for favorites screen
 */
data class FavoritesUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val successMessage: String? = null
)

/**
 * ViewModel for managing saved/favorite locations
 * Similar to iOS FavoritesManager
 */
@HiltViewModel
class FavoritesViewModel @Inject constructor(
    private val favoritesRepository: FavoritesRepository
) : ViewModel() {
    
    // Reactive Flow of saved locations
    val savedLocations: StateFlow<List<SavedLocation>> = favoritesRepository.getAllLocations()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )
    
    private val _uiState = MutableStateFlow(FavoritesUiState())
    val uiState: StateFlow<FavoritesUiState> = _uiState.asStateFlow()
    
    /**
     * Add a location to favorites
     */
    fun addFavorite(location: LocationData) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            val savedLocation = SavedLocation(
                latitude = location.latitude,
                longitude = location.longitude,
                cityName = location.cityName,
                stateName = location.stateName,
                countryName = location.countryName
            )
            
            favoritesRepository.addLocation(savedLocation)
                .onSuccess {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            successMessage = "Location saved"
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to save location"
                        )
                    }
                }
        }
    }
    
    /**
     * Remove a location from favorites
     */
    fun removeFavorite(location: SavedLocation) {
        viewModelScope.launch {
            favoritesRepository.removeLocation(location)
                .onSuccess {
                    _uiState.update { it.copy(successMessage = "Location removed") }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(error = error.message ?: "Failed to remove location") }
                }
        }
    }
    
    /**
     * Check if a location is saved
     */
    suspend fun isLocationSaved(latitude: Double, longitude: Double): Boolean {
        return favoritesRepository.isLocationSaved(latitude, longitude)
    }
    
    /**
     * Clear success/error messages
     */
    fun clearMessages() {
        _uiState.update { it.copy(error = null, successMessage = null) }
    }
}
