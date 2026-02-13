package com.andernet.weather.data.repository

import com.andernet.weather.data.local.SavedLocation
import com.andernet.weather.data.local.SavedLocationDao
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for managing saved/favorite locations
 * Similar to iOS FavoritesManager
 */
@Singleton
class FavoritesRepository @Inject constructor(
    private val savedLocationDao: SavedLocationDao
) {
    
    /**
     * Get all saved locations as Flow for reactive UI updates
     */
    fun getAllLocations(): Flow<List<SavedLocation>> {
        return savedLocationDao.getAllLocations()
    }
    
    /**
     * Add a new location to favorites
     * Checks for duplicates within 0.01 degree tolerance like iOS
     */
    suspend fun addLocation(location: SavedLocation): Result<Long> {
        return try {
            // Check if location already exists nearby
            val existing = savedLocationDao.findNearbyLocation(
                latitude = location.latitude,
                longitude = location.longitude
            )
            
            if (existing != null) {
                Result.failure(Exception("Location already saved"))
            } else {
                val id = savedLocationDao.insertLocation(location)
                Result.success(id)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Remove a location from favorites
     */
    suspend fun removeLocation(location: SavedLocation): Result<Unit> {
        return try {
            savedLocationDao.deleteLocation(location)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Remove a location by ID
     */
    suspend fun removeLocationById(locationId: Long): Result<Unit> {
        return try {
            savedLocationDao.deleteLocationById(locationId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Check if a location is already saved
     */
    suspend fun isLocationSaved(latitude: Double, longitude: Double): Boolean {
        return savedLocationDao.findNearbyLocation(latitude, longitude) != null
    }
    
    /**
     * Get count of saved locations
     */
    suspend fun getFavoritesCount(): Int {
        return savedLocationDao.getLocationCount()
    }
}
