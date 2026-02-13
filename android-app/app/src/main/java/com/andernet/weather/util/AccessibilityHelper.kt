package com.andernet.weather.util

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.*
import com.andernet.weather.data.model.CurrentWeather
import com.andernet.weather.data.model.DailyForecastItem
import com.andernet.weather.data.model.HourlyForecastItem
import com.andernet.weather.data.model.WeatherCondition

/**
 * Accessibility utilities for screen readers and assistive technologies
 * Ensures WCAG 2.1 Level AA compliance
 */
object AccessibilityHelper {
    
    /**
     * Generate descriptive text for current weather conditions
     * Optimized for screen readers like TalkBack
     */
    fun describeCurrentWeather(
        weather: CurrentWeather,
        locationName: String,
        temperatureUnit: String = "°F"
    ): String {
        val condition = WeatherCondition.fromCode(weather.weatherCode)
        
        return buildString {
            append("Current weather in $locationName. ")
            append("Temperature is ${weather.temperature.toInt()} degrees $temperatureUnit. ")
            append("${condition.description}. ")
            append("Feels like ${weather.apparentTemperature.toInt()} degrees. ")
            append("Wind speed ${weather.windSpeed.toInt()} miles per hour. ")
            append("Humidity ${weather.humidity} percent. ")
            
            weather.uvIndex?.let { uv ->
                if (uv > 0) {
                    append("UV index ${uv.toInt()}, ${getUVDescription(uv)}. ")
                }
            }
        }
    }
    
    /**
     * Generate descriptive text for hourly forecast item
     */
    fun describeHourlyForecast(
        hour: HourlyForecastItem,
        temperatureUnit: String = "°F"
    ): String {
        val condition = WeatherCondition.fromCode(hour.weatherCode)
        
        return buildString {
            append("${hour.time}. ")
            append("${hour.temperature.toInt()} degrees. ")
            append("${condition.description}. ")
            if (hour.precipitationProbability > 20) {
                append("${hour.precipitationProbability} percent chance of precipitation. ")
            }
        }
    }
    
    /**
     * Generate descriptive text for daily forecast item
     */
    fun describeDailyForecast(
        day: DailyForecastItem,
        temperatureUnit: String = "°F"
    ): String {
        val condition = WeatherCondition.fromCode(day.weatherCode)
        
        return buildString {
            append("${day.date}. ")
            append("${condition.description}. ")
            append("High ${day.temperatureMax.toInt()} degrees. ")
            append("Low ${day.temperatureMin.toInt()} degrees. ")
            if (day.precipitationProbability > 20) {
                append("${day.precipitationProbability} percent chance of precipitation. ")
            }
        }
    }
    
    /**
     * Get UV index description for screen readers
     */
    private fun getUVDescription(uvIndex: Double): String {
        return when {
            uvIndex < 3 -> "Low risk from UV rays"
            uvIndex < 6 -> "Moderate UV level, protection recommended"
            uvIndex < 8 -> "High UV level, protection needed"
            uvIndex < 11 -> "Very high UV, extra protection needed"
            else -> "Extreme UV, avoid sun exposure"
        }
    }
    
    /**
     * Get wind direction description for screen readers
     */
    fun getWindDirectionDescription(degrees: Double): String {
        val direction = when {
            degrees < 22.5 -> "North"
            degrees < 67.5 -> "Northeast"
            degrees < 112.5 -> "East"
            degrees < 157.5 -> "Southeast"
            degrees < 202.5 -> "South"
            degrees < 247.5 -> "Southwest"
            degrees < 292.5 -> "West"
            degrees < 337.5 -> "Northwest"
            else -> "North"
        }
        return "Wind from $direction at $degrees degrees"
    }
    
    /**
     * Get weather alert description for screen readers
     */
    fun getAlertDescription(
        title: String,
        message: String,
        priority: String
    ): String {
        return "$priority priority alert. $title. $message"
    }
}

/**
 * Modifier extensions for accessibility
 */

/**
 * Make an element clickable with proper accessibility support
 */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun Modifier.accessibleClickable(
    label: String,
    role: Role = Role.Button,
    onClick: () -> Unit
): Modifier {
    val interactionSource = remember { MutableInteractionSource() }
    
    return this
        .semantics {
            contentDescription = label
            this.role = role
            onClick {
                onClick()
                true
            }
        }
        .clickable(
            interactionSource = interactionSource,
            indication = null,
            onClick = onClick
        )
}

/**
 * Add text content description for screen readers
 */
fun Modifier.accessibleText(description: String): Modifier {
    return this.semantics {
        contentDescription = description
    }
}

/**
 * Mark element as heading for navigation
 */
fun Modifier.accessibleHeading(): Modifier {
    return this.semantics {
        heading()
    }
}

/**
 * Make image accessible with description
 */
fun Modifier.accessibleImage(description: String): Modifier {
    return this.semantics {
        contentDescription = description
        role = Role.Image
    }
}

/**
 * Add live region for dynamic content updates
 * Important for weather alerts and changing data
 */
fun Modifier.liveRegion(priority: LiveRegionMode = LiveRegionMode.Polite): Modifier {
    return this.semantics {
        liveRegion = priority
    }
}

/**
 * Mark content as disabled for accessibility
 */
fun Modifier.accessibleDisabled(isDisabled: Boolean): Modifier {
    return this.semantics {
        if (isDisabled) {
            disabled()
        }
    }
}

/**
 * Custom accessibility actions for complex interactions
 */
fun Modifier.customAccessibilityAction(
    label: String,
    action: () -> Boolean
): Modifier {
    return this.semantics {
        customActions = listOf(
            CustomAccessibilityAction(label) {
                action()
            }
        )
    }
}

/**
 * Accessibility configuration for text scaling
 */
object TextScaleHelper {
    /**
     * Check if large text is enabled
     * Adjust UI accordingly for better readability
     */
    fun shouldUseLargeText(fontScale: Float): Boolean {
        return fontScale >= 1.3f
    }
    
    /**
     * Get appropriate spacing for current text scale
     */
    fun getScaledSpacing(baseSpacing: Float, fontScale: Float): Float {
        return baseSpacing * (1f + (fontScale - 1f) * 0.5f)
    }
}

/**
 * Color contrast helpers for accessibility
 */
object ContrastHelper {
    /**
     * Calculate contrast ratio between two colors
     * WCAG 2.1 requires 4.5:1 for normal text, 3:1 for large text
     */
    fun getContrastRatio(foreground: androidx.compose.ui.graphics.Color, background: androidx.compose.ui.graphics.Color): Float {
        val fgLuminance = getRelativeLuminance(foreground)
        val bgLuminance = getRelativeLuminance(background)
        
        val lighter = maxOf(fgLuminance, bgLuminance)
        val darker = minOf(fgLuminance, bgLuminance)
        
        return (lighter + 0.05f) / (darker + 0.05f)
    }
    
    /**
     * Calculate relative luminance for contrast ratio
     */
    private fun getRelativeLuminance(color: androidx.compose.ui.graphics.Color): Float {
        fun adjust(channel: Float): Float {
            return if (channel <= 0.03928f) {
                channel / 12.92f
            } else {
                Math.pow(((channel + 0.055) / 1.055).toDouble(), 2.4).toFloat()
            }
        }
        
        val r = adjust(color.red)
        val g = adjust(color.green)
        val b = adjust(color.blue)
        
        return 0.2126f * r + 0.7152f * g + 0.0722f * b
    }
    
    /**
     * Check if contrast meets WCAG AA standards
     */
    fun meetsContrastStandards(
        foreground: androidx.compose.ui.graphics.Color,
        background: androidx.compose.ui.graphics.Color,
        isLargeText: Boolean = false
    ): Boolean {
        val ratio = getContrastRatio(foreground, background)
        val minimumRatio = if (isLargeText) 3.0f else 4.5f
        return ratio >= minimumRatio
    }
}

/**
 * Focus management helpers
 */
object FocusHelper {
    /**
     * Announce content change to screen readers
     */
    fun announceForAccessibility(message: String) {
        // This would integrate with Android's AccessibilityManager
        // Implementation requires access to Activity/View context
    }
}
