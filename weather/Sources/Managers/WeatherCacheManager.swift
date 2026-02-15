//
//  WeatherCacheManager.swift
//  weather
//
//  Enhanced cache manager with memory pressure handling and smart invalidation
//

import Foundation
import UIKit
import OSLog

/**
 * Enhanced cache manager with memory pressure handling, cache warming, and intelligent invalidation
 */
@MainActor
class WeatherCacheManager {
    static let shared = WeatherCacheManager()
    
    // MARK: - Cache Components
    
    /// Memory cache with automatic eviction under pressure
    private let memoryCache = NSCache<NSString, WeatherData>()
    
    /// Disk cache directory
    private let diskCacheDirectory: URL
    
    /// Cache metadata for smart invalidation
    private var cacheMetadata: [String: CacheMetadata] = [:]
    
    /// Logger for cache operations
    private let logger = Logger(subsystem: "WeatherApp.Cache", category: "CacheManager")
    
    // MARK: - Cache Configuration
    
    private struct CacheConfig {
        static let memoryLimit = 50 * 1024 * 1024 // 50MB in memory
        static let diskLimit = 200 * 1024 * 1024 // 200MB on disk
        static let itemCountLimit = 20 // Max items in memory
        static let staleTime: TimeInterval = 15 * 60 // 15 minutes before data is stale
        static let maxAge: TimeInterval = 6 * 60 * 60 // 6 hours max age
    }
    
    // MARK: - Cache Metadata
    
    private struct CacheMetadata: Codable {
        let key: String
        let timestamp: Date
        let size: Int64
        let accessCount: Int
        let lastAccess: Date
        let location: (latitude: Double, longitude: Double)
        
        var isStale: Bool {
            Date().timeIntervalSince(timestamp) > CacheConfig.staleTime
        }
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > CacheConfig.maxAge
        }
        
        var shouldRefresh: Bool {
            // Refresh if stale AND user is likely on WiFi (simplified heuristic)
            isStale && ProcessInfo.processInfo.isLowPowerModeEnabled == false
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Create disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = cacheDirectory.appendingPathComponent("WeatherCache")
        
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        
        setupMemoryCache()
        loadCacheMetadata()
        setupMemoryWarningHandling()
        
        logger.info("WeatherCacheManager initialized with disk cache at: \\(diskCacheDirectory.path)")
    }
    
    private func setupMemoryCache() {
        memoryCache.countLimit = CacheConfig.itemCountLimit
        memoryCache.totalCostLimit = CacheConfig.memoryLimit
        
        // Eviction delegate to update metadata
        memoryCache.delegate = self
    }
    
    private func setupMemoryWarningHandling() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.cleanupAndOptimize()
            }
        }
    }
    
    // MARK: - Public Cache Interface
    
    /// Get weather data from cache
    func getCachedWeather(latitude: Double, longitude: Double) -> WeatherData? {
        let key = cacheKey(latitude: latitude, longitude: longitude)
        
        // Try memory cache first
        if let cached = memoryCache.object(forKey: key as NSString) {
            updateAccessMetadata(for: key)
            logger.debug("Cache HIT (memory): \\(key)")
            return cached
        }
        
        // Try disk cache
        let diskURL = diskCacheDirectory.appendingPathComponent(key).appendingPathExtension("json")
        
        do {
            let data = try Data(contentsOf: diskURL)
            let weather = try JSONDecoder().decode(WeatherData.self, from: data)
            
            // Load back to memory cache
            let cost = data.count
            memoryCache.setObject(weather, forKey: key as NSString, cost: cost)
            
            updateAccessMetadata(for: key)
            logger.debug("Cache HIT (disk): \\(key)")
            return weather
        } catch {
            logger.warning("Cache MISS: \\(key) - \\(error.localizedDescription)")
            return nil
        }
    }
    
    /// Store weather data in cache
    func cacheWeather(_ weather: WeatherData, latitude: Double, longitude: Double) {
        let key = cacheKey(latitude: latitude, longitude: longitude)
        
        Task {
            do {
                let data = try JSONEncoder().encode(weather)
                let cost = data.count
                
                // Store in memory cache
                memoryCache.setObject(weather, forKey: key as NSString, cost: cost)
                
                // Store on disk
                let diskURL = diskCacheDirectory.appendingPathComponent(key).appendingPathExtension("json")
                try data.write(to: diskURL)
                
                // Update metadata
                let metadata = CacheMetadata(
                    key: key,
                    timestamp: Date(),
                    size: Int64(data.count),
                    accessCount: 1,
                    lastAccess: Date(),
                    location: (latitude: latitude, longitude: longitude)
                )
                cacheMetadata[key] = metadata
                saveCacheMetadata()
                
                logger.info("Cached weather data: \\(key) (\\(ByteCountFormatter.string(fromByteCount: Int64(cost), countStyle: .binary)))")
                
                // Cleanup if over disk limit
                await cleanupDiskCacheIfNeeded()
            } catch {
                logger.error("Failed to cache weather data: \\(error)")
            }
        }
    }
    
    /// Check if cached data should be refreshed
    func shouldRefreshCache(latitude: Double, longitude: Double) -> Bool {
        let key = cacheKey(latitude: latitude, longitude: longitude)
        guard let metadata = cacheMetadata[key] else { return true }
        
        return metadata.shouldRefresh || metadata.isExpired
    }
    
    /// Preload cache for given locations (cache warming)
    func warmCache(for locations: [(latitude: Double, longitude: Double)]) {
        Task(priority: .background) {
            for location in locations {
                // Only warm cache if we don't have recent data
                if shouldRefreshCache(latitude: location.latitude, longitude: location.longitude) {
                    logger.info("Cache warming for location: (\\(location.latitude), \\(location.longitude))")
                    // Note: This would typically trigger a background fetch
                    // Implementation depends on your weather service architecture
                }
            }
        }
    }
    
    // MARK: - Cache Management
    
    private func handleMemoryWarning() {
        logger.warning("Memory warning received - clearing memory cache")
        memoryCache.removeAllObjects()
        
        // Keep only most recently accessed items metadata
        let sortedMetadata = cacheMetadata.values.sorted { $0.lastAccess > $1.lastAccess }
        let keepCount = min(5, sortedMetadata.count)
        
        cacheMetadata = Dictionary(uniqueKeysWithValues: 
            sortedMetadata.prefix(keepCount).map { ($0.key, $0) }
        )
        
        saveCacheMetadata()
    }
    
    private func cleanupAndOptimize() async {
        logger.info("Running cache cleanup and optimization")
        
        // Remove expired entries
        let now = Date()
        var expiredKeys: [String] = []
        
        for (key, metadata) in cacheMetadata {
            if metadata.isExpired {
                expiredKeys.append(key)
            }
        }
        
        // Remove expired files and metadata
        for key in expiredKeys {
            let diskURL = diskCacheDirectory.appendingPathComponent(key).appendingPathExtension("json")
            try? FileManager.default.removeItem(at: diskURL)
            cacheMetadata.removeValue(forKey: key)
        }
        
        if !expiredKeys.isEmpty {
            logger.info("Cleaned up \\(expiredKeys.count) expired cache entries")
            saveCacheMetadata()
        }
        
        await cleanupDiskCacheIfNeeded()
    }
    
    private func cleanupDiskCacheIfNeeded() async {
        let totalSize = cacheMetadata.values.reduce(0) { $0 + $1.size }
        
        if totalSize > CacheConfig.diskLimit {
            logger.warning("Disk cache over limit (\\(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .binary))) - starting cleanup")
            
            // Remove least recently used items
            let sortedMetadata = cacheMetadata.values.sorted { $0.lastAccess < $1.lastAccess }
            
            var currentSize = totalSize
            var removedCount = 0
            
            for metadata in sortedMetadata {
                if currentSize <= Int64(Double(CacheConfig.diskLimit) * 0.8) { // Clean to 80% of limit
                    break
                }
                
                let diskURL = diskCacheDirectory.appendingPathComponent(metadata.key).appendingPathExtension("json")
                try? FileManager.default.removeItem(at: diskURL)
                cacheMetadata.removeValue(forKey: metadata.key)
                
                currentSize -= metadata.size
                removedCount += 1
            }
            
            logger.info("Cleaned up \\(removedCount) cache entries to free space")
            saveCacheMetadata()
        }
    }
    
    // MARK: - Metadata Management
    
    private func updateAccessMetadata(for key: String) {
        guard var metadata = cacheMetadata[key] else { return }
        
        metadata = CacheMetadata(
            key: metadata.key,
            timestamp: metadata.timestamp,
            size: metadata.size,
            accessCount: metadata.accessCount + 1,
            lastAccess: Date(),
            location: metadata.location
        )
        
        cacheMetadata[key] = metadata
        
        // Save metadata periodically (every 10 accesses)
        if metadata.accessCount % 10 == 0 {
            saveCacheMetadata()
        }
    }
    
    private func loadCacheMetadata() {
        let metadataURL = diskCacheDirectory.appendingPathComponent("metadata.json")
        
        do {
            let data = try Data(contentsOf: metadataURL)
            cacheMetadata = try JSONDecoder().decode([String: CacheMetadata].self, from: data)
            logger.debug("Loaded cache metadata for \\(cacheMetadata.count) entries")
        } catch {
            logger.info("No existing cache metadata found - starting fresh")
            cacheMetadata = [:]
        }
    }
    
    private func saveCacheMetadata() {
        let metadataURL = diskCacheDirectory.appendingPathComponent("metadata.json")
        
        do {
            let data = try JSONEncoder().encode(cacheMetadata)
            try data.write(to: metadataURL)
        } catch {
            logger.error("Failed to save cache metadata: \\(error)")
        }
    }
    
    // MARK: - Utilities
    
    private func cacheKey(latitude: Double, longitude: Double) -> String {
        // Round to reasonable precision for cache key
        let lat = String(format: "%.4f", latitude)
        let lon = String(format: "%.4f", longitude)
        return "weather_\\(lat)_\\(lon)"
    }
    
    // MARK: - Statistics
    
    func getCacheStatistics() -> (memoryItems: Int, diskItems: Int, totalSize: String) {
        let memoryItems = memoryCache.countLimit
        let diskItems = cacheMetadata.count
        let totalSize = cacheMetadata.values.reduce(0) { $0 + $1.size }
        
        return (
            memoryItems: memoryItems,
            diskItems: diskItems,
            totalSize: ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .binary)
        )
    }
}

// MARK: - NSCacheDelegate

extension WeatherCacheManager: NSCacheDelegate {
    nonisolated func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: AnyObject) {
        // Log eviction for debugging
        Task { @MainActor in
            logger.debug("Memory cache evicting object due to pressure")
        }
    }
}

// MARK: - Cache Metadata Extensions

private extension WeatherCacheManager.CacheMetadata {
    enum CodingKeys: String, CodingKey {
        case key, timestamp, size, accessCount, lastAccess
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        size = try container.decode(Int64.self, forKey: .size)
        accessCount = try container.decode(Int.self, forKey: .accessCount)
        lastAccess = try container.decode(Date.self, forKey: .lastAccess)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = (latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(size, forKey: .size)
        try container.encode(accessCount, forKey: .accessCount)
        try container.encode(lastAccess, forKey: .lastAccess)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
    }
}