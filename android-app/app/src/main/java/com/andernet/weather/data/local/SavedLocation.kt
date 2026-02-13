package com.andernet.weather.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date

/**
 * Room entity for saved/favorite locations
 * Similar to iOS SavedLocation SwiftData model
 */
@Entity(tableName = "saved_locations")
data class SavedLocation(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val latitude: Double,
    val longitude: Double,
    val cityName: String,
    val stateName: String = "",
    val countryName: String = "",
    val timestamp: Long = System.currentTimeMillis()
) {
    val displayName: String
        get() = when {
            cityName.isNotEmpty() && stateName.isNotEmpty() -> "$cityName, $stateName"
            cityName.isNotEmpty() && countryName.isNotEmpty() -> "$cityName, $countryName"
            cityName.isNotEmpty() -> cityName
            else -> "${latitude.format(2)}, ${longitude.format(2)}"
        }
    
    companion object {
        private fun Double.format(decimals: Int): String = "%.${decimals}f".format(this)
    }
}
