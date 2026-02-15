package com.andernet.weather.data.cache

import android.content.Context
import androidx.compose.runtime.Stable
import com.andernet.weather.data.model.WeatherData
import com.squareup.moshi.Moshi
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.roundToInt

/**
 * Enhanced cache manager for Android with smart invalidation and memory pressure handling
 * Similar to iOS WeatherCacheManager but adapted for Android patterns
 */
@Singleton
class WeatherCacheManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val moshi: Moshi
) {
    
    // MARK: - Cache Components
    
    private val memoryCache = ConcurrentHashMap<String, CacheEntry>()
    private val cacheMetadata = ConcurrentHashMap<String, CacheMetadata>()
    private val cacheDir = File(context.cacheDir, "weather_enhanced")
    private val metadataFile = File(cacheDir, "metadata.json")
    
    // MARK: - Cache Configuration
    
    private object CacheConfig {
        const val MEMORY_LIMIT_MB = 20 // 20MB in memory
        const val DISK_LIMIT_MB = 100 // 100MB on disk  
        const val MAX_MEMORY_ITEMS = 15
        const val STALE_TIME_MS = 15 * 60 * 1000L // 15 minutes
        const val MAX_AGE_MS = 6 * 60 * 60 * 1000L // 6 hours
    }
    
    // MARK: - Data Classes
    
    @Stable
    private data class CacheEntry(
        val data: WeatherData,
        val timestamp: Long,
        val size: Int
    )
    
    @Stable
    private data class CacheMetadata(
        val key: String,
        val timestamp: Long,
        val size: Long,
        val accessCount: Int,
        val lastAccess: Long,
        val latitude: Double,
        val longitude: Double
    ) {
        val isStale: Boolean
            get() = System.currentTimeMillis() - timestamp > CacheConfig.STALE_TIME_MS
            
        val isExpired: Boolean
            get() = System.currentTimeMillis() - timestamp > CacheConfig.MAX_AGE_MS
            
        val shouldRefresh: Boolean
            get() = isStale // Simplified - could add network type detection
    }
    
    init {
        cacheDir.mkdirs()
        loadMetadata()
        cleanupExpiredEntries()
    }
    
    // MARK: - Public Interface
    
    /**
     * Get weather data from cache
     */
    suspend fun getCachedWeather(latitude: Double, longitude: Double): WeatherData? {
        return withContext(Dispatchers.IO) {
            val key = cacheKey(latitude, longitude)
            
            // Try memory cache first
            memoryCache[key]?.let { entry ->
                updateAccessMetadata(key)
                return@withContext entry.data
            }
            
            // Try disk cache
            val cacheFile = File(cacheDir, "$key.json")
            if (cacheFile.exists()) {
                try {
                    val json = cacheFile.readText()
                    val adapter = moshi.adapter(WeatherData::class.java)
                    val weatherData = adapter.fromJson(json)
                    
                    if (weatherData != null) {
                        // Load back to memory cache if space available
                        if (memoryCache.size < CacheConfig.MAX_MEMORY_ITEMS) {
                            val entry = CacheEntry(
                                data = weatherData,
                                timestamp = System.currentTimeMillis(),
                                size = json.length
                            )
                            memoryCache[key] = entry
                        }
                        
                        updateAccessMetadata(key)
                        return@withContext weatherData
                    }
                } catch (e: Exception) {
                    // Invalid cache file - remove it
                    cacheFile.delete()
                    cacheMetadata.remove(key)
                }
            }
            
            null
        }
    }
    
    /**
     * Store weather data in cache
     */
    suspend fun cacheWeather(
        weatherData: WeatherData,
        latitude: Double,
        longitude: Double
    ) {
        withContext(Dispatchers.IO) {
            val key = cacheKey(latitude, longitude)
            val adapter = moshi.adapter(WeatherData::class.java)
            val json = adapter.toJson(weatherData)
            
            // Store in memory cache
            val entry = CacheEntry(
                data = weatherData,
                timestamp = System.currentTimeMillis(),
                size = json.length
            )
            
            // Manage memory cache size
            if (memoryCache.size >= CacheConfig.MAX_MEMORY_ITEMS) {
                evictLeastRecentlyUsed()
            }
            memoryCache[key] = entry
            
            // Store on disk
            val cacheFile = File(cacheDir, "$key.json")
            try {
                cacheFile.writeText(json)
                
                // Update metadata
                val metadata = CacheMetadata(
                    key = key,
                    timestamp = System.currentTimeMillis(),
                    size = json.length.toLong(),
                    accessCount = 1,
                    lastAccess = System.currentTimeMillis(),
                    latitude = latitude,
                    longitude = longitude
                )
                cacheMetadata[key] = metadata
                saveMetadata()
                
                // Cleanup disk if needed
                cleanupDiskCacheIfNeeded()
            } catch (e: Exception) {
                // Failed to write to disk - at least we have memory cache
                e.printStackTrace()
            }
        }
    }
    
    /**
     * Check if cached data should be refreshed
     */
    fun shouldRefreshCache(latitude: Double, longitude: Double): Boolean {
        val key = cacheKey(latitude, longitude)
        val metadata = cacheMetadata[key] ?: return true
        return metadata.shouldRefresh || metadata.isExpired
    }
    
    /**
     * Warm cache for given locations
     */
    suspend fun warmCache(locations: List<Pair<Double, Double>>) {
        withContext(Dispatchers.IO) {
            locations.forEach { (latitude, longitude) ->
                if (shouldRefreshCache(latitude, longitude)) {
                    // Cache warming would trigger background fetch
                    // Implementation depends on your weather service architecture
                }
            }
        }
    }
    
    /**
     * Clear expired cache entries
     */
    suspend fun clearExpired() {
        withContext(Dispatchers.IO) {
            cleanupExpiredEntries()
        }
    }
    
    /**
     * Get cache statistics
     */
    fun getCacheStats(): CacheStats {
        val totalMemorySize = memoryCache.values.sumOf { it.size }
        val totalDiskSize = cacheMetadata.values.sumOf { it.size }
        
        return CacheStats(
            memoryItems = memoryCache.size,
            diskItems = cacheMetadata.size,
            memorySize = totalMemorySize / (1024 * 1024), // MB
            diskSize = totalDiskSize / (1024 * 1024) // MB
        )
    }
    
    // MARK: - Private Methods
    
    private fun cacheKey(latitude: Double, longitude: Double): String {
        val lat = (latitude * 10000).roundToInt() / 10000.0
        val lon = (longitude * 10000).roundToInt() / 10000.0
        return "weather_${lat}_${lon}"
    }
    
    private fun updateAccessMetadata(key: String) {
        val metadata = cacheMetadata[key] ?: return
        val updated = metadata.copy(
            accessCount = metadata.accessCount + 1,
            lastAccess = System.currentTimeMillis()
        )
        cacheMetadata[key] = updated
        
        // Save metadata periodically
        if (updated.accessCount % 10 == 0) {
            saveMetadata()
        }
    }
    
    private fun evictLeastRecentlyUsed() {
        // Find LRU item in memory cache
        var lruKey: String? = null
        var oldestAccess = Long.MAX_VALUE
        
        for ((key, _) in memoryCache) {
            val metadata = cacheMetadata[key]
            if (metadata != null && metadata.lastAccess < oldestAccess) {
                oldestAccess = metadata.lastAccess
                lruKey = key
            }
        }
        
        lruKey?.let { memoryCache.remove(it) }
    }
    
    private fun cleanupExpiredEntries() {
        val now = System.currentTimeMillis()
        val expiredKeys = cacheMetadata.values.filter { 
            now - it.timestamp > CacheConfig.MAX_AGE_MS 
        }.map { it.key }
        
        expiredKeys.forEach { key ->
            // Remove from memory
            memoryCache.remove(key)
            
            // Remove from disk
            File(cacheDir, "$key.json").delete()
            
            // Remove metadata
            cacheMetadata.remove(key)
        }
        
        if (expiredKeys.isNotEmpty()) {
            saveMetadata()
        }
    }
    
    private fun cleanupDiskCacheIfNeeded() {
        val totalSize = cacheMetadata.values.sumOf { it.size }
        val limitBytes = CacheConfig.DISK_LIMIT_MB * 1024 * 1024L
        
        if (totalSize > limitBytes) {
            // Sort by last access (LRU)
            val sortedEntries = cacheMetadata.values.sortedBy { it.lastAccess }
            
            var currentSize = totalSize
            val targetSize = (limitBytes * 0.8).toLong() // Clean to 80% of limit
            
            for (metadata in sortedEntries) {
                if (currentSize <= targetSize) break
                
                // Remove from all caches
                memoryCache.remove(metadata.key)
                File(cacheDir, "${metadata.key}.json").delete()
                cacheMetadata.remove(metadata.key)
                
                currentSize -= metadata.size
            }
            
            saveMetadata()
        }
    }
    
    private fun loadMetadata() {
        if (metadataFile.exists()) {
            try {
                val json = metadataFile.readText()
                val adapter = moshi.adapter<Map<String, CacheMetadata>>(
                    Map::class.java, 
                    String::class.java, 
                    CacheMetadata::class.java
                )
                val loaded = adapter.fromJson(json)
                if (loaded != null) {
                    cacheMetadata.putAll(loaded)
                }
            } catch (e: Exception) {
                e.printStackTrace()
                cacheMetadata.clear()
            }
        }
    }
    
    private fun saveMetadata() {
        try {
            val adapter = moshi.adapter<Map<String, CacheMetadata>>(
                Map::class.java,
                String::class.java,
                CacheMetadata::class.java
            )
            val json = adapter.toJson(cacheMetadata.toMap())
            metadataFile.writeText(json ?: "{}")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    // MARK: - Data Classes
    
    @Stable
    data class CacheStats(
        val memoryItems: Int,
        val diskItems: Int,
        val memorySize: Int, // MB
        val diskSize: Int    // MB
    )
}