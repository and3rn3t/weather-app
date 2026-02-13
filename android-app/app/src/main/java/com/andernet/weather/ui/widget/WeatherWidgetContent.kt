package com.andernet.weather.ui.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.andernet.weather.MainActivity
import com.andernet.weather.data.model.CurrentWeather
import com.andernet.weather.data.model.HourlyForecastItem
import com.andernet.weather.data.model.TemperatureUnit
import com.andernet.weather.data.model.WeatherCondition

/**
 * Small weather widget content (2x2)
 * Displays: Current temp, condition icon, location
 */
@Composable
fun SmallWidgetContent(
    locationName: String,
    currentWeather: CurrentWeather?,
    temperatureUnit: TemperatureUnit
) {
    val condition = currentWeather?.let { WeatherCondition.fromCode(it.weatherCode) }
    val context = LocalContext.current
    
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ImageProvider(android.R.drawable.screen_background_dark))
            .padding(12.dp)
            .clickable(actionStartActivity(Intent(context, MainActivity::class.java))),
        contentAlignment = Alignment.Center
    ) {
        if (currentWeather != null) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Temperature
                Text(
                    text = "${currentWeather.temperature.toInt()}°",
                    style = TextStyle(
                        fontSize = 36.sp,
                        fontWeight = FontWeight.Bold,
                        color = ColorProvider(android.R.color.white)
                    )
                )
                
                Spacer(modifier = GlanceModifier.height(4.dp))
                
                // Condition
                Text(
                    text = condition?.description ?: "Clear",
                    style = TextStyle(
                        fontSize = 12.sp,
                        color = ColorProvider(android.R.color.white)
                    )
                )
                
                Spacer(modifier = GlanceModifier.height(2.dp))
                
                // Location
                Text(
                    text = locationName,
                    style = TextStyle(
                        fontSize = 10.sp,
                        color = ColorProvider(android.R.color.white)
                    ),
                    maxLines = 1
                )
            }
        } else {
            Text(
                text = "Loading...",
                style = TextStyle(
                    fontSize = 14.sp,
                    color = ColorProvider(android.R.color.white)
                )
            )
        }
    }
}

/**
 * Medium weather widget content (4x2)
 * Displays: Weather + key stats (feels like, wind, humidity)
 */
@Composable
fun MediumWidgetContent(
    locationName: String,
    currentWeather: CurrentWeather?,
    temperatureUnit: TemperatureUnit
) {
    val condition = currentWeather?.let { WeatherCondition.fromCode(it.weatherCode) }
    val context = LocalContext.current
    
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ImageProvider(android.R.drawable.screen_background_dark))
            .padding(16.dp)
            .clickable(actionStartActivity(Intent(context, MainActivity::class.java)))
    ) {
        if (currentWeather != null) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Left: Temperature and condition
                Column(
                    modifier = GlanceModifier.defaultWeight(),
                    horizontalAlignment = Alignment.Start
                ) {
                    Text(
                        text = locationName,
                        style = TextStyle(
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium,
                            color = ColorProvider(android.R.color.white)
                        ),
                        maxLines = 1
                    )
                    
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    
                    Text(
                        text = "${currentWeather.temperature.toInt()}°",
                        style = TextStyle(
                            fontSize = 40.sp,
                            fontWeight = FontWeight.Bold,
                            color = ColorProvider(android.R.color.white)
                        )
                    )
                    
                    Text(
                        text = condition?.description ?: "Clear",
                        style = TextStyle(
                            fontSize = 12.sp,
                            color = ColorProvider(android.R.color.white)
                        )
                    )
                }
                
                Spacer(modifier = GlanceModifier.width(16.dp))
                
                // Right: Stats
                Column(
                    modifier = GlanceModifier.defaultWeight(),
                    horizontalAlignment = Alignment.Start,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    StatRow("Feels", "${currentWeather.apparentTemperature.toInt()}°")
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    StatRow("Wind", "${currentWeather.windSpeed.toInt()} mph")
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    StatRow("Humidity", "${currentWeather.humidity}%")
                }
            }
        } else {
            Text(
                text = "Loading weather...",
                style = TextStyle(
                    fontSize = 14.sp,
                    color = ColorProvider(android.R.color.white)
                )
            )
        }
    }
}

/**
 * Large weather widget content (4x3)
 * Displays: Weather + 6-hour mini forecast
 */
@Composable
fun LargeWidgetContent(
    locationName: String,
    currentWeather: CurrentWeather?,
    hourlyForecast: List<HourlyForecastItem>,
    temperatureUnit: TemperatureUnit
) {
    val condition = currentWeather?.let { WeatherCondition.fromCode(it.weatherCode) }
    val context = LocalContext.current
    
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ImageProvider(android.R.drawable.screen_background_dark))
            .padding(16.dp)
            .clickable(actionStartActivity(Intent(context, MainActivity::class.java)))
    ) {
        if (currentWeather != null) {
            Column(modifier = GlanceModifier.fillMaxSize()) {
                // Header: Location and current weather
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = GlanceModifier.defaultWeight()) {
                        Text(
                            text = locationName,
                            style = TextStyle(
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Medium,
                                color = ColorProvider(android.R.color.white)
                            ),
                            maxLines = 1
                        )
                        
                        Text(
                            text = "${currentWeather.temperature.toInt()}°",
                            style = TextStyle(
                                fontSize = 36.sp,
                                fontWeight = FontWeight.Bold,
                                color = ColorProvider(android.R.color.white)
                            )
                        )
                    }
                    
                    Column(
                        modifier = GlanceModifier.defaultWeight(),
                        horizontalAlignment = Alignment.End
                    ) {
                        Text(
                            text = condition?.description ?: "Clear",
                            style = TextStyle(
                                fontSize = 14.sp,
                                color = ColorProvider(android.R.color.white)
                            )
                        )
                        
                        Text(
                            text = "H: ${currentWeather.temperature.toInt()}° L: ${currentWeather.apparentTemperature.toInt()}°",
                            style = TextStyle(
                                fontSize = 11.sp,
                                color = ColorProvider(android.R.color.white)
                            )
                        )
                    }
                }
                
                Spacer(modifier = GlanceModifier.height(12.dp))
                
                // Hourly forecast (6 hours)
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.Start
                ) {
                    hourlyForecast.take(6).forEach { hour ->
                        HourlyItem(hour, temperatureUnit)
                        if (hour != hourlyForecast.take(6).last()) {
                            Spacer(modifier = GlanceModifier.width(8.dp))
                        }
                    }
                }
            }
        } else {
            Text(
                text = "Loading weather...",
                style = TextStyle(
                    fontSize = 14.sp,
                    color = ColorProvider(android.R.color.white)
                )
            )
        }
    }
}

/**
 * Helper: Stat row for medium widget
 */
@Composable
private fun StatRow(label: String, value: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = GlanceModifier.fillMaxWidth()
    ) {
        Text(
            text = label,
            style = TextStyle(
                fontSize = 11.sp,
                color = ColorProvider(android.R.color.white)
            ),
            modifier = GlanceModifier.defaultWeight()
        )
        Text(
            text = value,
            style = TextStyle(
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                color = ColorProvider(android.R.color.white)
            )
        )
    }
}

/**
 * Helper: Hourly forecast item for large widget
 */
@Composable
private fun HourlyItem(hour: HourlyForecastItem, temperatureUnit: TemperatureUnit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = GlanceModifier.width(50.dp)
    ) {
        // Time - already formatted as string
        Text(
            text = hour.time,
            style = TextStyle(
                fontSize = 10.sp,
                color = ColorProvider(android.R.color.white)
            )
        )
        
        Spacer(modifier = GlanceModifier.height(4.dp))
        
        // Temperature
        Text(
            text = "${hour.temperature.toInt()}°",
            style = TextStyle(
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = ColorProvider(android.R.color.white)
            )
        )
    }
}
