package com.andernet.weather.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.andernet.weather.data.model.LocationData
import com.andernet.weather.data.model.WeatherError
import com.andernet.weather.data.repository.LocationRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI State for location search
 */
data class SearchUiState(
    val query: String = "",
    val results: List<LocationData> = emptyList(),
    val isLoading: Boolean = false,
    val error: WeatherError? = null
)

/**
 * ViewModel for location search
 */
@HiltViewModel
class SearchViewModel @Inject constructor(
    private val locationRepository: LocationRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()
    
    /**
     * Update search query
     */
    fun updateQuery(query: String) {
        _uiState.update { it.copy(query = query) }
    }
    
    /**
     * Search for locations
     */
    fun search(query: String) {
        if (query.isBlank()) {
            _uiState.update { it.copy(results = emptyList(), error = null) }
            return
        }
        
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            locationRepository.searchLocation(query)
                .onSuccess { locations ->
                    _uiState.update {
                        it.copy(
                            results = locations,
                            isLoading = false,
                            error = null
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            results = emptyList(),
                            isLoading = false,
                            error = error as? WeatherError ?: WeatherError.fromThrowable(error)
                        )
                    }
                }
        }
    }
    
    /**
     * Clear search results
     */
    fun clearSearch() {
        _uiState.update { SearchUiState() }
    }
}
