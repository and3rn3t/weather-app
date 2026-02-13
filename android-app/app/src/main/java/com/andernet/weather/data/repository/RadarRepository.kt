package com.andernet.weather.data.repository

import com.andernet.weather.data.model.RadarTile
import com.andernet.weather.data.remote.RainViewerApiService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for managing weather radar data from RainViewer
 */
@Singleton
class RadarRepository @Inject constructor(
    private val rainViewerApi: RainViewerApiService
) {
    private var cachedTiles: List<RadarTile>? = null
    private var lastFetchTime: Long = 0
    private val cacheValidityMs = 5 * 60 * 1000L // 5 minutes

    /**
     * Fetches radar tiles with caching
     */
    fun getRadarTiles(): Flow<Result<List<RadarTile>>> = flow {
        try {
            // Return cached data if still valid
            val now = System.currentTimeMillis()
            if (cachedTiles != null && (now - lastFetchTime) < cacheValidityMs) {
                emit(Result.success(cachedTiles!!))
                return@flow
            }

            // Fetch new data
            val response = rainViewerApi.getRadarMaps()
            val tiles = mutableListOf<RadarTile>()
            
            // Process past frames (radar history)
            response.radar.past.forEach { frame ->
                val tileUrl = RainViewerApiService.buildTileUrl(
                    host = response.host,
                    path = frame.path
                )
                tiles.add(
                    RadarTile(
                        timestamp = frame.time,
                        tileUrl = tileUrl,
                        isPast = true
                    )
                )
            }
            
            // Process nowcast frames (radar forecast)
            response.radar.nowcast.forEach { frame ->
                val tileUrl = RainViewerApiService.buildTileUrl(
                    host = response.host,
                    path = frame.path
                )
                tiles.add(
                    RadarTile(
                        timestamp = frame.time,
                        tileUrl = tileUrl,
                        isPast = false
                    )
                )
            }
            
            // Cache the results
            cachedTiles = tiles
            lastFetchTime = now
            
            emit(Result.success(tiles))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }

    /**
     * Clear cached radar data
     */
    fun clearCache() {
        cachedTiles = null
        lastFetchTime = 0
    }

    /**
     * Get the number of past frames (for timeline calculation)
     */
    fun getPastFrameCount(): Int {
        return cachedTiles?.count { it.isPast } ?: 0
    }

    /**
     * Get the number of forecast frames
     */
    fun getForecastFrameCount(): Int {
        return cachedTiles?.count { !it.isPast } ?: 0
    }
}
