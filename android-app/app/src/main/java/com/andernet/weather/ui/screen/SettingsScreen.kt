package com.andernet.weather.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.andernet.weather.data.model.PrecipitationUnit
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.model.WindSpeedUnit
import com.andernet.weather.ui.viewmodel.SettingsViewModel

/**
 * Settings screen for user preferences
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val temperatureUnit by viewModel.temperatureUnit.collectAsStateWithLifecycle()
    val windSpeedUnit by viewModel.windSpeedUnit.collectAsStateWithLifecycle()
    val precipitationUnit by viewModel.precipitationUnit.collectAsStateWithLifecycle()
    val use24HourFormat by viewModel.use24HourFormat.collectAsStateWithLifecycle()
    val dailyForecastEnabled by viewModel.dailyForecastEnabled.collectAsStateWithLifecycle()
    val rainAlertsEnabled by viewModel.rainAlertsEnabled.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Units Section
            Text(
                text = "Units",
                style = MaterialTheme.typography.titleLarge
            )

            Card {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Temperature Unit
                    SettingDropdown(
                        label = "Temperature",
                        options = TemperatureUnit.values().toList(),
                        selectedOption = temperatureUnit,
                        onOptionSelected = { viewModel.setTemperatureUnit(it) },
                        optionLabel = { "${it.name} (${it.symbol})" }
                    )

                    HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                    // Wind Speed Unit
                    SettingDropdown(
                        label = "Wind Speed",
                        options = WindSpeedUnit.values().toList(),
                        selectedOption = windSpeedUnit,
                        onOptionSelected = { viewModel.setWindSpeedUnit(it) },
                        optionLabel = { it.symbol }
                    )

                    HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                    // Precipitation Unit
                    SettingDropdown(
                        label = "Precipitation",
                        options = PrecipitationUnit.values().toList(),
                        selectedOption = precipitationUnit,
                        onOptionSelected = { viewModel.setPrecipitationUnit(it) },
                        optionLabel = { it.symbol }
                    )
                }
            }

            // Display Section
            Text(
                text = "Display",
                style = MaterialTheme.typography.titleLarge
            )

            Card {
                Column(modifier = Modifier.padding(16.dp)) {
                    SettingSwitch(
                        label = "24-hour format",
                        checked = use24HourFormat,
                        onCheckedChange = { viewModel.setUse24HourFormat(it) }
                    )
                }
            }

            // Notifications Section
            Text(
                text = "Notifications",
                style = MaterialTheme.typography.titleLarge
            )

            Card {
                Column(modifier = Modifier.padding(16.dp)) {
                    SettingSwitch(
                        label = "Daily forecast",
                        description = "Receive daily weather updates",
                        checked = dailyForecastEnabled,
                        onCheckedChange = { viewModel.setDailyForecastEnabled(it) }
                    )

                    HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                    SettingSwitch(
                        label = "Rain alerts",
                        description = "Get notified when rain is expected",
                        checked = rainAlertsEnabled,
                        onCheckedChange = { viewModel.setRainAlertsEnabled(it) }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun <T> SettingDropdown(
    label: String,
    options: List<T>,
    selectedOption: T,
    onOptionSelected: (T) -> Unit,
    optionLabel: (T) -> String
) {
    var expanded by remember { mutableStateOf(false) }

    Column {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(4.dp))

        ExposedDropdownMenuBox(
            expanded = expanded,
            onExpandedChange = { expanded = it }
        ) {
            OutlinedTextField(
                value = optionLabel(selectedOption),
                onValueChange = {},
                readOnly = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor(),
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) }
            )

            ExposedDropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                options.forEach { option ->
                    DropdownMenuItem(
                        text = { Text(optionLabel(option)) },
                        onClick = {
                            onOptionSelected(option)
                            expanded = false
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun SettingSwitch(
    label: String,
    description: String? = null,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = label,
                style = MaterialTheme.typography.bodyLarge
            )
            description?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}
