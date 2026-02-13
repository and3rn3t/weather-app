package com.andernet.weather.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.andernet.weather.data.model.MapLayerType
import com.andernet.weather.data.model.RadarTile
import com.andernet.weather.data.repository.RadarRepository
import com.google.android.gms.maps.model.LatLng
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI state for the Weather Map screen
 */
data class WeatherMapUiState(
    val radarTiles: List<RadarTile> = emptyList(),
    val currentFrameIndex: Int = 0,
    val isPlaying: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null,
    val mapLayerType: MapLayerType = MapLayerType.STANDARD,
    val radarOpacity: Float = 0.7f,
    val centerLocation: LatLng = LatLng(37.7749, -122.4194) // Default to San Francisco
)

/**
 * ViewModel for the Weather Map screen
 */
@HiltViewModel
class WeatherMapViewModel @Inject constructor(
    private val radarRepository: RadarRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(WeatherMapUiState())
    val uiState: StateFlow<WeatherMapUiState> = _uiState.asStateFlow()

    private var playbackJob: kotlinx.coroutines.Job? = null

    init {
        loadRadarTiles()
    }

    /**
     * Load radar tiles from RainViewer
     */
    fun loadRadarTiles() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            radarRepository.getRadarTiles().collect { result ->
                result.fold(
                    onSuccess = { tiles ->
                        _uiState.update {
                            it.copy(
                                radarTiles = tiles,
                                isLoading = false,
                                // Start at the last past frame (most recent)
                                currentFrameIndex = tiles.indexOfLast { tile -> tile.isPast }
                                    .coerceAtLeast(0)
                            )
                        }
                    },
                    onFailure = { exception ->
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                error = exception.message ?: "Failed to load radar data"
                            )
                        }
                    }
                )
            }
        }
    }

    /**
     * Set the center location for the map
     */
    fun setCenterLocation(location: LatLng) {
        _uiState.update { it.copy(centerLocation = location) }
    }

    /**
     * Change the current frame index
     */
    fun setFrameIndex(index: Int) {
        val tiles = _uiState.value.radarTiles
        if (index in tiles.indices) {
            _uiState.update { it.copy(currentFrameIndex = index) }
        }
    }

    /**
     * Toggle playback animation
     */
    fun togglePlayback() {
        if (_uiState.value.isPlaying) {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    /**
     * Start radar animation playback
     */
    private fun startPlayback() {
        playbackJob?.cancel()
        _uiState.update { it.copy(isPlaying = true) }
        
        playbackJob = viewModelScope.launch {
            val tiles = _uiState.value.radarTiles
            if (tiles.isEmpty()) return@launch
            
            while (_uiState.value.isPlaying) {
                val currentIndex = _uiState.value.currentFrameIndex
                val nextIndex = (currentIndex + 1) % tiles.size
                
                _uiState.update { it.copy(currentFrameIndex = nextIndex) }
                
                // Delay between frames (500ms for smooth animation)
                kotlinx.coroutines.delay(500)
            }
        }
    }

    /**
     * Stop radar animation playback
     */
    private fun stopPlayback() {
        playbackJob?.cancel()
        playbackJob = null
        _uiState.update { it.copy(isPlaying = false) }
    }

    /**
     * Change map layer type
     */
    fun setMapLayerType(layerType: MapLayerType) {
        _uiState.update { it.copy(mapLayerType = layerType) }
    }

    /**
     * Adjust radar overlay opacity
     */
    fun setRadarOpacity(opacity: Float) {
        _uiState.update { it.copy(radarOpacity = opacity.coerceIn(0f, 1f)) }
    }

    /**
     * Refresh radar data
     */
    fun refresh() {
        radarRepository.clearCache()
        loadRadarTiles()
    }

    override fun onCleared() {
        super.onCleared()
        stopPlayback()
    }
}
