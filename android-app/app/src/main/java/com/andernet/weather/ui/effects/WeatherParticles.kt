package com.andernet.weather.ui.effects

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

/**
 * Animated weather particles (rain, snow, etc.) for immersive UI
 * Similar to iOS weather app background animations
 */

/**
 * Rain particle animation overlay
 */
@Composable
fun RainEffect(
    modifier: Modifier = Modifier,
    particleCount: Int = 50,
    speed: Float = 1.5f
) {
    val particles = remember {
        List(particleCount) {
            RainParticle(
                x = Random.nextFloat(),
                y = Random.nextFloat(),
                speed = (0.8f + Random.nextFloat() * 0.4f) * speed,
                length = 20f + Random.nextFloat() * 30f,
                opacity = 0.3f + Random.nextFloat() * 0.4f
            )
        }
    }
    
    var time by remember { mutableStateOf(0f) }
    
    LaunchedEffect(Unit) {
        while (isActive) {
            delay(16) // ~60 FPS
            time += 0.016f
        }
    }
    
    Canvas(modifier = modifier.fillMaxSize()) {
        particles.forEach { particle ->
            val y = ((particle.y + particle.speed * time) % 1.2f) - 0.2f
            val startY = y * size.height
            val endY = startY + particle.length
            
            drawLine(
                color = Color(0xFF4FC3F7).copy(alpha = particle.opacity),
                start = Offset(particle.x * size.width, startY),
                end = Offset(particle.x * size.width, endY),
                strokeWidth = 2f
            )
        }
    }
}

private data class RainParticle(
    val x: Float,
    val y: Float,
    val speed: Float,
    val length: Float,
    val opacity: Float
)

/**
 * Snow particle animation overlay
 */
@Composable
fun SnowEffect(
    modifier: Modifier = Modifier,
    particleCount: Int = 80,
    speed: Float = 0.5f
) {
    val particles = remember {
        List(particleCount) {
            SnowParticle(
                x = Random.nextFloat(),
                y = Random.nextFloat(),
                speed = (0.3f + Random.nextFloat() * 0.4f) * speed,
                size = 2f + Random.nextFloat() * 4f,
                sway = Random.nextFloat() * 0.1f,
                swayPhase = Random.nextFloat() * 6.28f,
                opacity = 0.5f + Random.nextFloat() * 0.5f
            )
        }
    }
    
    var time by remember { mutableStateOf(0f) }
    
    LaunchedEffect(Unit) {
        while (isActive) {
            delay(16)
            time += 0.016f
        }
    }
    
    Canvas(modifier = modifier.fillMaxSize()) {
        particles.forEach { particle ->
            val y = ((particle.y + particle.speed * time) % 1.2f) - 0.2f
            val swayOffset = sin(time * 2f + particle.swayPhase) * particle.sway
            val x = particle.x + swayOffset
            
            drawCircle(
                color = Color.White.copy(alpha = particle.opacity),
                radius = particle.size,
                center = Offset(x * size.width, y * size.height)
            )
        }
    }
}

private data class SnowParticle(
    val x: Float,
    val y: Float,
    val speed: Float,
    val size: Float,
    val sway: Float,
    val swayPhase: Float,
    val opacity: Float
)

/**
 * Cloud movement animation
 */
@Composable
fun CloudEffect(
    modifier: Modifier = Modifier,
    cloudCount: Int = 3,
    speed: Float = 0.05f
) {
    val clouds = remember {
        List(cloudCount) {
            Cloud(
                x = Random.nextFloat(),
                y = Random.nextFloat() * 0.4f,
                speed = (0.5f + Random.nextFloat() * 0.5f) * speed,
                scale = 0.8f + Random.nextFloat() * 0.6f,
                opacity = 0.15f + Random.nextFloat() * 0.15f
            )
        }
    }
    
    var time by remember { mutableStateOf(0f) }
    
    LaunchedEffect(Unit) {
        while (isActive) {
            delay(16)
            time += 0.016f
        }
    }
    
    Canvas(modifier = modifier.fillMaxSize()) {
        clouds.forEach { cloud ->
            val x = ((cloud.x + cloud.speed * time) % 1.2f) - 0.2f
            drawCloud(
                x = x * size.width,
                y = cloud.y * size.height,
                scale = cloud.scale,
                opacity = cloud.opacity
            )
        }
    }
}

private data class Cloud(
    val x: Float,
    val y: Float,
    val speed: Float,
    val scale: Float,
    val opacity: Float
)

private fun DrawScope.drawCloud(x: Float, y: Float, scale: Float, opacity: Float) {
    val baseSize = 60f * scale
    
    // Draw 3 overlapping circles to form a cloud
    drawCircle(
        color = Color.White.copy(alpha = opacity),
        radius = baseSize * 0.8f,
        center = Offset(x, y)
    )
    drawCircle(
        color = Color.White.copy(alpha = opacity),
        radius = baseSize,
        center = Offset(x + baseSize * 0.5f, y - baseSize * 0.2f)
    )
    drawCircle(
        color = Color.White.copy(alpha = opacity),
        radius = baseSize * 0.7f,
        center = Offset(x + baseSize, y)
    )
}

/**
 * Lightning flash effect
 */
@Composable
fun LightningEffect(
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    var flashAlpha by remember { mutableStateOf(0f) }
    
    LaunchedEffect(enabled) {
        if (enabled) {
            while (isActive) {
                delay((3000 + Random.nextLong(5000))) // Random delay 3-8 seconds
                
                // Flash sequence
                flashAlpha = 0.6f
                delay(50)
                flashAlpha = 0f
                delay(100)
                flashAlpha = 0.8f
                delay(40)
                flashAlpha = 0f
            }
        }
    }
    
    Canvas(modifier = modifier.fillMaxSize()) {
        if (flashAlpha > 0f) {
            drawRect(
                color = Color.White.copy(alpha = flashAlpha)
            )
        }
    }
}

/**
 * Fog/mist particle effect
 */
@Composable
fun FogEffect(
    modifier: Modifier = Modifier,
    layerCount: Int = 3
) {
    val layers = remember {
        List(layerCount) {
            FogLayer(
                y = it * 0.3f,
                speed = 0.02f + it * 0.01f,
                opacity = 0.15f - it * 0.03f
            )
        }
    }
    
    var time by remember { mutableStateOf(0f) }
    
    LaunchedEffect(Unit) {
        while (isActive) {
            delay(16)
            time += 0.016f
        }
    }
    
    Canvas(modifier = modifier.fillMaxSize()) {
        layers.forEach { layer ->
            val offset = (time * layer.speed) % 1f
            
            drawRect(
                color = Color.White.copy(alpha = layer.opacity),
                topLeft = Offset(offset * size.width - size.width, layer.y * size.height),
                size = size.copy(width = size.width * 2f, height = size.height * 0.4f)
            )
        }
    }
}

private data class FogLayer(
    val y: Float,
    val speed: Float,
    val opacity: Float
)

/**
 * Star twinkle effect for night sky
 */
@Composable
fun StarEffect(
    modifier: Modifier = Modifier,
    starCount: Int = 50
) {
    val stars = remember {
        List(starCount) {
            Star(
                x = Random.nextFloat(),
                y = Random.nextFloat() * 0.6f, // Upper portion of screen
                size = 1f + Random.nextFloat() * 2f,
                twinkleSpeed = 1f + Random.nextFloat() * 2f,
                twinklePhase = Random.nextFloat() * 6.28f
            )
        }
    }
    
    var time by remember { mutableStateOf(0f) }
    
    LaunchedEffect(Unit) {
        while (isActive) {
            delay(16)
            time += 0.016f
        }
    }
    
    Canvas(modifier = modifier.fillMaxSize()) {
        stars.forEach { star ->
            val twinkle = (sin(time * star.twinkleSpeed + star.twinklePhase) + 1f) / 2f
            val opacity = 0.3f + (twinkle * 0.7f)
            
            drawCircle(
                color = Color.White.copy(alpha = opacity),
                radius = star.size,
                center = Offset(star.x * size.width, star.y * size.height)
            )
        }
    }
}

private data class Star(
    val x: Float,
    val y: Float,
    val size: Float,
    val twinkleSpeed: Float,
    val twinklePhase: Float
)
