package com.andernet.weather.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.cos
import kotlin.math.sin

/**
 * Wind compass showing wind direction and speed
 * Similar to iOS weather app wind compass
 */
@Composable
fun WindCompass(
    windDirection: Double,  // Degrees (0-360)
    windSpeed: Double,      // Speed in current unit
    windSpeedUnit: String,  // "mph", "km/h", etc.
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Compass circle
        Box(
            modifier = Modifier
                .size(200.dp)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                val center = Offset(size.width / 2f, size.height / 2f)
                val radius = size.minDimension / 2f
                val compassColor = Color.White.copy(alpha = 0.5f)
                val arrowColor = Color(0xFF2196F3)
                
                // Draw outer circle
                drawCircle(
                    color = compassColor,
                    radius = radius,
                    center = center,
                    style = Stroke(width = 2.dp.toPx())
                )
                
                // Draw cardinal direction markers
                val cardinalPoints = listOf(
                    0.0 to "N",
                    90.0 to "E",
                    180.0 to "S",
                    270.0 to "W"
                )
                
                cardinalPoints.forEach { (angle, label) ->
                    val rad = Math.toRadians(angle - 90)
                    val markerRadius = radius * 0.85f
                    val x = center.x + (markerRadius * cos(rad)).toFloat()
                    val y = center.y + (markerRadius * sin(rad)).toFloat()
                    
                    // Draw tick mark
                    val tickStart = Offset(
                        center.x + (radius * 0.9f * cos(rad)).toFloat(),
                        center.y + (radius * 0.9f * sin(rad)).toFloat()
                    )
                    val tickEnd = Offset(
                        center.x + (radius * cos(rad)).toFloat(),
                        center.y + (radius * sin(rad)).toFloat()
                    )
                    
                    drawLine(
                        color = compassColor,
                        start = tickStart,
                        end = tickEnd,
                        strokeWidth = 3.dp.toPx(),
                        cap = StrokeCap.Round
                    )
                }
                
                // Draw intercardinal direction markers (NE, SE, SW, NW)
                val intercardinalPoints = listOf(45.0, 135.0, 225.0, 315.0)
                intercardinalPoints.forEach { angle ->
                    val rad = Math.toRadians(angle - 90)
                    val tickStart = Offset(
                        center.x + (radius * 0.95f * cos(rad)).toFloat(),
                        center.y + (radius * 0.95f * sin(rad)).toFloat()
                    )
                    val tickEnd = Offset(
                        center.x + (radius * cos(rad)).toFloat(),
                        center.y + (radius * sin(rad)).toFloat()
                    )
                    
                    drawLine(
                        color = compassColor.copy(alpha = 0.3f),
                        start = tickStart,
                        end = tickEnd,
                        strokeWidth = 2.dp.toPx(),
                        cap = StrokeCap.Round
                    )
                }
                
                // Draw wind direction arrow
                rotate(degrees = windDirection.toFloat(), pivot = center) {
                    val arrowPath = Path().apply {
                        // Arrow pointing up (north)
                        val arrowLength = radius * 0.7f
                        val arrowWidth = radius * 0.15f
                        
                        // Arrow tip
                        moveTo(center.x, center.y - arrowLength)
                        
                        // Left side
                        lineTo(center.x - arrowWidth, center.y - arrowLength + arrowWidth * 1.5f)
                        lineTo(center.x - arrowWidth * 0.4f, center.y - arrowLength + arrowWidth * 1.5f)
                        
                        // Tail
                        lineTo(center.x - arrowWidth * 0.4f, center.y + arrowLength * 0.3f)
                        lineTo(center.x + arrowWidth * 0.4f, center.y + arrowLength * 0.3f)
                        
                        // Right side
                        lineTo(center.x + arrowWidth * 0.4f, center.y - arrowLength + arrowWidth * 1.5f)
                        lineTo(center.x + arrowWidth, center.y - arrowLength + arrowWidth * 1.5f)
                        
                        close()
                    }
                    
                    drawPath(
                        path = arrowPath,
                        color = arrowColor
                    )
                }
            }
            
            // Cardinal direction labels
            Text(
                text = "N",
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .offset(y = (-4).dp),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Text(
                text = "S",
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .offset(y = 4.dp),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Text(
                text = "E",
                modifier = Modifier
                    .align(Alignment.CenterEnd)
                    .offset(x = 4.dp),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Text(
                text = "W",
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .offset(x = (-4).dp),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }
        
        // Wind information
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "${getDirectionName(windDirection)} ${windSpeed.toInt()} $windSpeedUnit",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        
        Text(
            text = "${windDirection.toInt()}°",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
    }
}

/**
 * Convert wind direction in degrees to cardinal/intercardinal direction name
 */
private fun getDirectionName(degrees: Double): String {
    val normalized = ((degrees % 360) + 360) % 360  // Ensure positive 0-360
    
    return when {
        normalized < 22.5 -> "N"
        normalized < 67.5 -> "NE"
        normalized < 112.5 -> "E"
        normalized < 157.5 -> "SE"
        normalized < 202.5 -> "S"
        normalized < 247.5 -> "SW"
        normalized < 292.5 -> "W"
        normalized < 337.5 -> "NW"
        else -> "N"
    }
}
