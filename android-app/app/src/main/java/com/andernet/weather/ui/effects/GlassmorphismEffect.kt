package com.andernet.weather.ui.effects

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Glass morphism effect for modern UI components
 * Creates frosted glass appearance with blur and transparency
 */
object GlassmorphismEffect {
    
    /**
     * Apply glass morphism effect to a composable
     * 
     * @param backgroundColor Base color with transparency
     * @param blurRadius Blur amount for frosted effect
     * @param borderWidth Width of the subtle border
     * @param cornerRadius Corner rounding
     */
    fun Modifier.glassmorphism(
        backgroundColor: Color = Color.White.copy(alpha = 0.1f),
        blurRadius: Dp = 10.dp,
        borderWidth: Dp = 1.dp,
        cornerRadius: Dp = 16.dp
    ): Modifier {
        return this
            .clip(RoundedCornerShape(cornerRadius))
            .background(backgroundColor)
            .border(
                width = borderWidth,
                color = Color.White.copy(alpha = 0.2f),
                shape = RoundedCornerShape(cornerRadius)
            )
            .blur(radius = blurRadius)
    }
    
    /**
     * Create gradient glass effect with multiple color stops
     */
    fun Modifier.glassmorphismGradient(
        colors: List<Color> = listOf(
            Color.White.copy(alpha = 0.15f),
            Color.White.copy(alpha = 0.05f)
        ),
        cornerRadius: Dp = 16.dp,
        borderWidth: Dp = 1.dp
    ): Modifier {
        return this
            .clip(RoundedCornerShape(cornerRadius))
            .background(
                brush = Brush.verticalGradient(colors)
            )
            .border(
                width = borderWidth,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color.White.copy(alpha = 0.3f),
                        Color.White.copy(alpha = 0.1f)
                    )
                ),
                shape = RoundedCornerShape(cornerRadius)
            )
    }
    
    /**
     * Frosted card effect - preset for card components
     */
    fun Modifier.frostedCard(): Modifier {
        return this.glassmorphism(
            backgroundColor = Color.White.copy(alpha = 0.1f),
            blurRadius = 12.dp,
            borderWidth = 1.dp,
            cornerRadius = 20.dp
        )
    }
    
    /**
     * Frosted panel effect - preset for larger panels
     */
    fun Modifier.frostedPanel(): Modifier {
        return this.glassmorphismGradient(
            colors = listOf(
                Color.White.copy(alpha = 0.2f),
                Color.White.copy(alpha = 0.08f)
            ),
            cornerRadius = 24.dp,
            borderWidth = 1.5.dp
        )
    }
    
    /**
     * Subtle frosted effect for backgrounds
     */
    fun Modifier.frostedBackground(): Modifier {
        return this.glassmorphism(
            backgroundColor = Color.Black.copy(alpha = 0.3f),
            blurRadius = 20.dp,
            borderWidth = 0.dp,
            cornerRadius = 0.dp
        )
    }
}
