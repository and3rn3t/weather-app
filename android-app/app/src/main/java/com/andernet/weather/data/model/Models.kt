package com.andernet.weather.data.model

import androidx.compose.runtime.Stable

/**
 * Location data
 */
@Stable
data class LocationData(
    val latitude: Double,
    val longitude: Double,
    val cityName: String = "",
    val stateName: String = "",
    val countryName: String = ""
) {
    val displayName: String
        get() = when {
            cityName.isNotEmpty() && stateName.isNotEmpty() -> "$cityName, $stateName"
            cityName.isNotEmpty() && countryName.isNotEmpty() -> "$cityName, $countryName"
            cityName.isNotEmpty() -> cityName
            else -> "${latitude.format(2)}, ${longitude.format(2)}"
        }
}

/**
 * Temperature units
 */
enum class TemperatureUnit(val symbol: String, val apiParam: String) {
    CELSIUS("°C", "celsius"),
    FAHRENHEIT("°F", "fahrenheit")
}

/**
 * Wind speed units
 */
enum class WindSpeedUnit(val symbol: String, val apiParam: String) {
    MPH("mph", "mph"),
    KMH("km/h", "kmh"),
    MS("m/s", "ms"),
    KNOTS("knots", "kn")
}

/**
 * Precipitation units
 */
enum class PrecipitationUnit(val symbol: String, val apiParam: String) {
    INCHES("in", "inch"),
    MM("mm", "mm")
}

/**
 * UV Index categories
 */
enum class UVIndexCategory(val range: IntRange, val description: String) {
    LOW(0..2, "Low"),
    MODERATE(3..5, "Moderate"),
    HIGH(6..7, "High"),
    VERY_HIGH(8..10, "Very High"),
    EXTREME(11..Int.MAX_VALUE, "Extreme");

    companion object {
        fun fromValue(uvIndex: Double): UVIndexCategory {
            val value = uvIndex.toInt()
            return values().find { value in it.range } ?: LOW
        }
    }
}

/**
 * Extension functions
 */
private fun Double.format(decimals: Int): String = "%.${decimals}f".format(this)
