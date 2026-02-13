package com.andernet.weather.ui.screen

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.andernet.weather.ui.viewmodel.FavoritesViewModel
import com.andernet.weather.ui.viewmodel.MainViewModel

/**
 * Favorites/saved locations screen
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavoritesScreen(
    favoritesViewModel: FavoritesViewModel = hiltViewModel(),
    mainViewModel: MainViewModel = hiltViewModel()
) {
    val savedLocations by favoritesViewModel.savedLocations.collectAsStateWithLifecycle()
    val uiState by favoritesViewModel.uiState.collectAsStateWithLifecycle()
    
    // Show snackbar for messages
    val snackbarHostState = remember { SnackbarHostState() }
    
    LaunchedEffect(uiState.error, uiState.successMessage) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            favoritesViewModel.clearMessages()
        }
        uiState.successMessage?.let {
            snackbarHostState.showSnackbar(it)
            favoritesViewModel.clearMessages()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Saved Locations") }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        if (savedLocations.isEmpty()) {
            // Empty state
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(32.dp)
                ) {
                    Text(
                        text = "No saved locations",
                        style = MaterialTheme.typography.titleMedium,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Search for a location and add it to favorites",
                        style = MaterialTheme.typography.bodyMedium,
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            // List of saved locations
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(
                    items = savedLocations,
                    key = { it.id }
                ) { location ->
                    FavoriteLocationItem(
                        location = location,
                        onClick = {
                            mainViewModel.loadWeatherForLocation(
                                com.andernet.weather.data.model.LocationData(
                                    latitude = location.latitude,
                                    longitude = location.longitude,
                                    cityName = location.cityName,
                                    stateName = location.stateName,
                                    countryName = location.countryName
                                )
                            )
                        },
                        onDelete = {
                            favoritesViewModel.removeFavorite(location)
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun FavoriteLocationItem(
    location: com.andernet.weather.data.local.SavedLocation,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = location.displayName,
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = "${location.latitude}, ${location.longitude}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            IconButton(onClick = onDelete) {
                Icon(
                    Icons.Default.Delete,
                    contentDescription = "Delete",
                    tint = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}
