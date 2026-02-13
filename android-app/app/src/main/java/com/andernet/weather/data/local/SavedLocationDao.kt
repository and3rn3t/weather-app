package com.andernet.weather.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for saved locations
 */
@Dao
interface SavedLocationDao {
    
    @Query("SELECT * FROM saved_locations ORDER BY timestamp DESC")
    fun getAllLocations(): Flow<List<SavedLocation>>
    
    @Query("SELECT * FROM saved_locations ORDER BY timestamp DESC")
    suspend fun getAllLocationsSync(): List<SavedLocation>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLocation(location: SavedLocation): Long
    
    @Delete
    suspend fun deleteLocation(location: SavedLocation)
    
    @Query("DELETE FROM saved_locations WHERE id = :locationId")
    suspend fun deleteLocationById(locationId: Long)
    
    /**
     * Check if location already exists within tolerance (0.01 degrees like iOS)
     */
    @Query("""
        SELECT * FROM saved_locations 
        WHERE ABS(latitude - :latitude) < 0.01 
        AND ABS(longitude - :longitude) < 0.01
        LIMIT 1
    """)
    suspend fun findNearbyLocation(latitude: Double, longitude: Double): SavedLocation?
    
    @Query("SELECT COUNT(*) FROM saved_locations")
    suspend fun getLocationCount(): Int
}
