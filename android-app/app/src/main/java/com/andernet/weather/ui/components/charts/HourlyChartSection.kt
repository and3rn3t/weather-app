package com.andernet.weather.ui.components.charts

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.andernet.weather.data.model.HourlyWeatherData
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.model.WindSpeedUnit

/**
 * Chart types available for hourly data visualization
 */
enum class ChartType {
    TEMPERATURE,
    PRECIPITATION,
    UV_INDEX,
    WIND_SPEED,
    HUMIDITY;
    
    fun getDisplayName(): String = when (this) {
        TEMPERATURE -> "Temperature"
        PRECIPITATION -> "Precipitation"
        UV_INDEX -> "UV Index"
        WIND_SPEED -> "Wind Speed"
        HUMIDITY -> "Humidity"
    }
}

/**
 * Interactive chart selector with multiple chart types
 */
@Composable
fun HourlyChartSection(
    hourlyData: List<HourlyWeatherData>,
    temperatureUnit: TemperatureUnit,
    windSpeedUnit: WindSpeedUnit,
    modifier: Modifier = Modifier
) {
    var selectedChartType by remember { mutableStateOf(ChartType.TEMPERATURE) }
    
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Chart type selector
            Text(
                text = "Hourly Trends",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(bottom = 12.dp)
            )
            
            // Segmented control for chart type
            ChartTypeSelector(
                selectedType = selectedChartType,
                onTypeSelected = { selectedChartType = it },
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Display selected chart
            when (selectedChartType) {
                ChartType.TEMPERATURE -> TemperatureChart(
                    hourlyData = hourlyData,
                    temperatureUnit = temperatureUnit
                )
                ChartType.PRECIPITATION -> PrecipitationChart(
                    hourlyData = hourlyData
                )
                ChartType.UV_INDEX -> UVIndexChart(
                    hourlyData = hourlyData
                )
                ChartType.WIND_SPEED -> WindSpeedChart(
                    hourlyData = hourlyData,
                    windSpeedUnit = windSpeedUnit
                )
                ChartType.HUMIDITY -> HumidityChart(
                    hourlyData = hourlyData
                )
            }
        }
    }
}

/**
 * Scrollable horizontal chart type selector
 */
@Composable
fun ChartTypeSelector(
    selectedType: ChartType,
    onTypeSelected: (ChartType) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        ChartType.entries.forEach { chartType ->
            FilterChip(
                selected = chartType == selectedType,
                onClick = { onTypeSelected(chartType) },
                label = {
                    Text(
                        text = chartType.getDisplayName(),
                        style = MaterialTheme.typography.labelMedium
                    )
                },
                modifier = Modifier.weight(1f, fill = false)
            )
        }
    }
}
