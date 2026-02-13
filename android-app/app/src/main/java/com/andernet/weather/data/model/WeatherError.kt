package com.andernet.weather.data.model

/**
 * Weather-related errors with recovery suggestions
 */
sealed class WeatherError(message: String, val recoverySuggestion: String) : Exception(message) {
    
    // Network errors
    data class NetworkError(val errorMessage: String) : WeatherError(
        "Network error: $errorMessage",
        "Please check your internet connection and try again."
    )
    
    data class NoInternetConnection(val errorMessage: String = "No internet connection") : WeatherError(
        errorMessage,
        "Please check your internet connection."
    )
    
    data class RequestTimeout(val errorMessage: String = "Request timed out") : WeatherError(
        errorMessage,
        "The request took too long. Please try again."
    )
    
    // Location errors
    data class LocationUnavailable(val errorMessage: String = "Location unavailable") : WeatherError(
        errorMessage,
        "Unable to determine your location. Please enable location services."
    )
    
    data class LocationPermissionDenied(val errorMessage: String = "Location permission denied") : WeatherError(
        errorMessage,
        "Please grant location permission in settings."
    )
    
    data class GeocodingFailed(val errorMessage: String = "Could not find location") : WeatherError(
        errorMessage,
        "Unable to find the location you searched for. Try a different search term."
    )
    
    // API errors
    data class InvalidResponse(val errorMessage: String = "Invalid API response") : WeatherError(
        errorMessage,
        "Received unexpected data from weather service. Please try again."
    )
    
    data class APIError(val statusCode: Int, val errorMessage: String) : WeatherError(
        "API error ($statusCode): $errorMessage",
        "Weather service temporarily unavailable. Please try again later."
    )
    
    // Data errors
    data class ParsingError(val errorMessage: String = "Failed to parse weather data") : WeatherError(
        errorMessage,
        "Unable to process weather data. Please try again."
    )
    
    data class CacheError(val errorMessage: String = "Cache error") : WeatherError(
        errorMessage,
        "Unable to access cached data."
    )
    
    // Generic error
    data class UnknownError(val errorMessage: String = "An unknown error occurred") : WeatherError(
        errorMessage,
        "Something went wrong. Please try again."
    )
    
    companion object {
        fun fromThrowable(throwable: Throwable): WeatherError {
            return when (throwable) {
                is WeatherError -> throwable
                is java.net.UnknownHostException -> NoInternetConnection()
                is java.net.SocketTimeoutException -> RequestTimeout()
                is java.io.IOException -> NetworkError(throwable.message ?: "Network error")
                else -> UnknownError(throwable.message ?: "Unknown error")
            }
        }
    }
}

/**
 * Result wrapper for operations that can fail
 */
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val error: WeatherError) : Result<Nothing>()
    data object Loading : Result<Nothing>()
    
    val isSuccess: Boolean get() = this is Success
    val isError: Boolean get() = this is Error
    val isLoading: Boolean get() = this is Loading
}
