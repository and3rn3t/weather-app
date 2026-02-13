package com.andernet.weather.ui.components.charts

import android.graphics.Color
import com.github.mikephil.charting.charts.BarChart
import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.components.YAxis
import com.github.mikephil.charting.data.*
import com.github.mikephil.charting.formatter.ValueFormatter

/**
 * Factory for creating consistently styled charts
 */
object ChartFactory {
    
    // Color constants
    const val CHART_TEXT_COLOR = Color.WHITE
    const val CHART_GRID_COLOR = 0x30FFFFFF
    const val TEMPERATURE_COLOR = 0xFFFF9800.toInt()
    const val PRECIPITATION_COLOR = 0xFF2196F3.toInt()
    const val SNOW_COLOR = 0xFFFFFFFF.toInt()
    const val UV_LOW_COLOR = 0xFF4CAF50.toInt()
    const val UV_MODERATE_COLOR = 0xFFFFC107.toInt()
    const val UV_HIGH_COLOR = 0xFFFF9800.toInt()
    const val UV_VERY_HIGH_COLOR = 0xFFF44336.toInt()
    const val UV_EXTREME_COLOR = 0xFF9C27B0.toInt()
    const val WIND_COLOR = 0xFF00BCD4.toInt()
    const val HUMIDITY_COLOR = 0xFF2196F3.toInt()
    
    /**
     * Apply common styling to a LineChart
     */
    fun styleLineChart(chart: LineChart) {
        chart.apply {
            description.isEnabled = false
            legend.isEnabled = false
            setTouchEnabled(true)
            isDragEnabled = true
            setScaleEnabled(false)
            setPinchZoom(false)
            setDrawGridBackground(false)
            
            // X-Axis
            xAxis.apply {
                position = XAxis.XAxisPosition.BOTTOM
                textColor = CHART_TEXT_COLOR
                gridColor = CHART_GRID_COLOR
                setDrawGridLines(true)
                setDrawAxisLine(false)
                granularity = 1f
            }
            
            // Left Y-Axis
            axisLeft.apply {
                textColor = CHART_TEXT_COLOR
                gridColor = CHART_GRID_COLOR
                setDrawGridLines(true)
                setDrawAxisLine(false)
            }
            
            // Right Y-Axis (disabled)
            axisRight.isEnabled = false
        }
    }
    
    /**
     * Apply common styling to a BarChart
     */
    fun styleBarChart(chart: BarChart) {
        chart.apply {
            description.isEnabled = false
            legend.isEnabled = false
            setTouchEnabled(true)
            isDragEnabled = true
            setScaleEnabled(false)
            setPinchZoom(false)
            setDrawGridBackground(false)
            setDrawBarShadow(false)
            
            // X-Axis
            xAxis.apply {
                position = XAxis.XAxisPosition.BOTTOM
                textColor = CHART_TEXT_COLOR
                gridColor = CHART_GRID_COLOR
                setDrawGridLines(false)
                setDrawAxisLine(false)
                granularity = 1f
            }
            
            // Left Y-Axis
            axisLeft.apply {
                textColor = CHART_TEXT_COLOR
                gridColor = CHART_GRID_COLOR
                setDrawGridLines(true)
                setDrawAxisLine(false)
                axisMinimum = 0f
            }
            
            // Right Y-Axis (disabled)
            axisRight.isEnabled = false
        }
    }
    
    /**
     * Create a LineDataSet with gradient fill
     */
    fun createLineDataSet(
        entries: List<Entry>,
        label: String,
        color: Int,
        fillEnabled: Boolean = false
    ): LineDataSet {
        return LineDataSet(entries, label).apply {
            this.color = color
            setCircleColor(color)
            circleRadius = 3f
            lineWidth = 2f
            setDrawValues(false)
            setDrawCircles(true)
            mode = LineDataSet.Mode.CUBIC_BEZIER
            
            if (fillEnabled) {
                setDrawFilled(true)
                fillColor = color
                fillAlpha = 100
            }
        }
    }
    
    /**
     * Create a BarDataSet
     */
    fun createBarDataSet(
        entries: List<BarEntry>,
        label: String,
        color: Int
    ): BarDataSet {
        return BarDataSet(entries, label).apply {
            this.color = color
            setDrawValues(true)
            valueTextColor = CHART_TEXT_COLOR
            valueTextSize = 10f
        }
    }
    
    /**
     * Create multi-color BarDataSet
     */
    fun createMultiColorBarDataSet(
        entries: List<BarEntry>,
        label: String,
        colors: List<Int>
    ): BarDataSet {
        return BarDataSet(entries, label).apply {
            setColors(colors)
            setDrawValues(true)
            valueTextColor = CHART_TEXT_COLOR
            valueTextSize = 10f
        }
    }
    
    /**
     * Hour formatter for X-axis (0-23)
     */
    class HourFormatter : ValueFormatter() {
        override fun getFormattedValue(value: Float): String {
            val hour = value.toInt()
            return when {
                hour == 0 -> "12 AM"
                hour < 12 -> "${hour} AM"
                hour == 12 -> "12 PM"
                else -> "${hour - 12} PM"
            }
        }
    }
    
    /**
     * Temperature formatter
     */
    class TemperatureFormatter(private val unit: String = "°") : ValueFormatter() {
        override fun getFormattedValue(value: Float): String {
            return "${value.toInt()}$unit"
        }
    }
    
    /**
     * Percentage formatter
     */
    class PercentageFormatter : ValueFormatter() {
        override fun getFormattedValue(value: Float): String {
            return "${value.toInt()}%"
        }
    }
    
    /**
     * Wind speed formatter
     */
    class WindSpeedFormatter(private val unit: String = "mph") : ValueFormatter() {
        override fun getFormattedValue(value: Float): String {
            return "${value.toInt()} $unit"
        }
    }
}
