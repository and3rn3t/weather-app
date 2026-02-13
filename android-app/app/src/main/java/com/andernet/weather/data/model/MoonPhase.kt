package com.andernet.weather.data.model

import kotlin.math.floor

/**
 * Moon phase data and calculations
 * Similar to iOS weather app moon phase display
 */
data class MoonPhase(
    val phaseName: String,
    val phaseEmoji: String,
    val illumination: Double,  // 0.0 to 1.0
    val angle: Double          // 0.0 to 360.0 degrees
)

/**
 * Calculator for moon phases using astronomical algorithms
 */
object MoonPhaseCalculator {
    
    /**
     * Calculate current moon phase
     * Uses simplified algorithm based on Julian date
     */
    fun getCurrentPhase(): MoonPhase {
        val julianDate = getJulianDate()
        return calculatePhase(julianDate)
    }
    
    /**
     * Get moon phase for a specific timestamp
     */
    fun getPhaseForDate(timestampMillis: Long): MoonPhase {
        val julianDate = getJulianDate(timestampMillis)
        return calculatePhase(julianDate)
    }
    
    /**
     * Calculate Julian date from Unix timestamp
     * Julian date is used in astronomical calculations
     */
    private fun getJulianDate(timestampMillis: Long = System.currentTimeMillis()): Double {
        val unixTimestamp = timestampMillis / 1000.0
        return (unixTimestamp / 86400.0) + 2440587.5
    }
    
    /**
     * Calculate moon phase from Julian date
     * Returns phase name, emoji, and illumination percentage
     */
    private fun calculatePhase(julianDate: Double): MoonPhase {
        // Known new moon reference point (January 6, 2000)
        val knownNewMoon = 2451550.1
        
        // Average lunar month length (synodic period)
        val synodicMonth = 29.53058867
        
        // Calculate days since known new moon
        val daysSinceNewMoon = julianDate - knownNewMoon
        
        // Calculate current position in lunar cycle (0 to 1)
        val cycles = daysSinceNewMoon / synodicMonth
        val phase = (cycles - floor(cycles))
        
        // Convert to angle (0-360 degrees)
        val angle = phase * 360.0
        
        // Calculate illumination (0 to 1)
        val illumination = when {
            phase < 0.5 -> phase * 2.0  // Waxing (0 to 1)
            else -> 2.0 - (phase * 2.0)  // Waning (1 to 0)
        }
        
        // Determine phase name and emoji
        val (phaseName, phaseEmoji) = when {
            phase < 0.033 -> "New Moon" to "🌑"
            phase < 0.216 -> "Waxing Crescent" to "🌒"
            phase < 0.283 -> "First Quarter" to "🌓"
            phase < 0.466 -> "Waxing Gibbous" to "🌔"
            phase < 0.533 -> "Full Moon" to "🌕"
            phase < 0.716 -> "Waning Gibbous" to "🌖"
            phase < 0.783 -> "Last Quarter" to "🌗"
            phase < 0.966 -> "Waning Crescent" to "🌘"
            else -> "New Moon" to "🌑"
        }
        
        return MoonPhase(
            phaseName = phaseName,
            phaseEmoji = phaseEmoji,
            illumination = illumination,
            angle = angle
        )
    }
    
    /**
     * Get next full moon date
     */
    fun getNextFullMoon(): Long {
        val currentJulianDate = getJulianDate()
        val knownNewMoon = 2451550.1
        val synodicMonth = 29.53058867
        
        val daysSinceNewMoon = currentJulianDate - knownNewMoon
        val currentCycle = floor(daysSinceNewMoon / synodicMonth)
        
        // Full moon occurs at 0.5 of the cycle
        val nextFullMoonJulian = knownNewMoon + ((currentCycle + 0.5) * synodicMonth)
        
        // If we've passed this full moon, get the next one
        val adjustedJulian = if (nextFullMoonJulian < currentJulianDate) {
            nextFullMoonJulian + synodicMonth
        } else {
            nextFullMoonJulian
        }
        
        // Convert back to Unix timestamp
        return ((adjustedJulian - 2440587.5) * 86400.0 * 1000.0).toLong()
    }
    
    /**
     * Get next new moon date
     */
    fun getNextNewMoon(): Long {
        val currentJulianDate = getJulianDate()
        val knownNewMoon = 2451550.1
        val synodicMonth = 29.53058867
        
        val daysSinceNewMoon = currentJulianDate - knownNewMoon
        val currentCycle = floor(daysSinceNewMoon / synodicMonth)
        
        val nextNewMoonJulian = knownNewMoon + ((currentCycle + 1.0) * synodicMonth)
        
        // Convert back to Unix timestamp
        return ((nextNewMoonJulian - 2440587.5) * 86400.0 * 1000.0).toLong()
    }
}
