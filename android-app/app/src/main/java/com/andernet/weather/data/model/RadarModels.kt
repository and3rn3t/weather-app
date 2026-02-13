package com.andernet.weather.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

/**
 * RainViewer API response for radar data
 * Provides timestamps and paths for radar animation frames
 */
@JsonClass(generateAdapter = true)
data class RainViewerResponse(
    @Json(name = "version")
    val version: String,
    
    @Json(name = "generated")
    val generated: Long,
    
    @Json(name = "host")
    val host: String,
    
    @Json(name = "radar")
    val radar: RadarData
)

@JsonClass(generateAdapter = true)
data class RadarData(
    @Json(name = "past")
    val past: List<RadarFrame>,
    
    @Json(name = "nowcast")
    val nowcast: List<RadarFrame>
)

@JsonClass(generateAdapter = true)
data class RadarFrame(
    @Json(name = "time")
    val time: Long,
    
    @Json(name = "path")
    val path: String
)

/**
 * Processed radar tile information for display
 */
data class RadarTile(
    val timestamp: Long,
    val tileUrl: String,
    val isPast: Boolean
) {
    fun getFormattedTime(): String {
        val date = java.util.Date(timestamp * 1000L)
        val format = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault())
        return format.format(date)
    }
}

/**
 * Map layer types
 */
enum class MapLayerType {
    STANDARD,
    SATELLITE,
    HYBRID,
    PRECIPITATION
}
