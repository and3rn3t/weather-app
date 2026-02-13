package com.andernet.weather.ui.screen

import android.Manifest
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.andernet.weather.ui.components.CurrentWeatherCard
import com.andernet.weather.ui.components.DailyForecastSection
import com.andernet.weather.ui.components.HourlyForecastSection
import com.andernet.weather.ui.components.WeatherDetailsGrid
import com.andernet.weather.ui.viewmodel.MainViewModel
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.accompanist.permissions.shouldShowRationale
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState

/**
 * Home screen showing current weather and forecasts
 */
@OptIn(ExperimentalPermissionsApi::class, ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    viewModel: MainViewModel = hiltViewModel(),
    onNavigateToSearch: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val locationPermissionState = rememberPermissionState(Manifest.permission.ACCESS_COARSE_LOCATION)
    
    // Request location permission on first composition
    LaunchedEffect(Unit) {
        if (!locationPermissionState.status.isGranted) {
            locationPermissionState.launchPermissionRequest()
        }
    }
    
    // Check if permission granted
    val permissionGranted = locationPermissionState.status.isGranted
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.LocationOn,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = uiState.location?.displayName ?: "Loading...",
                            style = MaterialTheme.typography.titleMedium
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.refresh() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        }
    ) { padding ->
        if (!permissionGranted) {
            // Show permission request UI
            LocationPermissionScreen(
                onRequestPermission = { locationPermissionState.launchPermissionRequest() },
                shouldShowRationale = locationPermissionState.status.shouldShowRationale,
                modifier = Modifier.padding(padding)
            )
        } else {
            // Show weather content
            SwipeRefresh(
                state = rememberSwipeRefreshState(uiState.isRefreshing),
                onRefresh = { viewModel.refresh() },
                modifier = Modifier.padding(padding)
            ) {
                when {
                    uiState.isLoading && uiState.weatherData == null -> {
                        LoadingScreen()
                    }
                    uiState.error != null && uiState.weatherData == null -> {
                        ErrorScreen(
                            error = uiState.error!!,
                            onRetry = { viewModel.retry() }
                        )
                    }
                    uiState.weatherData != null -> {
                        WeatherContent(
                            viewModel = viewModel,
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun LocationPermissionScreen(
    onRequestPermission: () -> Unit,
    shouldShowRationale: Boolean,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                Icons.Default.LocationOn,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "Location Permission Required",
                style = MaterialTheme.typography.headlineSmall,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = if (shouldShowRationale) {
                    "We need location access to show you weather for your current location"
                } else {
                    "Grant location permission to see weather for your area"
                },
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(24.dp))
            Button(onClick = onRequestPermission) {
                Text("Grant Permission")
            }
        }
    }
}

@Composable
fun LoadingScreen(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}

@Composable
fun ErrorScreen(
    error: com.andernet.weather.data.model.WeatherError,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(32.dp)
        ) {
            Text(
                text = error.message ?: "An error occurred",
                style = MaterialTheme.typography.titleMedium,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.error
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = error.recoverySuggestion,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(24.dp))
            Button(onClick = onRetry) {
                Text("Retry")
            }
        }
    }
}

@Composable
fun WeatherContent(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val weatherData = uiState.weatherData ?: return
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        // Offline indicator
        if (uiState.isOffline) {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "Offline - Showing cached data",
                    modifier = Modifier.padding(12.dp),
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
        
        // Current weather
        weatherData.current?.let { current ->
            CurrentWeatherCard(
                currentWeather = current,
                temperatureUnit = uiState.temperatureUnit,
                windSpeedUnit = uiState.windSpeedUnit
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Weather details grid
        weatherData.current?.let { current ->
            WeatherDetailsGrid(
                currentWeather = current,
                windSpeedUnit = uiState.windSpeedUnit,
                precipitationUnit = uiState.precipitationUnit
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Hourly forecast
        val hourlyForecast = viewModel.getHourlyForecast(24)
        if (hourlyForecast.isNotEmpty()) {
            HourlyForecastSection(
                hourlyForecast = hourlyForecast,
                temperatureUnit = uiState.temperatureUnit
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Daily forecast
        val dailyForecast = viewModel.getDailyForecast()
        if (dailyForecast.isNotEmpty()) {
            DailyForecastSection(
                dailyForecast = dailyForecast,
                temperatureUnit = uiState.temperatureUnit
            )
        }
    }
}
