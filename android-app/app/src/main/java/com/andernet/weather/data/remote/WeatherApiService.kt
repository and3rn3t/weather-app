package com.andernet.weather.data.remote

import com.andernet.weather.data.model.WeatherData
import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.Query

/**
 * Open-Meteo API service
 * API Documentation: https://open-meteo.com/en/docs
 */
interface WeatherApiService {
    
    /**
     * Fetch weather forecast data
     * 
     * @param latitude Latitude coordinate
     * @param longitude Longitude coordinate
     * @param current Current weather parameters
     * @param hourly Hourly forecast parameters
     * @param daily Daily forecast parameters
     * @param temperatureUnit Temperature unit (celsius or fahrenheit)
     * @param windSpeedUnit Wind speed unit (mph, kmh, ms, kn)
     * @param precipitationUnit Precipitation unit (mm or inch)
     * @param timezone Timezone (default: auto)
     * @param forecastDays Number of forecast days (max 16)
     */
    @GET("v1/forecast")
    suspend fun getWeatherForecast(
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double,
        @Query("current") current: String = "temperature_2m,apparent_temperature,weather_code," +
                "wind_speed_10m,wind_direction_10m,wind_gusts_10m," +
                "relative_humidity_2m,dew_point_2m,pressure_msl," +
                "cloud_cover,visibility,uv_index,precipitation,is_day",
        @Query("hourly") hourly: String = "temperature_2m,weather_code," +
                "precipitation_probability,wind_speed_10m,wind_gusts_10m," +
                "relative_humidity_2m,uv_index",
        @Query("daily") daily: String = "weather_code,temperature_2m_max,temperature_2m_min," +
                "precipitation_probability_max,sunrise,sunset," +
                "uv_index_max,wind_speed_10m_max",
        @Query("temperature_unit") temperatureUnit: String = "celsius",
        @Query("wind_speed_unit") windSpeedUnit: String = "kmh",
        @Query("precipitation_unit") precipitationUnit: String = "mm",
        @Query("timezone") timezone: String = "auto",
        @Query("forecast_days") forecastDays: Int = 14
    ): Response<WeatherData>
}
