package com.andernet.weather.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

/**
 * Room database for the Weather app
 */
@Database(
    entities = [SavedLocation::class],
    version = 1,
    exportSchema = false
)
abstract class WeatherDatabase : RoomDatabase() {
    abstract fun savedLocationDao(): SavedLocationDao
}
