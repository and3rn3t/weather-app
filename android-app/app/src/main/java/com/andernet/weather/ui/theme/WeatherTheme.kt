package com.andernet.weather.ui.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.ui.graphics.Color

/**
 * Weather-adaptive themes that change based on current conditions
 * Similar to iOS adaptive theming
 */
enum class WeatherThemeType {
    CLASSIC,      // Default blue theme
    OCEAN,        // Deep blues for rainy weather
    SUNSET,       // Warm oranges/pinks for clear evenings
    FOREST,       // Greens for mild, pleasant weather
    MIDNIGHT,     // Dark purples for night
    ARCTIC,       // Cool whites/blues for snow
    STORM,        // Dark grays for thunderstorms
    FOG           // Muted grays for foggy conditions
}

/**
 * Theme manager that selects appropriate theme based on weather conditions
 */
object WeatherThemeManager {
    
    /**
     * Select appropriate theme based on weather code, time of day, and temperature
     */
    fun selectTheme(
        weatherCode: Int,
        isDay: Boolean,
        temperature: Double,
        currentTheme: WeatherThemeType = WeatherThemeType.CLASSIC
    ): WeatherThemeType {
        // User can override with manual selection
        if (currentTheme != WeatherThemeType.CLASSIC) {
            return currentTheme
        }
        
        // Night theme
        if (!isDay) {
            return WeatherThemeType.MIDNIGHT
        }
        
        // Weather-based selection
        return when (weatherCode) {
            // Clear
            0, 1 -> if (temperature > 80) WeatherThemeType.SUNSET else WeatherThemeType.CLASSIC
            
            // Partly Cloudy
            2 -> if (temperature > 70) WeatherThemeType.FOREST else WeatherThemeType.CLASSIC
            
            // Cloudy/Fog
            3, 45, 48 -> WeatherThemeType.FOG
            
            // Rain
            51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82 -> WeatherThemeType.OCEAN
            
            // Snow
            71, 73, 75, 77, 85, 86 -> WeatherThemeType.ARCTIC
            
            // Thunderstorm
            95, 96, 99 -> WeatherThemeType.STORM
            
            else -> WeatherThemeType.CLASSIC
        }
    }
    
    /**
     * Get color scheme for a specific theme
     */
    fun getColorScheme(theme: WeatherThemeType): ColorScheme {
        return when (theme) {
            WeatherThemeType.CLASSIC -> classicTheme()
            WeatherThemeType.OCEAN -> oceanTheme()
            WeatherThemeType.SUNSET -> sunsetTheme()
            WeatherThemeType.FOREST -> forestTheme()
            WeatherThemeType.MIDNIGHT -> midnightTheme()
            WeatherThemeType.ARCTIC -> arcticTheme()
            WeatherThemeType.STORM -> stormTheme()
            WeatherThemeType.FOG -> fogTheme()
        }
    }
    
    // Classic - Default blue theme
    private fun classicTheme() = darkColorScheme(
        primary = Color(0xFF2196F3),
        onPrimary = Color.White,
        primaryContainer = Color(0xFF1976D2),
        onPrimaryContainer = Color.White,
        secondary = Color(0xFF03A9F4),
        onSecondary = Color.White,
        background = Color(0xFF121212),
        onBackground = Color.White,
        surface = Color(0xFF1E1E1E),
        onSurface = Color.White,
        surfaceVariant = Color(0xFF2C2C2C),
        onSurfaceVariant = Color(0xFFE0E0E0)
    )
    
    // Ocean - Deep blues for rainy weather
    private fun oceanTheme() = darkColorScheme(
        primary = Color(0xFF006494),
        onPrimary = Color.White,
        primaryContainer = Color(0xFF003554),
        onPrimaryContainer = Color.White,
        secondary = Color(0xFF0582CA),
        onSecondary = Color.White,
        background = Color(0xFF0A1929),
        onBackground = Color.White,
        surface = Color(0xFF132F4C),
        onSurface = Color.White,
        surfaceVariant = Color(0xFF1A3A52),
        onSurfaceVariant = Color(0xFFB8D4E8)
    )
    
    // Sunset - Warm oranges/pinks for clear evenings
    private fun sunsetTheme() = darkColorScheme(
        primary = Color(0xFFFF6F00),
        onPrimary = Color.White,
        primaryContainer = Color(0xFFE65100),
        onPrimaryContainer = Color.White,
        secondary = Color(0xFFFF8A65),
        onSecondary = Color.White,
        background = Color(0xFF1A1311),
        onBackground = Color.White,
        surface = Color(0xFF2D1E1A),
        onSurface = Color.White,
        surfaceVariant = Color(0xFF3E2723),
        onSurfaceVariant = Color(0xFFFFCCBC)
    )
    
    // Forest - Greens for mild, pleasant weather
    private fun forestTheme() = darkColorScheme(
        primary = Color(0xFF4CAF50),
        onPrimary = Color.White,
        primaryContainer = Color(0xFF388E3C),
        onPrimaryContainer = Color.White,
        secondary = Color(0xFF66BB6A),
        onSecondary = Color.White,
        background = Color(0xFF0D1B0E),
        onBackground = Color.White,
        surface = Color(0xFF1B2A1C),
        onSurface = Color.White,
        surfaceVariant = Color(0xFF263828),
        onSurfaceVariant = Color(0xFFC8E6C9)
    )
    
    // Midnight - Dark purples for night
    private fun midnightTheme() = darkColorScheme(
        primary = Color(0xFF7E57C2),
        onPrimary = Color.White,
        primaryContainer = Color(0xFF5E35B1),
        onPrimaryContainer = Color.White,
        secondary = Color(0xFF9575CD),
        onSecondary = Color.White,
        background = Color(0xFF0A0A14),
        onBackground = Color.White,
        surface = Color(0xFF151524),
        onSurface = Color.White,
        surfaceVariant = Color(0xFF1F1F33),
        onSurfaceVariant = Color(0xFFD1C4E9)
    )
    
    // Arctic - Cool whites/blues for snow
    private fun arcticTheme() = darkColorScheme(
        primary = Color(0xFF00BCD4),
        onPrimary = Color.White,
        primaryContainer = Color(0xFF0097A7),
        onPrimaryContainer = Color.White,
        secondary = Color(0xFF26C6DA),
        onSecondary = Color.White,
        background = Color(0xFF0E1419),
        onBackground = Color.White,
        surface = Color(0xFF1A2329),
        onSurface = Color.White,
        surfaceVariant = Color(0xFF253238),
        onSurfaceVariant = Color(0xFFB2EBF2)
    )
    
    // Storm - Dark grays for thunderstorms
    private fun stormTheme() = darkColorScheme(
        primary = Color(0xFF607D8B),
        onPrimary = Color.White,
        primaryContainer = Color(0xFF455A64),
        onPrimaryContainer = Color.White,
        secondary = Color(0xFF78909C),
        onSecondary = Color.White,
        background = Color(0xFF0A0C0E),
        onBackground = Color.White,
        surface = Color(0xFF1C1E21),
        onSurface = Color.White,
        surfaceVariant = Color(0xFF2A2D31),
        onSurfaceVariant = Color(0xFFCFD8DC)
    )
    
    // Fog - Muted grays for foggy conditions
    private fun fogTheme() = darkColorScheme(
        primary = Color(0xFF9E9E9E),
        onPrimary = Color.White,
        primaryContainer = Color(0xFF757575),
        onPrimaryContainer = Color.White,
        secondary = Color(0xFFBDBDBD),
        onSecondary = Color(0xFF212121),
        background = Color(0xFF121416),
        onBackground = Color.White,
        surface = Color(0xFF1E2124),
        onSurface = Color.White,
        surfaceVariant = Color(0xFF2C2F33),
        onSurfaceVariant = Color(0xFFEEEEEE)
    )
}
