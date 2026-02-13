package com.andernet.weather.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

/**
 * Complete weather data response from Open-Meteo API
 */
@JsonClass(generateAdapter = true)
data class WeatherData(
    val latitude: Double,
    val longitude: Double,
    val timezone: String,
    @Json(name = "timezone_abbreviation") val timezoneAbbreviation: String,
    val elevation: Double,
    val current: CurrentWeather?,
    val hourly: HourlyWeather?,
    val daily: DailyWeather?
)

/**
 * Current weather conditions
 */
@JsonClass(generateAdapter = true)
data class CurrentWeather(
    val time: String,
    @Json(name = "temperature_2m") val temperature: Double,
    @Json(name = "apparent_temperature") val apparentTemperature: Double,
    @Json(name = "weather_code") val weatherCode: Int,
    @Json(name = "wind_speed_10m") val windSpeed: Double,
    @Json(name = "wind_direction_10m") val windDirection: Double,
    @Json(name = "wind_gusts_10m") val windGusts: Double?,
    @Json(name = "relative_humidity_2m") val humidity: Int,
    @Json(name = "dew_point_2m") val dewPoint: Double?,
    @Json(name = "pressure_msl") val pressure: Double,
    @Json(name = "cloud_cover") val cloudCover: Int,
    val visibility: Double?,
    @Json(name = "uv_index") val uvIndex: Double?,
    val precipitation: Double,
    @Json(name = "is_day") val isDay: Int
)

/**
 * Hourly forecast data (arrays of 168 hours = 7 days)
 */
@JsonClass(generateAdapter = true)
data class HourlyWeather(
    val time: List<String>,
    @Json(name = "temperature_2m") val temperature: List<Double>,
    @Json(name = "weather_code") val weatherCode: List<Int>,
    @Json(name = "precipitation_probability") val precipitationProbability: List<Int>?,
    @Json(name = "wind_speed_10m") val windSpeed: List<Double>,
    @Json(name = "wind_gusts_10m") val windGusts: List<Double>?,
    @Json(name = "relative_humidity_2m") val humidity: List<Int>,
    @Json(name = "uv_index") val uvIndex: List<Double>?
)

/**
 * Daily forecast data (arrays of 14 days)
 */
@JsonClass(generateAdapter = true)
data class DailyWeather(
    val time: List<String>,
    @Json(name = "weather_code") val weatherCode: List<Int>,
    @Json(name = "temperature_2m_max") val temperatureMax: List<Double>,
    @Json(name = "temperature_2m_min") val temperatureMin: List<Double>,
    @Json(name = "precipitation_probability_max") val precipitationProbabilityMax: List<Int>?,
    val sunrise: List<String>,
    val sunset: List<String>,
    @Json(name = "uv_index_max") val uvIndexMax: List<Double>?,
    @Json(name = "wind_speed_10m_max") val windSpeedMax: List<Double>
)

/**
 * Weather condition types mapped from WMO codes
 */
enum class WeatherCondition(val code: IntRange, val description: String, val iconName: String) {
    CLEAR(0..1, "Clear", "clear_day"),
    PARTLY_CLOUDY(2..2, "Partly Cloudy", "partly_cloudy"),
    CLOUDY(3..3, "Cloudy", "cloudy"),
    OVERCAST(45..48, "Fog", "fog"),
    DRIZZLE(51..57, "Drizzle", "drizzle"),
    RAIN(61..67, "Rain", "rain"),
    SNOW(71..77, "Snow", "snow"),
    RAIN_SHOWERS(80..82, "Rain Showers", "rain"),
    SNOW_SHOWERS(85..86, "Snow Showers", "snow"),
    THUNDERSTORM(95..99, "Thunderstorm", "thunderstorm");

    companion object {
        fun fromCode(code: Int): WeatherCondition {
            return values().find { code in it.code } ?: CLEAR
        }
    }
}

/**
 * Hourly forecast item for UI display
 */
data class HourlyForecastItem(
    val time: String,
    val temperature: Double,
    val weatherCode: Int,
    val precipitationProbability: Int,
    val windSpeed: Double,
    val uvIndex: Double? = null,
    val humidity: Int? = null
)

/**
 * Daily forecast item for UI display
 */
data class DailyForecastItem(
    val date: String,
    val weatherCode: Int,
    val temperatureMax: Double,
    val temperatureMin: Double,
    val precipitationProbability: Int,
    val sunrise: String,
    val sunset: String
)
