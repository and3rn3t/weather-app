package com.andernet.weather.util

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView

/**
 * Haptic feedback utility for tactile UI interactions
 * Similar to iOS haptic feedback engine
 */
class HapticFeedbackManager(private val context: Context) {
    
    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
    
    /**
     * Light impact feedback
     * Use for: Button taps, list item selection
     */
    fun lightImpact() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrator?.vibrate(
                VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
            )
        } else {
            // Fallback for older devices
            @Suppress("DEPRECATION")
            vibrator?.vibrate(10)
        }
    }
    
    /**
     * Medium impact feedback
     * Use for: Tab switches, toggle changes
     */
    fun mediumImpact() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrator?.vibrate(
                VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(20)
        }
    }
    
    /**
     * Heavy impact feedback
     * Use for: Significant UI changes, pull-to-refresh complete
     */
    fun heavyImpact() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrator?.vibrate(
                VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(40)
        }
    }
    
    /**
     * Success feedback
     * Use for: Task completion, successful actions
     */
    fun success() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val timings = longArrayOf(0, 30, 50, 30)
            val amplitudes = intArrayOf(0, 80, 0, 120)
            vibrator?.vibrate(
                VibrationEffect.createWaveform(timings, amplitudes, -1)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(longArrayOf(0, 30, 50, 30), -1)
        }
    }
    
    /**
     * Warning feedback
     * Use for: Validation errors, warnings
     */
    fun warning() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val timings = longArrayOf(0, 40, 40, 40)
            val amplitudes = intArrayOf(0, 100, 0, 100)
            vibrator?.vibrate(
                VibrationEffect.createWaveform(timings, amplitudes, -1)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(longArrayOf(0, 40, 40, 40), -1)
        }
    }
    
    /**
     * Error feedback
     * Use for: Failed actions, errors
     */
    fun error() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val timings = longArrayOf(0, 50, 50, 50, 50, 50)
            val amplitudes = intArrayOf(0, 120, 0, 120, 0, 120)
            vibrator?.vibrate(
                VibrationEffect.createWaveform(timings, amplitudes, -1)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(longArrayOf(0, 50, 50, 50, 50, 50), -1)
        }
    }
    
    /**
     * Selection changed feedback
     * Use for: Scrolling through picker values
     */
    fun selectionChanged() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrator?.vibrate(
                VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(5)
        }
    }
    
    /**
     * Long press feedback
     * Use for: Long press detected
     */
    fun longPress() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(
                VibrationEffect.createOneShot(60, VibrationEffect.DEFAULT_AMPLITUDE)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(60)
        }
    }
}

/**
 * Composable to remember a HapticFeedbackManager instance
 */
@Composable
fun rememberHapticFeedback(): HapticFeedbackManager {
    val context = LocalContext.current
    return remember { HapticFeedbackManager(context) }
}

/**
 * Extension function to perform haptic feedback on a View
 */
fun View.performHaptic(type: HapticFeedbackType) {
    when (type) {
        HapticFeedbackType.CLICK -> performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
        HapticFeedbackType.LONG_PRESS -> performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
        HapticFeedbackType.CONTEXT_CLICK -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
            }
        }
    }
}

enum class HapticFeedbackType {
    CLICK,
    LONG_PRESS,
    CONTEXT_CLICK
}
