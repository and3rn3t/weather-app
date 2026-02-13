package com.andernet.weather.ui.screen

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.andernet.weather.data.model.LocationData
import com.andernet.weather.ui.viewmodel.MainViewModel
import com.andernet.weather.ui.viewmodel.SearchViewModel

/**
 * Search screen for finding locations
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    searchViewModel: SearchViewModel = hiltViewModel(),
    mainViewModel: MainViewModel = hiltViewModel()
) {
    val searchUiState by searchViewModel.uiState.collectAsStateWithLifecycle()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Search Location") }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            // Search bar
            OutlinedTextField(
                value = searchUiState.query,
                onValueChange = { searchViewModel.updateQuery(it) },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Enter city name...") },
                leadingIcon = {
                    Icon(Icons.Default.Search, contentDescription = "Search")
                },
                trailingIcon = {
                    if (searchUiState.query.isNotEmpty()) {
                        IconButton(onClick = { searchViewModel.clearSearch() }) {
                            Icon(Icons.Default.Close, contentDescription = "Clear")
                        }
                    }
                },
                singleLine = true
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Search button
            Button(
                onClick = { searchViewModel.search(searchUiState.query) },
                modifier = Modifier.fillMaxWidth(),
                enabled = searchUiState.query.isNotBlank() && !searchUiState.isLoading
            ) {
                if (searchUiState.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("Search")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Results
            when {
                searchUiState.isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                searchUiState.error != null -> {
                    Text(
                        text = searchUiState.error!!.message ?: "Error",
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(16.dp)
                    )
                }
                searchUiState.results.isNotEmpty() -> {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(searchUiState.results) { location ->
                            LocationResultItem(
                                location = location,
                                onClick = {
                                    mainViewModel.loadWeatherForLocation(location)
                                }
                            )
                        }
                    }
                }
                searchUiState.query.isNotEmpty() && searchUiState.results.isEmpty() -> {
                    Text(
                        text = "No results found",
                        modifier = Modifier.padding(16.dp),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
fun LocationResultItem(
    location: LocationData,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
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
    }
}
