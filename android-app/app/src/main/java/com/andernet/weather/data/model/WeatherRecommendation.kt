package com.andernet.weather.data.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Weather-based recommendation for user actions
 * Similar to iOS weather app suggestions
 */
data class WeatherRecommendation(
    val title: String,
    val message: String,
    val icon: ImageVector,
    val priority: RecommendationPriority
)

enum class RecommendationPriority {
    HIGH,      // Red/urgent (e.g., dangerous UV, extreme temps)
    MEDIUM,    // Yellow/warning (e.g., rain soon, high wind)
    LOW        // Blue/info (e.g., good weather for activities)
}

/**
 * Engine that generates contextual recommendations based on weather data
 */
object RecommendationEngine {
    
    /**
     * Generate recommendations based on current and forecast weather
     */
    fun generateRecommendations(
        currentWeather: CurrentWeather,
        hourlyForecast: List<HourlyForecastItem>,
        uvIndex: Double?,
        airQuality: Int? = null
    ): List<WeatherRecommendation> {
        val recommendations = mutableListOf<WeatherRecommendation>()
        
        // UV Index warnings
        uvIndex?.let { uv ->
            when {
                uv >= 11 -> recommendations.add(
                    WeatherRecommendation(
                        title = "Extreme UV Alert",
                        message = "Take all precautions. Unprotected skin can burn in minutes. Avoid sun exposure from 10 AM - 4 PM.",
                        icon = Icons.Filled.Warning,
                        priority = RecommendationPriority.HIGH
                    )
                )
                uv >= 8 -> recommendations.add(
                    WeatherRecommendation(
                        title = "Very High UV",
                        message = "Wear SPF 30+ sunscreen, sunglasses, and protective clothing. Seek shade during midday hours.",
                        icon = Icons.Filled.WbSunny,
                        priority = RecommendationPriority.HIGH
                    )
                )
                uv >= 6 -> recommendations.add(
                    WeatherRecommendation(
                        title = "High UV Index",
                        message = "Protection needed. Apply SPF 30+ sunscreen every 2 hours if outdoors.",
                        icon = Icons.Filled.WbSunny,
                        priority = RecommendationPriority.MEDIUM
                    )
                )
            }
        }
        
        // Temperature warnings
        when {
            currentWeather.temperature >= 95 -> recommendations.add(
                WeatherRecommendation(
                    title = "Extreme Heat",
                    message = "Stay hydrated and limit outdoor activities. Heat exhaustion risk is high.",
                    icon = Icons.Filled.Whatshot,
                    priority = RecommendationPriority.HIGH
                )
            )
            currentWeather.temperature >= 85 -> recommendations.add(
                WeatherRecommendation(
                    title = "Hot Weather",
                    message = "Drink plenty of water and take breaks in air-conditioned spaces.",
                    icon = Icons.Filled.Thermostat,
                    priority = RecommendationPriority.MEDIUM
                )
            )
            currentWeather.temperature <= 32 -> recommendations.add(
                WeatherRecommendation(
                    title = "Freezing Temperature",
                    message = "Bundle up! Wear layers and protect extremities from frostbite.",
                    icon = Icons.Filled.AcUnit,
                    priority = RecommendationPriority.HIGH
                )
            )
            currentWeather.temperature <= 45 -> recommendations.add(
                WeatherRecommendation(
                    title = "Cold Weather",
                    message = "Dress warmly in layers. Consider a jacket or coat.",
                    icon = Icons.Filled.AcUnit,
                    priority = RecommendationPriority.MEDIUM
                )
            )
        }
        
        // Rain predictions (next 2 hours)
        val upcomingRain = hourlyForecast.take(2).any { it.precipitationProbability >= 50 }
        if (upcomingRain) {
            recommendations.add(
                WeatherRecommendation(
                    title = "Rain Expected Soon",
                    message = "Bring an umbrella. Rain likely in the next 2 hours.",
                    icon = Icons.Filled.BeachAccess,
                    priority = RecommendationPriority.MEDIUM
                )
            )
        }
        
        // Wind warnings
        when {
            currentWeather.windSpeed >= 40 -> recommendations.add(
                WeatherRecommendation(
                    title = "High Wind Warning",
                    message = "Damaging winds possible. Secure loose objects and avoid driving high-profile vehicles.",
                    icon = Icons.Filled.Air,
                    priority = RecommendationPriority.HIGH
                )
            )
            currentWeather.windSpeed >= 25 -> recommendations.add(
                WeatherRecommendation(
                    title = "Windy Conditions",
                    message = "Breezy weather ahead. Secure outdoor items.",
                    icon = Icons.Filled.Air,
                    priority = RecommendationPriority.MEDIUM
                )
            )
        }
        
        // Air quality warnings (if available)
        airQuality?.let { aqi ->
            when {
                aqi >= 151 -> recommendations.add(
                    WeatherRecommendation(
                        title = "Unhealthy Air Quality",
                        message = "Limit outdoor activities, especially for sensitive groups. Wear a mask if necessary.",
                        icon = Icons.Filled.Masks,
                        priority = RecommendationPriority.HIGH
                    )
                )
                aqi >= 101 -> recommendations.add(
                    WeatherRecommendation(
                        title = "Moderate Air Quality",
                        message = "Sensitive individuals should reduce prolonged outdoor exertion.",
                        icon = Icons.Filled.Cloud,
                        priority = RecommendationPriority.MEDIUM
                    )
                )
            }
        }
        
        // Good weather recommendation
        if (recommendations.isEmpty() && 
            currentWeather.temperature in 65.0..78.0 &&
            currentWeather.windSpeed < 15 &&
            hourlyForecast.take(4).all { it.precipitationProbability < 30 }
        ) {
            recommendations.add(
                WeatherRecommendation(
                    title = "Perfect Weather",
                    message = "Great conditions for outdoor activities! Enjoy the day.",
                    icon = Icons.Filled.WbSunny,
                    priority = RecommendationPriority.LOW
                )
            )
        }
        
        return recommendations.sortedByDescending { it.priority }
    }
}
