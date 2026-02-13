package com.andernet.weather.data.remote

import com.andernet.weather.data.model.RainViewerResponse
import retrofit2.http.GET

/**
 * RainViewer API service for fetching weather radar data
 * API Documentation: https://www.rainviewer.com/api.html
 */
interface RainViewerApiService {
    
    /**
     * Get the latest radar map data including past and forecast frames
     * Base URL: https://api.rainviewer.com
     */
    @GET("public/weather-maps.json")
    suspend fun getRadarMaps(): RainViewerResponse
    
    companion object {
        const val BASE_URL = "https://api.rainviewer.com/"
        
        /**
         * Constructs tile URL for a radar frame
         * @param host The host URL from the API response
         * @param path The path from the radar frame
         * @param tileSize The size of tiles (256, 512, etc.)
         * @param color The color scheme (0-8)
         * @param smooth Whether to apply smoothing
         * @param snow Whether to show snow
         */
        fun buildTileUrl(
            host: String,
            path: String,
            tileSize: Int = 512,
            color: Int = 2,
            smooth: Boolean = true,
            snow: Boolean = true
        ): String {
            val smoothParam = if (smooth) "1" else "0"
            val snowParam = if (snow) "1" else "0"
            return "$host$path/$tileSize/{z}/{x}/{y}/$color/${smoothParam}_$snowParam.png"
        }
    }
}
