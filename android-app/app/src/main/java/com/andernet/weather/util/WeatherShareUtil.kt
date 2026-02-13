package com.andernet.weather.util

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.andernet.weather.data.model.CurrentWeather
import com.andernet.weather.data.model.WeatherCondition
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

/**
 * Utility for sharing weather information
 * Supports text and image sharing similar to iOS
 */
object WeatherShareUtil {
    
    /**
     * Share current weather as text
     */
    fun shareWeatherText(
        context: Context,
        locationName: String,
        currentWeather: CurrentWeather,
        temperatureUnit: String = "°F"
    ) {
        val condition = WeatherCondition.fromCode(currentWeather.weatherCode)
        val dateFormat = SimpleDateFormat("EEEE, MMM d 'at' h:mm a", Locale.getDefault())
        val timeString = dateFormat.format(Date())
        
        val shareText = buildString {
            appendLine("🌤️ Weather in $locationName")
            appendLine()
            appendLine("${currentWeather.temperature.toInt()}$temperatureUnit - ${condition.description}")
            appendLine("Feels like ${currentWeather.apparentTemperature.toInt()}$temperatureUnit")
            appendLine()
            appendLine("💨 Wind: ${currentWeather.windSpeed.toInt()} mph")
            appendLine("💧 Humidity: ${currentWeather.humidity}%")
            currentWeather.uvIndex?.let {
                if (it > 0) appendLine("☀️ UV Index: ${it.toInt()}")
            }
            appendLine()
            appendLine("Updated: $timeString")
            appendLine()
            appendLine("Shared from Andernet Weather")
        }
        
        val sendIntent = Intent().apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, shareText)
            type = "text/plain"
        }
        
        val shareIntent = Intent.createChooser(sendIntent, "Share Weather")
        context.startActivity(shareIntent)
    }
    
    /**
     * Share current weather with forecast as detailed text
     */
    fun shareDetailedWeather(
        context: Context,
        locationName: String,
        currentWeather: CurrentWeather,
        dailyHighs: List<Int>,
        dailyLows: List<Int>,
        temperatureUnit: String = "°F"
    ) {
        val condition = WeatherCondition.fromCode(currentWeather.weatherCode)
        val dateFormat = SimpleDateFormat("EEEE, MMM d", Locale.getDefault())
        
        val shareText = buildString {
            appendLine("🌤️ $locationName Weather Report")
            appendLine("=" .repeat(30))
            appendLine()
            
            // Current conditions
            appendLine("CURRENT CONDITIONS")
            appendLine("Temperature: ${currentWeather.temperature.toInt()}$temperatureUnit")
            appendLine("Condition: ${condition.description}")
            appendLine("Feels Like: ${currentWeather.apparentTemperature.toInt()}$temperatureUnit")
            appendLine()
            
            // Details
            appendLine("DETAILS")
            appendLine("Wind: ${currentWeather.windSpeed.toInt()} mph ${getWindDirection(currentWeather.windDirection)}")
            appendLine("Humidity: ${currentWeather.humidity}%")
            appendLine("Pressure: ${currentWeather.pressure.toInt()} mb")
            currentWeather.uvIndex?.let {
                if (it > 0) appendLine("UV Index: ${it.toInt()} - ${getUVLevel(it)}")
            }
            currentWeather.visibility?.let {
                appendLine("Visibility: ${it.toInt()} mi")
            }
            appendLine()
            
            // 7-day forecast
            if (dailyHighs.isNotEmpty() && dailyLows.isNotEmpty()) {
                appendLine("7-DAY FORECAST")
                val calendar = Calendar.getInstance()
                for (i in 0 until minOf(7, dailyHighs.size, dailyLows.size)) {
                    val dayName = if (i == 0) "Today" else dateFormat.format(calendar.time)
                    appendLine("$dayName: H ${dailyHighs[i]}° L ${dailyLows[i]}°")
                    calendar.add(Calendar.DAY_OF_YEAR, 1)
                }
                appendLine()
            }
            
            appendLine("Shared from Andernet Weather")
            appendLine(dateFormat.format(Date()))
        }
        
        val sendIntent = Intent().apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, shareText)
            type = "text/plain"
        }
        
        val shareIntent = Intent.createChooser(sendIntent, "Share Weather Report")
        context.startActivity(shareIntent)
    }
    
    /**
     * Get wind direction name from degrees
     */
    private fun getWindDirection(degrees: Double): String {
        val normalized = ((degrees % 360) + 360) % 360
        return when {
            normalized < 22.5 -> "N"
            normalized < 67.5 -> "NE"
            normalized < 112.5 -> "E"
            normalized < 157.5 -> "SE"
            normalized < 202.5 -> "S"
            normalized < 247.5 -> "SW"
            normalized < 292.5 -> "W"
            normalized < 337.5 -> "NW"
            else -> "N"
        }
    }
    
    /**
     * Get UV index level description
     */
    private fun getUVLevel(uvIndex: Double): String {
        return when {
            uvIndex < 3 -> "Low"
            uvIndex < 6 -> "Moderate"
            uvIndex < 8 -> "High"
            uvIndex < 11 -> "Very High"
            else -> "Extreme"
        }
    }
}

/**
 * Composable weather card for sharing as image
 * Can be rendered to bitmap for image sharing
 */
@Composable
fun ShareableWeatherCard(
    locationName: String,
    currentWeather: CurrentWeather,
    temperatureUnit: String,
    style: WeatherCardStyle = WeatherCardStyle.MODERN
) {
    val condition = WeatherCondition.fromCode(currentWeather.weatherCode)
    
    when (style) {
        WeatherCardStyle.MODERN -> ModernWeatherCard(locationName, currentWeather, temperatureUnit, condition)
        WeatherCardStyle.MINIMAL -> MinimalWeatherCard(locationName, currentWeather, temperatureUnit, condition)
        WeatherCardStyle.DETAILED -> DetailedWeatherCard(locationName, currentWeather, temperatureUnit, condition)
        WeatherCardStyle.GRADIENT -> GradientWeatherCard(locationName, currentWeather, temperatureUnit, condition)
    }
}

enum class WeatherCardStyle {
    MODERN,
    MINIMAL,
    DETAILED,
    GRADIENT
}

@Composable
private fun ModernWeatherCard(
    locationName: String,
    currentWeather: CurrentWeather,
    temperatureUnit: String,
    condition: WeatherCondition
) {
    Card(
        modifier = Modifier
            .width(400.dp)
            .height(250.dp),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF2196F3)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Location
            Text(
                text = locationName,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            
            // Temperature and condition
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "${currentWeather.temperature.toInt()}$temperatureUnit",
                    fontSize = 72.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = condition.description,
                        fontSize = 20.sp,
                        color = Color.White
                    )
                    Text(
                        text = "H:${currentWeather.temperature.toInt() + 3}° L:${currentWeather.temperature.toInt() - 5}°",
                        fontSize = 16.sp,
                        color = Color.White.copy(alpha = 0.8f)
                    )
                }
            }
            
            // App credit
            Text(
                text = "Andernet Weather",
                fontSize = 14.sp,
                color = Color.White.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun MinimalWeatherCard(
    locationName: String,
    currentWeather: CurrentWeather,
    temperatureUnit: String,
    condition: WeatherCondition
) {
    Card(
        modifier = Modifier
            .width(350.dp)
            .height(200.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.White
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = locationName,
                fontSize = 18.sp,
                color = Color.Black,
                fontWeight = FontWeight.Medium
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "${currentWeather.temperature.toInt()}$temperatureUnit",
                fontSize = 64.sp,
                fontWeight = FontWeight.Bold,
                color = Color.Black
            )
            
            Text(
                text = condition.description,
                fontSize = 16.sp,
                color = Color.Gray
            )
        }
    }
}

@Composable
private fun DetailedWeatherCard(
    locationName: String,
    currentWeather: CurrentWeather,
    temperatureUnit: String,
    condition: WeatherCondition
) {
    Card(
        modifier = Modifier
            .width(400.dp)
            .height(300.dp),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF1E1E1E)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp)
        ) {
            // Header
            Text(
                text = locationName,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Main temp
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "${currentWeather.temperature.toInt()}$temperatureUnit",
                    fontSize = 56.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                
                Text(
                    text = condition.description,
                    fontSize = 18.sp,
                    color = Color.White.copy(alpha = 0.9f)
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Details grid
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                WeatherDetail("Feels Like", "${currentWeather.apparentTemperature.toInt()}°")
                WeatherDetail("Wind", "${currentWeather.windSpeed.toInt()} mph")
                WeatherDetail("Humidity", "${currentWeather.humidity}%")
            }
        }
    }
}

@Composable
private fun WeatherDetail(label: String, value: String) {
    Column {
        Text(
            text = label,
            fontSize = 12.sp,
            color = Color.White.copy(alpha = 0.6f)
        )
        Text(
            text = value,
            fontSize = 18.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White
        )
    }
}

@Composable
private fun GradientWeatherCard(
    locationName: String,
    currentWeather: CurrentWeather,
    temperatureUnit: String,
    condition: WeatherCondition
) {
    Card(
        modifier = Modifier
            .width(400.dp)
            .height(250.dp),
        shape = RoundedCornerShape(24.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    androidx.compose.ui.graphics.Brush.verticalGradient(
                        colors = listOf(
                            Color(0xFF667eea),
                            Color(0xFF764ba2)
                        )
                    )
                )
                .padding(32.dp)
        ) {
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = locationName,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                
                Column {
                    Text(
                        text = "${currentWeather.temperature.toInt()}$temperatureUnit",
                        fontSize = 72.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Text(
                        text = condition.description,
                        fontSize = 20.sp,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                }
                
                Text(
                    text = "Andernet Weather",
                    fontSize = 14.sp,
                    color = Color.White.copy(alpha = 0.7f)
                )
            }
        }
    }
}
