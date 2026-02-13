package com.andernet.weather.data.repository

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.os.Build
import androidx.core.content.ContextCompat
import com.andernet.weather.data.model.LocationData
import com.andernet.weather.data.model.WeatherError
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Repository for location services
 * Similar to iOS LocationManager
 */
@Singleton
class LocationRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val fusedLocationClient: FusedLocationProviderClient,
    private val geocoder: Geocoder
) {
    
    /**
     * Check if location permission is granted
     */
    fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    /**
     * Get current location using FusedLocationProvider
     * Uses kilometer-level accuracy for faster GPS fix (like iOS)
     */
    suspend fun getCurrentLocation(): Result<LocationData> = withContext(Dispatchers.IO) {
        try {
            if (!hasLocationPermission()) {
                return@withContext Result.failure(
                    WeatherError.LocationPermissionDenied()
                )
            }
            
            val location = suspendCancellableCoroutine<Location> { continuation ->
                val cancellationToken = CancellationTokenSource()
                
                continuation.invokeOnCancellation {
                    cancellationToken.cancel()
                }
                
                @Suppress("MissingPermission")
                fusedLocationClient.getCurrentLocation(
                    Priority.PRIORITY_BALANCED_POWER_ACCURACY,
                    cancellationToken.token
                ).addOnSuccessListener { location ->
                    if (location != null) {
                        continuation.resume(location)
                    } else {
                        continuation.resumeWithException(
                            WeatherError.LocationUnavailable()
                        )
                    }
                }.addOnFailureListener { exception ->
                    continuation.resumeWithException(exception)
                }
            }
            
            // Reverse geocode to get city/state names
            val locationData = reverseGeocode(location.latitude, location.longitude)
            
            Result.success(locationData)
            
        } catch (e: Exception) {
            Result.failure(WeatherError.fromThrowable(e))
        }
    }
    
    /**
     * Reverse geocode coordinates to get city/state/country names
     * Similar to iOS MapKit reverse geocoding
     */
    suspend fun reverseGeocode(latitude: Double, longitude: Double): LocationData = 
        withContext(Dispatchers.IO) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    // Android 13+ async API
                    suspendCancellableCoroutine { continuation ->
                        geocoder.getFromLocation(latitude, longitude, 1) { addresses ->
                            val address = addresses.firstOrNull()
                            continuation.resume(addressToLocationData(latitude, longitude, address))
                        }
                    }
                } else {
                    // Legacy synchronous API
                    @Suppress("DEPRECATION")
                    val addresses = geocoder.getFromLocation(latitude, longitude, 1)
                    val address = addresses?.firstOrNull()
                    addressToLocationData(latitude, longitude, address)
                }
            } catch (e: Exception) {
                // If geocoding fails, return coordinates only
                LocationData(latitude, longitude)
            }
        }
    
    /**
     * Forward geocode: search for location by name
     */
    suspend fun searchLocation(query: String): Result<List<LocationData>> = 
        withContext(Dispatchers.IO) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    // Android 13+ async API
                    suspendCancellableCoroutine { continuation ->
                        geocoder.getFromLocationName(query, 10) { addresses ->
                            val locations = addresses.map { address ->
                                addressToLocationData(
                                    address.latitude,
                                    address.longitude,
                                    address
                                )
                            }
                            continuation.resume(Result.success(locations))
                        }
                    }
                } else {
                    // Legacy synchronous API
                    @Suppress("DEPRECATION")
                    val addresses = geocoder.getFromLocationName(query, 10) ?: emptyList()
                    val locations = addresses.map { address ->
                        addressToLocationData(
                            address.latitude,
                            address.longitude,
                            address
                        )
                    }
                    Result.success(locations)
                }
            } catch (e: Exception) {
                Result.failure(WeatherError.GeocodingFailed())
            }
        }
    
    /**
     * Convert Android Address to LocationData
     */
    private fun addressToLocationData(
        latitude: Double,
        longitude: Double,
        address: Address?
    ): LocationData {
        return LocationData(
            latitude = latitude,
            longitude = longitude,
            cityName = address?.locality ?: address?.subAdminArea ?: "",
            stateName = address?.adminArea ?: "",
            countryName = address?.countryName ?: ""
        )
    }
}
