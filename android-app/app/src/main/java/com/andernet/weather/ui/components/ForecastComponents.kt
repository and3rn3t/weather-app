package com.andernet.weather.ui.components

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.andernet.weather.data.model.DailyForecastItem
import com.andernet.weather.data.model.HourlyForecastItem
import com.andernet.weather.data.model.TemperatureUnit
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import kotlin.math.roundToInt

/**
 * Horizontal scrolling hourly forecast
 */
@Composable
fun HourlyForecastSection(
    hourlyForecast: List<HourlyForecastItem>,
    temperatureUnit: TemperatureUnit,
    modifier: Modifier = Modifier
) {
    Card(modifier = modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Hourly Forecast",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                hourlyForecast.forEach { item ->
                    HourlyForecastItem(
                        item = item,
                        temperatureUnit = temperatureUnit
                    )
                }
            }
        }
    }
}

@Composable
fun HourlyForecastItem(
    item: HourlyForecastItem,
    temperatureUnit: TemperatureUnit
) {
    val time = try {
        val dateTime = LocalDateTime.parse(item.time)
        dateTime.format(DateTimeFormatter.ofPattern("HH:mm"))
    } catch (e: Exception) {
        item.time.substring(11, 16)
    }
    
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(60.dp)
    ) {
        Text(
            text = time,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = getWeatherEmoji(item.weatherCode),
            fontSize = 24.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = "${item.temperature.roundToInt()}°",
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
        
        if (item.precipitationProbability > 0) {
            Text(
                text = "${item.precipitationProbability}%",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

/**
 * 14-day daily forecast list
 */
@Composable
fun DailyForecastSection(
    dailyForecast: List<DailyForecastItem>,
    temperatureUnit: TemperatureUnit,
    modifier: Modifier = Modifier
) {
    Card(modifier = modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "14-Day Forecast",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                dailyForecast.forEach { item ->
                    DailyForecastItem(
                        item = item,
                        temperatureUnit = temperatureUnit
                    )
                }
            }
        }
    }
}

@Composable
fun DailyForecastItem(
    item: DailyForecastItem,
    temperatureUnit: TemperatureUnit
) {
    val dayName = try {
        val date = LocalDateTime.parse(item.date + "T00:00:00")
        date.format(DateTimeFormatter.ofPattern("EEE, MMM d"))
    } catch (e: Exception) {
        item.date
    }
    
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Date
        Text(
            text = dayName,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(1f)
        )
        
        // Weather icon
        Text(
            text = getWeatherEmoji(item.weatherCode),
            fontSize = 24.sp,
            modifier = Modifier.padding(horizontal = 8.dp)
        )
        
        // Precipitation
        if (item.precipitationProbability > 0) {
            Text(
                text = "${item.precipitationProbability}%",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.width(40.dp)
            )
        } else {
            Spacer(modifier = Modifier.width(40.dp))
        }
        
        // Temperature range
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.width(80.dp)
        ) {
            Text(
                text = "${item.temperatureMin.roundToInt()}°",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "${item.temperatureMax.roundToInt()}°",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
