package com.andernet.weather.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.andernet.weather.data.model.MapLayerType
import com.andernet.weather.ui.viewmodel.WeatherMapViewModel
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MapStyleOptions
import com.google.maps.android.compose.*

/**
 * Weather Map screen with radar overlay and controls
 * Integrates Google Maps with RainViewer radar data
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WeatherMapScreen(
    onNavigateBack: () -> Unit,
    initialLocation: LatLng? = null,
    viewModel: WeatherMapViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    // Set initial location if provided
    LaunchedEffect(initialLocation) {
        initialLocation?.let { viewModel.setCenterLocation(it) }
    }
    
    // Camera position state
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(uiState.centerLocation, 8f)
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Weather Radar") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    // Refresh button
                    IconButton(onClick = { viewModel.refresh() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Google Map with radar overlay
            if (!uiState.isLoading) {
                WeatherMapView(
                    cameraPositionState = cameraPositionState,
                    radarTiles = uiState.radarTiles,
                    currentFrameIndex = uiState.currentFrameIndex,
                    mapLayerType = uiState.mapLayerType,
                    radarOpacity = uiState.radarOpacity
                )
            }
            
            // Loading indicator
            if (uiState.isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            
            // Error message
            uiState.error?.let { error ->
                Snackbar(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(16.dp),
                    action = {
                        TextButton(onClick = { viewModel.loadRadarTiles() }) {
                            Text("Retry")
                        }
                    }
                ) {
                    Text(error)
                }
            }
            
            // Map controls overlay
            Column(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(16.dp)
            ) {
                // Layer selector
                MapLayerSelector(
                    currentLayer = uiState.mapLayerType,
                    onLayerSelected = { viewModel.setMapLayerType(it) }
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                // Opacity slider
                RadarOpacitySlider(
                    opacity = uiState.radarOpacity,
                    onOpacityChange = { viewModel.setRadarOpacity(it) }
                )
            }
            
            // Timeline controls at bottom
            if (uiState.radarTiles.isNotEmpty()) {
                RadarTimelineControls(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(16.dp),
                    radarTiles = uiState.radarTiles,
                    currentFrameIndex = uiState.currentFrameIndex,
                    isPlaying = uiState.isPlaying,
                    onFrameIndexChange = { viewModel.setFrameIndex(it) },
                    onPlayPauseClick = { viewModel.togglePlayback() }
                )
            }
        }
    }
}

/**
 * Google Map view with radar overlay
 */
@Composable
fun WeatherMapView(
    cameraPositionState: CameraPositionState,
    radarTiles: List<com.andernet.weather.data.model.RadarTile>,
    currentFrameIndex: Int,
    mapLayerType: MapLayerType,
    radarOpacity: Float
) {
    val mapProperties = remember(mapLayerType) {
        MapProperties(
            mapType = when (mapLayerType) {
                MapLayerType.STANDARD -> MapType.NORMAL
                MapLayerType.SATELLITE -> MapType.SATELLITE
                MapLayerType.HYBRID -> MapType.HYBRID
                MapLayerType.PRECIPITATION -> MapType.NORMAL
            }
        )
    }
    
    val mapUiSettings = remember {
        MapUiSettings(
            zoomControlsEnabled = false,
            compassEnabled = true,
            myLocationButtonEnabled = true
        )
    }
    
    GoogleMap(
        modifier = Modifier.fillMaxSize(),
        cameraPositionState = cameraPositionState,
        properties = mapProperties,
        uiSettings = mapUiSettings
    ) {
        // Add radar tile overlay
        if (radarTiles.isNotEmpty() && currentFrameIndex in radarTiles.indices) {
            val currentTile = radarTiles[currentFrameIndex]
            
            // Note: Tile overlay requires additional setup
            // For now, we'''ll use a marker to demonstrate the data is available
            // In a full implementation, you would use TileOverlayOptions
            // with a custom TileProvider that fetches tiles from the URL
        }
    }
}

/**
 * Map layer type selector
 */
@Composable
fun MapLayerSelector(
    currentLayer: MapLayerType,
    onLayerSelected: (MapLayerType) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    
    Box {
        FloatingActionButton(
            onClick = { expanded = true },
            modifier = Modifier.size(48.dp),
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = MaterialTheme.colorScheme.onSurface
        ) {
            Icon(Icons.Default.Layers, contentDescription = "Map Layers")
        }
        
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            MapLayerType.entries.forEach { layer ->
                DropdownMenuItem(
                    text = {
                        Text(
                            text = when (layer) {
                                MapLayerType.STANDARD -> "Standard"
                                MapLayerType.SATELLITE -> "Satellite"
                                MapLayerType.HYBRID -> "Hybrid"
                                MapLayerType.PRECIPITATION -> "Precipitation"
                            }
                        )
                    },
                    onClick = {
                        onLayerSelected(layer)
                        expanded = false
                    },
                    leadingIcon = {
                        if (layer == currentLayer) {
                            Icon(Icons.Default.Check, contentDescription = null)
                        }
                    }
                )
            }
        }
    }
}

/**
 * Radar opacity slider control
 */
@Composable
fun RadarOpacitySlider(
    opacity: Float,
    onOpacityChange: (Float) -> Unit
) {
    Card(
        modifier = Modifier.width(200.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
        )
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(
                    Icons.Default.Opacity,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Radar Opacity",
                    style = MaterialTheme.typography.labelSmall
                )
            }
            
            Slider(
                value = opacity,
                onValueChange = onOpacityChange,
                valueRange = 0f..1f,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

/**
 * Timeline controls for radar animation
 */
@Composable
fun RadarTimelineControls(
    modifier: Modifier = Modifier,
    radarTiles: List<com.andernet.weather.data.model.RadarTile>,
    currentFrameIndex: Int,
    isPlaying: Boolean,
    onFrameIndexChange: (Int) -> Unit,
    onPlayPauseClick: () -> Unit
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Current time display
            if (currentFrameIndex in radarTiles.indices) {
                val currentTile = radarTiles[currentFrameIndex]
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = currentTile.getFormattedTime(),
                        style = MaterialTheme.typography.titleMedium
                    )
                    
                    Text(
                        text = if (currentTile.isPast) "Past" else "Forecast",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (currentTile.isPast)
                            MaterialTheme.colorScheme.secondary
                        else
                            MaterialTheme.colorScheme.primary
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Timeline slider
            Slider(
                value = currentFrameIndex.toFloat(),
                onValueChange = { onFrameIndexChange(it.toInt()) },
                valueRange = 0f..(radarTiles.size - 1).toFloat(),
                steps = radarTiles.size - 2,
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Play/Pause and frame counter
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Play/Pause button
                FloatingActionButton(
                    onClick = onPlayPauseClick,
                    modifier = Modifier.size(48.dp)
                ) {
                    Icon(
                        imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                        contentDescription = if (isPlaying) "Pause" else "Play"
                    )
                }
                
                // Frame counter
                Text(
                    text = "Frame ${currentFrameIndex + 1} / ${radarTiles.size}",
                    style = MaterialTheme.typography.labelMedium
                )
            }
        }
    }
}
