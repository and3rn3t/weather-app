package com.andernet.weather.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.andernet.weather.data.model.CurrentWeather
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.model.WeatherCondition
import com.andernet.weather.data.model.WindSpeedUnit
import kotlin.math.roundToInt

/**
 * Card displaying current weather conditions
 */
@Composable
fun CurrentWeatherCard(
    currentWeather: CurrentWeather,
    temperatureUnit: TemperatureUnit,
    windSpeedUnit: WindSpeedUnit,
    modifier: Modifier = Modifier
) {
    val condition = WeatherCondition.fromCode(currentWeather.weatherCode)
    
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Weather icon (placeholder - would use actual icons)
            Text(
                text = getWeatherEmoji(currentWeather.weatherCode),
                fontSize = 72.sp
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Temperature
            Text(
                text = "${currentWeather.temperature.roundToInt()}${temperatureUnit.symbol}",
                style = MaterialTheme.typography.displayLarge,
                fontWeight = FontWeight.Bold
            )
            
            // Feels like
            Text(
                text = "Feels like ${currentWeather.apparentTemperature.roundToInt()}${temperatureUnit.symbol}",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Condition
            Text(
                text = condition.description,
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

/**
 * Grid of weather details (humidity, wind, pressure, etc.)
 */
@Composable
fun WeatherDetailsGrid(
    currentWeather: CurrentWeather,
    windSpeedUnit: WindSpeedUnit,
    precipitationUnit: com.andernet.weather.data.model.PrecipitationUnit,
    modifier: Modifier = Modifier
) {
    Card(modifier = modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Details",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            
            // 2 column grid
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    WeatherDetailItem(
                        label = "Humidity",
                        value = "${currentWeather.humidity}%",
                        modifier = Modifier.weight(1f)
                    )
                    WeatherDetailItem(
                        label = "Wind",
                        value = "${currentWeather.windSpeed.roundToInt()} ${windSpeedUnit.symbol}",
                        modifier = Modifier.weight(1f)
                    )
                }
                
                Spacer(modifier = Modifier.height(12.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    WeatherDetailItem(
                        label = "Pressure",
                        value = "${currentWeather.pressure.roundToInt()} hPa",
                        modifier = Modifier.weight(1f)
                    )
                    currentWeather.visibility?.let { visibility ->
                        WeatherDetailItem(
                            label = "Visibility",
                            value = "${(visibility / 1000).roundToInt()} km",
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(12.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    currentWeather.uvIndex?.let { uv ->
                        val uvCategory =  com.andernet.weather.data.model.UVIndexCategory.fromValue(uv)
                        WeatherDetailItem(
                            label = "UV Index",
                            value = "${uv.roundToInt()} (${uvCategory.description})",
                            modifier = Modifier.weight(1f)
                        )
                    }
                    WeatherDetailItem(
                        label = "Cloud Cover",
                        value = "${currentWeather.cloudCover}%",
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@Composable
fun WeatherDetailItem(
    label: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium
        )
    }
}

/**
 * Get emoji representation of weather (temporary until actual icons)
 */
fun getWeatherEmoji(code: Int): String {
    return when (WeatherCondition.fromCode(code)) {
        WeatherCondition.CLEAR -> "☀️"
        WeatherCondition.PARTLY_CLOUDY -> "⛅"
        WeatherCondition.CLOUDY -> "☁️"
        WeatherCondition.OVERCAST -> "🌫️"
        WeatherCondition.DRIZZLE -> "🌦️"
        WeatherCondition.RAIN, WeatherCondition.RAIN_SHOWERS -> "🌧️"
        WeatherCondition.SNOW, WeatherCondition.SNOW_SHOWERS -> "🌨️"
        WeatherCondition.THUNDERSTORM -> "⛈️"
    }
}
